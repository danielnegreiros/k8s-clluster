# Private Registry with TLS Security

#### Prepare Configuration on Master

Maybe big companies don't want to upload their images to the cloud, even if it's protected.
Then, it's possible to create private registries.


For that we need to make use of the tool httpasswd, to create a password

- Install
```
$ sudo yum install httpd-tools -y
```
- Create a user/ password
```
$ htpasswd -Bc registry.password my-user
New password: 
Re-type new password: 
Adding password for user my-user
```

- Create a second user/ password
```
$ htpasswd -B registry.password aderbal
New password: 
Re-type new password: 
Adding password for user aderbal
```

Check the created password
```
$ cat registry.password
my-user:$2y$05$uPPFiRcrN4P1V9LkvDAvhONmVV00dtrnoeM2t5m2980nueFA8K4U6
aderbal:$2y$05$7coUtb6V3hC1hbeRVJ6ZU.6YZNLSOMNaeSSnxsQ2h.YR.dKLxBybC
```

#### Create Certs on Worker02
- Create Key

```
$ mkdir certs
$ openssl genrsa -out certs/registry.key 4096
```

- Create SSL conf

```
cat << EOF > certs/ssl.conf
[ req ]
default_bits       = 4096
distinguished_name = req_distinguished_name
req_extensions     = req_ext

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = BR
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = RJ
localityName                = Locality Name (eg, city)
localityName_default        = RJ
organizationName            = Organization Name (eg, company)
organizationName_default    = Test
commonName                  = Common Name (e.g. server FQDN or YOUR name)
commonName_max              = 64
commonName_default          = localhost

[ req_ext ]
subjectAltName = @alt_names

[alt_names]
DNS.1   = my-priv-reg
EOF
```

- Generate a Certificate Signing Request

```
$ openssl req -new -sha256 -out certs/registry.csr -key certs/registry.key  -config certs/ssl.conf 
```
- Create cert and change permissions

```
$ openssl x509 -req -sha256 -days 3650 -in certs/registry.csr  -signkey certs/registry.key -out certs/registry.crt -extensions req_ext  -extfile certs/ssl.conf
$ chmod 400 certs/*
```

- Create directory for Docker to store the cert - on ALL the nodes

```
$ sudo mkdir -pv /etc/docker/certs.d/my-priv-reg:443
$ sudo scp vagrant@worker02:/home/vagrant/certs/registry.crt /etc/docker/certs.d/my-priv-reg:443/
```


#### Finalize Configuration on Master

Creating a dedicated namespace
```
$ kubectl create ns priv-registry
namespace/priv-registry created
```


Let's create a config map using that passwd file
```
$ kubectl create configmap my-reg-config --from-file=registry.password -n=priv-registry
configmap/my-reg-config created
```

- Now let's create a persistent volume and give it 2Gb

- Crate yaml file

```
cat << EOF > reg-pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  namespace: priv-registry
  name: reg-pv-volume
  labels:
    type: local
spec:
  storageClassName: manual
  capacity:
    storage: 2Gi
  accessModes:
    - ReadWriteOnce
  hostPath:
    path: "/var/lib/registry"
EOF
```
- Applying and Checking
```
$ kubectl apply -f reg-pv.yaml
persistentvolume/reg-pv-volume created

$ kubectl get pv -n=priv-registry
NAME            CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM   STORAGECLASS   REASON   AGE
reg-pv-volume   2Gi        RWO            Retain           Available           manual                  14s
```


- Now let's create a Persistent Volume Claim

```
cat << EOF > reg-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  namespace: priv-registry
  name: priv-reg-pvc
spec:
  accessModes:
    - ReadWriteOnce
  volumeMode: Filesystem
  storageClassName: manual
  resources:
    requests:
      storage: 2Gi  
EOF
```

- Applying and Checking - Note: PVC is bound

```
$ kubectl apply -f reg-pvc.yaml
persistentvolumeclaim/priv-reg-pvc created

$ kubectl get pvc -n=priv-registry
NAME           STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
priv-reg-pvc   Bound    reg-pv-volume   2Gi        RWO            manual         2s
```

