# MongoDB

Let's create a very simple mongo database and actually use it.

- Creating 

```
$ kubectl run mongo --image=mongo
pod/mongo created
```

- Checking
```
$ kubectl get pods
NAME    READY   STATUS    RESTARTS   AGE
mongo   1/1     Running   0          2m2s
```

- Let's expose it with LoadBalancer, so we can access from outside the cluster. Node Port would also work.
- But let's keep cleaner ports.

```
$ kubectl expose pod mongo --type=LoadBalancer --port=27017
service/mongo exposed
```

- Check IP

```
$ kubectl get svc mongo
NAME    TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)           AGE
mongo   LoadBalancer   10.108.97.19   192.168.50.101   27017:32104/TCP   53s
```

- Creating a simple python to add content to MongoDB Pod and read it later

```
import pymongo

## Connecting
try:
    client = pymongo.MongoClient("192.168.50.101", 27017)
except:
    print ("Not possible to connecy")


## Mongo insertion taken from: https://www.geeksforgeeks.org/mongodb-python-insert-update-data/
# database
db = client.database

## Define collection
collection = db.users

user1 = {
    "name": "Daniel",
    "age": 30
}
user2 = {
    "name": "Test",
    "age": 10,
}

# Inserting
print ("Inserting the contents into Mongo POD...")
try:
    collection.insert_one(user1)
    collection.insert_one(user2)
    print(" Inserted with success")
except:
    print ( "Failure inserting")
print()

# Printing the data inserted
print("Reading data from mongo POD ...")
try:
    list = collection.find()
    print(" Read successfully from mongo POD")
except:
    print ("Failed reading")
print()

print ("My users: ")
for user in list:
    print(" Name: " + user["name"] + " -- Age: " + str(user["age"]))

## Cleaning up
collection.delete_many({})
```

- Execute and check results.
- Now you can increase and manage your mongodb with your POD the way you like
```
$ python commandsMongo.py

Inserting the contents into Mongo POD...
 Inserted with success

Reading data from mongo POD ...
 Read successfully from mongo POD

My users:
 Name: Daniel -- Age: 30
 Name: Test -- Age: 10

```