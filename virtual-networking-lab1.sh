# create network automatic
gcloud compute --project=warm-classifier-721 networks create learnauto --description=learnauto --subnet-mode=auto
gcloud compute --project=warm-classifier-721 firewall-rules create allow-icmp-learn-auto --description=allow-icmp-learn-auto --direction=INGRESS --priority=1000 --network=learnauto --action=ALLOW --rules=icmp --source-ranges=0.0.0.0/0
# create network "learncustom" and three subnets "subnet-a in europe-west1 subnet-b in europe-west1 subnet-c in us-east1"
gcloud compute --project=warm-classifier-721 networks create learncustom --description=learncustom --subnet-mode=custom

gcloud compute --project=warm-classifier-721 networks subnets create subnet-a --network=learncustom --region=europe-west1 --range=192.168.5.0/24 --enable-private-ip-google-access

gcloud compute --project=warm-classifier-721 networks subnets create subnet-b --network=learncustom --region=europe-west1 --range=192.168.3.0/24 --enable-private-ip-google-access

gcloud compute --project=warm-classifier-721 networks subnets create subnet-c --network=learncustom --region=us-east1 --range=192.168.4.0/24 --enable-private-ip-google-access

# create firewall rules allowing ssh(tcp:22), icmp, and tcp:3389 for the network: learncustom
gcloud compute --project=warm-classifier-721 firewall-rules create allow-ssh-icmp-rdp-learncustom --description=learncustom --direction=INGRESS --priority=1000 --network=learncustom --action=ALLOW --rules=tcp:22,tcp:3389,icmp --source-ranges=0.0.0.0/0

#//create learn-1 instance
gcloud compute --project=warm-classifier-721 instances create learn-1 --zone=us-east1-b --machine-type=f1-micro --subnet=default --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --image=debian-9-stretch-v20190618 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=learn-1

#//create learn-2 instance
gcloud compute --project=warm-classifier-721 instances create learn-2 --zone=us-east1-b --machine-type=f1-micro --subnet=learnauto --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --image=debian-9-stretch-v20190618 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=learn-2

gcloud compute --project=warm-classifier-721 firewall-rules create learnauto-allow-http --direction=INGRESS --priority=1000 --network=learnauto --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

gcloud compute --project=warm-classifier-721 firewall-rules create learnauto-allow-https --direction=INGRESS --priority=1000 --network=learnauto --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=https-server

#create learn-3 instance
gcloud compute --project=warm-classifier-721 instances create learn-3 --zone=europe-west1-b --machine-type=f1-micro --subnet=subnet-b --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --image=debian-9-stretch-v20190618 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=learn-3

gcloud compute --project=warm-classifier-721 firewall-rules create learncustom-allow-http --direction=INGRESS --priority=1000 --network=learncustom --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

gcloud compute --project=warm-classifier-721 firewall-rules create learncustom-allow-https --direction=INGRESS --priority=1000 --network=learncustom --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=https-server
#create learn-4 instance
gcloud compute --project=warm-classifier-721 instances create learn-4 --zone=europe-west1-b --machine-type=f1-micro --subnet=subnet-a --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --image=debian-9-stretch-v20190618 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=learn-4
#create learn-5 instance
gcloud compute --project=warm-classifier-721 instances create learn-5 --zone=us-east1-b --machine-type=f1-micro --subnet=subnet-c --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --image=debian-9-stretch-v20190618 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=learn-5
