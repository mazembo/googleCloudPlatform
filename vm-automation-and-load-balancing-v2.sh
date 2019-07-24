gcloud compute --project=warm-classifier-721 instances create webserver1 --zone=europe-west1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --metadata=startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-1 --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=int-lb --image=ubuntu-1804-bionic-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=webserver1
gcloud compute --project=warm-classifier-721 instances create webserver2 --zone=europe-west1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --metadata=startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-2 --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=int-lb --image=ubuntu-1804-bionic-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=webserver2
gcloud compute --project=warm-classifier-721 instances create webserver3 --zone=europe-west1-b --machine-type=n1-standard-1 --subnet=default --network-tier=PREMIUM --metadata=startup-script-url=gs://cloud-training/archinfra/mystartupscript,my-server-id=WebServer-3 --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/servicecontrol,https://www.googleapis.com/auth/service.management.readonly,https://www.googleapis.com/auth/logging.write,https://www.googleapis.com/auth/monitoring.write,https://www.googleapis.com/auth/trace.append,https://www.googleapis.com/auth/devstorage.read_only --tags=int-lb --image=ubuntu-1804-bionic-v20190628 --image-project=ubuntu-os-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=webserver3

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

# create two other vms in a different zone with a different network tags 
echo 'create two other vms in a different zone with a different network tags'
gcloud compute instances create webserver4 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --tags int-lb \
    --zone $MY_ZONE2 \
    --subnet default \
    --metadata startup-script-url="gs://cloud-training/archinfra/mystartupscript",my-server-id="WebServer-4"

gcloud compute instances create webserver5 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --tags int-lb \
    --zone $MY_ZONE2 \
    --subnet default \
    --metadata startup-script-url="gs://cloud-training/archinfra/mystartupscript",my-server-id="WebServer-5"

# create an instance group for each zone and add the instances 
echo 'create an instance group for each zone and add the instances'
gcloud compute instance-groups unmanaged create ig1 \
    --zone $MY_ZONE1
gcloud compute instance-groups unmanaged add-instances ig1 \
    --instances=webserver1,webserver2,webserver3 --zone $MY_ZONE1
gcloud compute instance-groups unmanaged create ig2 \
    --zone $MY_ZONE2
gcloud compute instance-groups unmanaged add-instances ig2 \
    --instances=webserver4,webserver5 --zone $MY_ZONE2
echo 'configure load balancer...'
echo 'creating health-checks...'
gcloud compute health-checks create tcp my-tcp-health-check \
    --port 80
echo 'creating backend services ... '
gcloud compute backend-services create my-int-lb \
    --load-balancing-scheme internal \
    --region $MY_REGION \
    --health-checks my-tcp-health-check \
    --protocol tcp
echo 'adding ig1 to back end services ...'
gcloud compute backend-services add-backend my-int-lb \
    --instance-group ig1 \
    --instance-group-zone $MY_ZONE1 \
    --region $MY_REGION
echo 'adding ig2 to back end services ...'
gcloud compute backend-services add-backend my-int-lb \
    --instance-group ig2 \
    --instance-group-zone $MY_ZONE2 \
    --region $MY_REGION
echo 'creating the forwarding rule ...'
gcloud compute forwarding-rules create my-int-lb-forwarding-rule \
    --load-balancing-scheme internal \
    --ports 80 \
    --network default \
    --subnet default \
    --region $MY_REGION \
    --backend-service my-int-lb
echo "creating firewall rules to allow traffic to the load balancer and from the loadbalancer to instances"
gcloud compute firewall-rules create allow-internal-lb \
    --network default \
    --source-ranges 10.128.0.0/20 \
    --target-tags int-lb \
    --allow tcp:80,tcp:443
echo "firewall rules to allow health probes from the health checker"
gcloud compute firewall-rules create allow-health-check \
    --network default \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --target-tags int-lb \
    --allow tcp
echo "creating standalone instance for test purposes"
gcloud compute instances create standalone-instance-1 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone $MY_ZONE1 \
    --tags standalone \
    --subnet default
echo "allow ssh to standalone"
gcloud compute firewall-rules create allow-ssh-to-standalone \
    --network default \
    --target-tags standalone \
    --allow tcp:22
