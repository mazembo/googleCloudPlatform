gcloud compute --project=warm-classifier-721 instances create webserver1 --zone=europe-west1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --metadata=startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-1 --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=http-server,https-server --image=ubuntu-1804-bionic-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=webserver1
gcloud compute --project=warm-classifier-721 instances create webserver2 --zone=europe-west1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --metadata=startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-2 --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=http-server,https-server --image=ubuntu-1804-bionic-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=webserver2
gcloud compute --project=warm-classifier-721 instances create webserver3 --zone=europe-west1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --metadata=startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-3 --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=http-server,https-server --image=ubuntu-1804-bionic-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=webserver3

# reserve static IP address for load balancing 

gcloud compute addresses create network-lb-ip --project=warm-classifier-721 --description=ip\ address\ for\ load\ balancer --region=europe-west1

# get the static IP in a variable 
STATIC_EXTERNAL_ADDRESS=$(gcloud compute addresses describe network-lb-ip --region 'europe-west1'  --format 'value(address)')
# create health checks
gcloud compute --project "warm-classifier-721" http-health-checks create "webserver-health" --description "webserver-health" --port "80" --request-path "/" --check-interval "10" --timeout "5" --unhealthy-threshold "3" --healthy-threshold "2"

#configure the load balancer 
export MY_REGION='europe-west1'
export MY_ZONE1='europe-west1-b'
export MY_ZONE2='europe-west1-c'

gcloud compute target-pools create extloadbalancer \
    --region $MY_REGION --http-health-check webserver-health

gcloud compute target-pools add-instances extloadbalancer \
    --instances webserver1,webserver2,webserver3 \
     --instances-zone=$MY_ZONE1
#getting the static external IP 
# export STATIC_EXTERNAL_IP=STATIC_EXTERNAL_ADDRESS
# creating forwarding rule 
gcloud compute forwarding-rules create webserver-rule \
    --region $MY_REGION --ports 80 \
    --address $STATIC_EXTERNAL_ADDRESS --target-pool extloadbalancer
