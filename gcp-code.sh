#create a network and sub-network
gcloud compute --project=warm-classifier-721 networks create vpn-network-2 --description="my second network in europe" --subnet-mode=custom

gcloud compute --project=warm-classifier-721 networks subnets create subnet-b --network=vpn-network-2 --region=europe-west1 --range=10.5.4.0/24 --enable-private-ip-google-access

# creation d'une premiere VM
gcloud compute --project=warm-classifier-721 instances create instance-1 --zone=us-east1-b --machine-type=f1-micro --subnet=subnet-a --network-tier=PREMIUM --maintenance-policy=MIGRATE --service-account=778083151326-compute@developer.gserviceaccount.com --scopes=https://www.googleapis.com/auth/cloud-platform --tags=http-server,https-server --image=debian-9-stretch-v20190514 --image-project=debian-cloud --boot-disk-size=10GB --boot-disk-type=pd-standard --boot-disk-device-name=instance-1

gcloud compute --project=warm-classifier-721 firewall-rules create vpn-network-1-allow-http --direction=INGRESS --priority=1000 --network=vpn-network-1 --action=ALLOW --rules=tcp:80 --source-ranges=0.0.0.0/0 --target-tags=http-server

gcloud compute --project=warm-classifier-721 firewall-rules create vpn-network-1-allow-https --direction=INGRESS --priority=1000 --network=vpn-network-1 --action=ALLOW --rules=tcp:443 --source-ranges=0.0.0.0/0 --target-tags=https-server

#create firewall rules to allow tcp 22 and icmp 
gcloud compute --project=warm-classifier-721 firewall-rules create allow-icmp-ssh-network-1 --direction=INGRESS --priority=1000 --network=vpn-network-1 --action=ALLOW --rules=tcp:22,icmp --source-ranges=0.0.0.0/0

# create VPN1
gcloud compute target-vpn-gateways \
create vpn-1 \
--network vpn-network-1  \
--region us-east1

# create VPN2
gcloud compute target-vpn-gateways \
create vpn-2 \
--network vpn-network-2  \
--region europe-west1

# create a static address
gcloud compute addresses create --region us-east1 vpn-1-static-ip

# to see the static address 
gcloud compute addresses list 

# export the static address in an environment variable 
export STATIC_IP_VPN_1=35.231.19.214 
export STATIC_IP_VPN_2=35.233.10.214 

# create forwarding rules
gcloud compute \
forwarding-rules create vpn-1-esp \
--region us-east1  \
--ip-protocol ESP  \
--address $STATIC_IP_VPN_1 \
--target-vpn-gateway vpn-1


gcloud compute \
forwarding-rules create vpn-2-esp \
--region europe-west1  \
--ip-protocol ESP  \
--address $STATIC_IP_VPN_2 \
--target-vpn-gateway vpn-2

gcloud compute \
forwarding-rules create vpn-1-udp500  \
--region us-east1 \
--ip-protocol UDP \
--ports 500 \
--address $STATIC_IP_VPN_1 \
--target-vpn-gateway vpn-1

gcloud compute \
forwarding-rules create vpn-2-udp500  \
--region europe-west1 \
--ip-protocol UDP \
--ports 500 \
--address $STATIC_IP_VPN_2 \
--target-vpn-gateway vpn-2

gcloud compute \
forwarding-rules create vpn-1-udp4500  \
--region us-east1 \
--ip-protocol UDP --ports 4500 \
--address $STATIC_IP_VPN_1 \
--target-vpn-gateway vpn-1

gcloud compute \
forwarding-rules create vpn-2-udp4500  \
--region europe-west1 \
--ip-protocol UDP --ports 4500 \
--address $STATIC_IP_VPN_2 \
--target-vpn-gateway vpn-2

#create tunnels 
gcloud compute \
vpn-tunnels create tunnel1to2  \
--peer-address $STATIC_IP_VPN_2 \
--region us-east1 \
--ike-version 2 \
--shared-secret gcprocks \
--target-vpn-gateway vpn-1 \
--local-traffic-selector 0.0.0.0/0 \
--remote-traffic-selector 0.0.0.0/0

gcloud compute \
vpn-tunnels create tunnel2to1 \
--peer-address $STATIC_IP_VPN_1 \
--region europe-west1 \
--ike-version 2 \
--shared-secret gcprocks \
--target-vpn-gateway vpn-2 \
--local-traffic-selector 0.0.0.0/0 \
--remote-traffic-selector 0.0.0.0/0

# create static routes 

gcloud compute  \
routes create route1to2  \
--network vpn-network-1 \
--next-hop-vpn-tunnel tunnel1to2 \
--next-hop-vpn-tunnel-region us-east1 \
--destination-range 10.1.3.0/24

gcloud compute  \
routes create route2to1  \
--network vpn-network-2 \
--next-hop-vpn-tunnel tunnel2to1 \
--next-hop-vpn-tunnel-region europe-west1 \
--destination-range 10.5.4.0/24

# create static routes 
gcloud compute  routes create route1to2  --network vpn-network-1 --next-hop-vpn-tunnel tunnel1to2 --next-hop-vpn-tunnel-region us-east1 --destination-range 10.5.4.0/24
gcloud compute  routes create route2to1  --network vpn-network-2 --next-hop-vpn-tunnel tunnel2to1 --next-hop-vpn-tunnel-region europe-west1 --destination-range 10.1.3.0/24