- Creating Deployment and ClusterIP service to use Registry
```
cat << EOF > my-priv-reg-dep-svc.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  creationTimestamp: null
  labels:
    app: my-priv-registry
  name: my-priv-registry
  namespace: priv-registry
spec:
  replicas: 1
  selector:
    matchLabels:
      app: my-priv-registry
  strategy: {}
  template:
    metadata:
      creationTimestamp: null
      labels:
        app: my-priv-registry
    spec:
      nodeName: worker02
      containers:
      - image: registry:2
        name: registry
        env:
        - name: REGISTRY_AUTH
          value: htpasswd
        - name: REGISTRY_AUTH_HTPASSWD_REALM
          value: Registry
        - name: REGISTRY_AUTH_HTPASSWD_PATH
          value: /etc/security/registry.password
        - name: REGISTRY_HTTP_TLS_CERTIFICATE
          value: /certs/registry.crt
        - name: REGISTRY_HTTP_TLS_KEY 
          value: /certs/registry.key
        - name: REGISTRY_HTTP_ADDR
          value: "0.0.0.0:443"
        volumeMounts:
        - name: my-reg-config-vol
          mountPath: /etc/security/
        - name: my-reg-vol
          mountPath: /var/lib/registry
        - name: my-certs-vol
          mountPath: /certs
      volumes:
      - name: my-reg-config-vol
        configMap:
          name: my-reg-config
          defaultMode: 0400
      - name: my-reg-vol
        persistentVolumeClaim:
          claimName: priv-reg-pvc
      - name: my-certs-vol
        hostPath:
          path: "/home/vagrant/certs"
---
apiVersion: v1
kind: Service
metadata:
  creationTimestamp: null
  labels:
    app: my-priv-registry
  name: my-priv-registry
  namespace: priv-registry
spec:
  ports:
  - port: 443
    protocol: TCP
    targetPort: 443
  selector:
    app: my-priv-registry
status:
  loadBalancer: {}
EOF
```

- Applying

```
$ kubectl apply -f my-priv-reg-dep-svc.yaml
deployment.apps/my-priv-registry created
service/my-priv-registry created
```


- Checking objects

```
$ kubectl get pv,pvc,pod -n=priv-registry
NAME                             CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS   REASON   AGE
persistentvolume/reg-pv-volume   2Gi        RWO            Retain           Bound    priv-registry/priv-reg-pvc   manual                  11m

NAME                                 STATUS   VOLUME          CAPACITY   ACCESS MODES   STORAGECLASS   AGE
persistentvolumeclaim/priv-reg-pvc   Bound    reg-pv-volume   2Gi        RWO            manual         7m9s

NAME                                    READY   STATUS    RESTARTS   AGE
pod/my-priv-registry-6f56f89f94-s9xrw   1/1     Running   0          50s
```


#### Fix /etc/hosts - on ALL the nodes

- On master, check registry svc IP
```
$ kubectl get svc -n=priv-registry
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
my-priv-registry   ClusterIP   10.99.68.39   <none>        5000/TCP   25m
```


Add info on all nodes of the cluster to /etc/hosts
```
sudo -i
echo "10.99.68.39 my-priv-reg" >> /etc/hosts
exit
```


- Try to login from any node:
```
$ docker login my-priv-reg:443
Username: aderbal
Password:
WARNING! Your password will be stored unencrypted in /home/vagrant/.docker/config.json.
Configure a credential helper to remove this warning. See
https://docs.docker.com/engine/reference/commandline/login/#credentials-store

Login Succeeded
```


- Pull default nginx image

```
$ docker pull nginx
Using default tag: latest
latest: Pulling from library/nginx
bb79b6b2107f: Pull complete
5a9f1c0027a7: Pull complete
b5c20b2b484f: Pull complete
166a2418f7e8: Pull complete
1966ea362d23: Pull complete
Digest: sha256:aeade65e99e5d5e7ce162833636f692354c227ff438556e5f3ed0335b7cc2f1b
Status: Downloaded newer image for nginx:latest
docker.io/library/nginx:latest
```

- Tag it to our private registry
```
$ docker tag nginx my-priv-reg:443/nginx:vp.20.0
```


And later push it
```
$ docker push my-priv-reg:443/nginx:vp.20.0
The push refers to repository [my-priv-reg:443/nginx]
7b5417cae114: Pushed
aee208b6ccfb: Pushed
2f57e21e4365: Pushed
2baf69a23d7a: Pushing [===================>                               ]  25.32MB/63.64MB
d0fe97fa8b8c: Pushing [=================>                                 ]  24.91MB/69.22MB
```


#### Using the private registry

- Creating a Secret

```
$ kubectl create secret docker-registry regcred --docker-server=my-priv-reg:443 --docker-username=my-user --docker-password=test123 --docker-email=db101010@gmail.com
secret/regcred created
$ kubectl create secret docker-registry regaderbal --docker-server=my-priv-reg:443 --docker-username=aderbal --docker-password=test123 --docker-email=db101010@gmail.com
secret/regaderbal created
```

- Creating POD to use private image

```
cat << EOF > my-priv-rg-test.yaml
apiVersion: v1
kind: Pod
metadata:
  name: private-reg-test
spec:
  nodeName: worker01
  containers:
  - name: private-reg-container-test
    image: my-priv-reg:443/nginx:vp.20.0
  imagePullSecrets:
  - name: regcred
EOF
```
- Applying
```
$ kubectl apply -f my-priv-rg-test.yaml
pod/private-reg-test created
```

- Ckecking
```
$ kubectl get pod private-reg-test -o wide
NAME               READY   STATUS    RESTARTS   AGE   IP          NODE       NOMINATED NODE   READINESS GATES
private-reg-test   1/1     Running   0          9s    10.44.0.6   worker01   <none>           <none>

$ kubectl describe pod private-reg-test | grep -i image:
    Image:          my-priv-reg:443/nginx:vp.20.0
```