gcloud compute networks create openshift-network --subnet-mode custom
gcloud compute networks subnets create openshift-network1 \
  --network openshift-networks \
  --range 10.240.0.0/24
gcloud compute firewall-rules create openshift-network-allow-internal \
  --allow tcp,udp,icmp \
  --network openshift-network \
  --source-ranges 10.0.0.0/24
gcloud compute firewall-rules create openshift-network-allow-external \
  --allow tcp:22,tcp:6443,icmp \
  --network openshift-network \
  --source-ranges 0.0.0.0/0
gcloud compute addresses create openshift-network \
  --region $(gcloud config get-value compute/region)
gcloud compute addresses create masterips2 --addresses=10.0.0.3 --subnet=openshift-network1 --region=europe-west1
gcloud compute addresses create masterips --addresses=10.0.0.3 --subnet=openshift-network1 --region=europe-west1 
