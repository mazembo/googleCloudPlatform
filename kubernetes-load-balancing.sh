# set some environment variables 
export MY_REGION="europe-west1"
export MY_ZONE="europe-west1-c"
export MY_PROJECT_ID = "sonic-progress-721"
export CLUSTER_NAME=httploadbalancer
# setting some config elements 
gcloud config set project $MY_PROJECT_ID
gcloud config set compute/region $MY_REGION
gcloud config set compute/zone $MY_ZONE

# create kubernetes cluster of three nodes 
gcloud container clusters create networklb --num-nodes 3

# deploy ab nginx container with 3 replicas 
kubectl run nginx --image=nginx --replicas=3

# expose the service with a load balancer 
kubectl expose deployment nginx --port=80 --target-port=80 \
--type=LoadBalancer

# undeploy this service 
# kubectl delete service nginx 
# kubectl delete deployment nginx
# gcloud container clusters delete networklb  