# set some environment variables 
export MY_REGION="europe-west1"
export MY_ZONE="europe-west1-c"
export MY_PROJECT_ID = "sonic-progress-721"
export CLUSTER_NAME=httploadbalancer
# setting some config elements 
gcloud config set project $MY_PROJECT_ID
gcloud config set compute/region $MY_REGION
gcloud config set compute/zone $MY_ZONE
# creating a cluster 
gcloud container clusters create $CLUSTER_NAME --zone $MY_ZONE
# create the deployment 
kubectl run nginx --image=nginx --port=80
# exposing the service 
kubectl expose deployment nginx --target-port=80 --type=NodePort 
# ingress directs all traffic to nginx on port 80
kubectl create -f basic-ingress.yaml 
# to verify that ingress works properly 
# kubectl get ingress basic-ingress --watch
# kubectl describe ingress basic-ingress 
# kubectl get ingress basic-ingress 

# to delete ressources after running them 
# kubectl delete -f basic-ingress.yaml 
# kubectl delete deployment nginx 
# gcloud container clusters delete $CLUSTER_NAME 