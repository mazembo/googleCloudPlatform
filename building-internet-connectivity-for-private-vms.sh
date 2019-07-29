# https://cloud.google.com/solutions/building-internet-connectivity-for-private-vms
echo "an instance named www-1 in us-central1-bwith a basic startup script"
gcloud compute instances create www-1 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone us-central1-b \
    --tags http-tag \
    --network-interface=no-address \
    --metadata startup-script="#! /bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
sudo service apache2 restart
echo '<!doctype html><html><body><h1>www-1</h1></body></html>' | tee /var/www/html/index.html
EOF"
echo "Create an instance named www-2 in us-central1-b"
gcloud compute instances create www-2 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone us-central1-b \
    --tags http-tag \
    --network-interface=no-address \
    --metadata startup-script="#! /bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
sudo service apache2 restart
echo '<!doctype html><html><body><h1>www-2</h1></body></html>' | tee /var/www/html/index.html
EOF"
echo "Create an instance named www-3, this time in europe-west1-b"
gcloud compute instances create www-3 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone europe-west1-b \
    --tags http-tag \
    --network-interface=no-address \
    --metadata startup-script="#! /bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
sudo service apache2 restart
echo '<!doctype html><html><body><h1>www-3</h1></body></html>' | tee /var/www/html/index.html
EOF"
echo "Create an instance named www-4, this one also in europe-west1-b"
gcloud compute instances create www-4 \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone europe-west1-b \
    --tags http-tag \
    --network-interface=no-address \
    --metadata startup-script="#! /bin/bash
sudo apt-get update
sudo apt-get install apache2 -y
sudo service apache2 restart
echo '<!doctype html><html><body><h1>www-4</h1></body></html>' | tee /var/www/html/index.html
EOF"

echo "Create a firewall rule named allow-ssh-from-iap" 
gcloud compute firewall-rules create allow-ssh-from-iap \
    --source-ranges 35.235.240.0/20 \
    --target-tags http-tag \
    --allow tcp:22
# Test tunneling 
#gcloud beta compute ssh www-1 \
#    --zone us-central1-b \
#    --tunnel-through-iap
# manual step_ add identity aware proxy role under security from the console  to create vms 
echo "create a nat configuration using cloud router"
echo "create cloud router instances in each region"
gcloud compute routers create nat-router-us-central1 \
    --network default \
    --region us-central1

gcloud compute routers create nat-router-europe-west1 \
    --network default \
    --region europe-west1
echo "configure the routers for cloud NAT"
gcloud compute routers nats create nat-config \
    --router-region us-central1 \
    --router nat-router-us-central1 \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips

gcloud compute routers nats create nat-config \
    --router-region europe-west1 \
    --router nat-router-europe-west1 \
    --nat-all-subnet-ip-ranges \
    --auto-allocate-nat-external-ips
# test cloud nat configuration 
# In Cloud Shell, connect to your instance using the tunnel you created
# gcloud beta compute ssh www-1 --tunnel-through-iap 
# When you're logged in to the instance, use the curl command to make an outbound request
# curl example.com 
echo "Creating an HTTP load-balanced service for serving"
echo "open the firewall"
echo "Create a firewall rule named allow-lb-and-healthcheck"
gcloud compute firewall-rules create allow-lb-and-healthcheck \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --target-tags http-tag \
    --allow tcp:80
echo "Allocate an external IP address for load balancers"
echo "Create a static IP address named lb-ip-cr for IPv4"
gcloud compute addresses create lb-ip-cr \
    --ip-version=IPV4 \
    --global
echo "Create a static IP address named lb-ipv6-cr for IPv6"
gcloud compute addresses create lb-ipv6-cr \
    --ip-version=IPV6 \
    --global
echo "Create instance groups and add instances"
echo "Create the us-resources-w instance group"

gcloud compute instance-groups unmanaged create us-resources-w \
    --zone us-central1-b
echo "Add the www-1 and www-2 instances"

gcloud compute instance-groups unmanaged add-instances us-resources-w \
    --instances www-1,www-2 \
    --zone us-central1-b

echo "Create the europe-resources-w instance group"

gcloud compute instance-groups unmanaged create europe-resources-w \
    --zone europe-west1-b

echo "Add the www-3 and www-4 instances"

gcloud compute instance-groups unmanaged add-instances europe-resources-w \
    --instances www-3,www-4 \
    --zone europe-west1-b
echo "Configure the load balancing service"
echo "For each instance group, define an HTTP service and map a port name to the relevant port"
gcloud compute instance-groups unmanaged set-named-ports us-resources-w \
    --named-ports http:80 \
    --zone us-central1-b

gcloud compute instance-groups unmanaged set-named-ports europe-resources-w \
    --named-ports http:80 \
    --zone europe-west1-b
echo "Create a health check"
gcloud compute health-checks create http http-basic-check \
    --port 80
echo "Create a backend service"

gcloud compute backend-services create web-map-backend-service \
    --protocol HTTP \
    --health-checks http-basic-check \
    --global
echo "Add your instance groups as backends to the backend services"
gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group us-resources-w \
    --instance-group-zone us-central1-b \
    --global

gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group europe-resources-w \
    --instance-group-zone europe-west1-b \
    --global
echo "Create a default URL map that directs all incoming requests to all of your instances"

gcloud compute url-maps create web-map \
    --default-service web-map-backend-service

echo "Create a target HTTP proxy to route requests to the URL map"

gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map

echo "Configure the frontend"
# get the load balancer ip address 
lb_ip_address=$(gcloud compute addresses describe lb_ip_address --region 'europe-west1'  --format 'value(address)')
lb_ipv6_address=$(gcloud compute addresses describe lb_ip_address --region 'europe-west1'  --format 'value(address)')

gcloud compute forwarding-rules create http-cr-rule \
    --address lb_ip_address \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80

gcloud compute forwarding-rules create http-cr-ipv6-rule \
    --address lb_ipv6_address \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80
# Test your solution 

#echo "Get the IP addresses of your global forwarding rules, and make a note of them for the next step"
#gcloud compute forwarding-rules list
#curl http://ipv4-address
#curl -g -6 "http://[ipv6-address]/"
