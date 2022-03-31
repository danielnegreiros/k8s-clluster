#!/bin/bash

ip1=$(kubectl get svc --no-headers deploy-1-svc | awk '{print $3}')
ip2=$(kubectl get svc --no-headers deploy-2-svc | awk '{print $3}')
for i in {1..100000}
do
 out=$(curl -s --max-time 2 $ip1)
 if [ $? -eq 0 ]; then
   echo "Testing Deployment 1 Successful: " $out
 else
   echo "FAILED Testing Deployment 1"
 fi

 out=$(curl -s --max-time 2 $ip2)
 if [ $? -eq 0 ]; then
   echo "Testing Deployment 2 Successful: " $out
 else
   echo "FAILED Testing Deployment 2"
 fi

 sleep 1
done
