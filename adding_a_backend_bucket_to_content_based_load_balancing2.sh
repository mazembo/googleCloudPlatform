# https://cloud.google.com/load-balancing/docs/https/adding-a-backend-bucket-to-content-based-load-balancing
gcloud config set project [PROJECT_ID]
gcloud compute instances create www \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone us-central1-b \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      sudo apt-get update
      sudo apt-get install apache2 -y
      sudo service apache2 restart
      echo '<!doctype html><html><body><h1>www</h1></body></html>' | sudo tee /var/www/html/index.html
      EOF"
gcloud compute instances create www-video \
    --image-family debian-9 \
    --image-project debian-cloud \
    --zone us-central1-b \
    --tags http-tag \
    --metadata startup-script="#! /bin/bash
      sudo apt-get update
      sudo apt-get install apache2 -y
      sudo service apache2 restart
      echo '<!doctype html><html><body><h1>www-video</h1></body></html>' | sudo tee /var/www/html/index.html
      sudo mkdir /var/www/html/video
      echo '<!doctype html><html><body><h1>www-video</h1></body></html>' | sudo tee /var/www/html/video/index.html
      EOF"
echo " create a firewall rule to allow HTTP(S) or HTTP/2 traffic to your VMs"
gcloud compute firewall-rules create www-firewall \
    --target-tags http-tag --allow tcp:80
echo "Configuring services needed by the load balancing service"
echo "Create IPv4 and IPv6 global static external IP addresses for your load balancer"
gcloud compute addresses create lb-ip-1 \
    --ip-version=IPV4 \
    --global
gcloud compute addresses create lb-ipv6-1 \
    --ip-version=IPV6 \
    --global
echo "Create an instance group for each traffic type"
gcloud compute instance-groups unmanaged add-instances video-resources \
    --instances www-video \
    --zone us-central1-b
gcloud compute instance-groups unmanaged add-instances www-resources \
    --instances www \
    --zone us-central1-b
echo "Configuring the load balancing service"
gcloud compute instance-groups unmanaged set-named-ports video-resources \
    --named-ports http:80 \
    --zone us-central1-b
gcloud compute instance-groups unmanaged set-named-ports www-resources \
    --named-ports http:80 \
    --zone us-central1-b
echo "create health check"
gcloud compute health-checks create http http-basic-check \
    --port 80
echo "create backservice"
gcloud compute backend-services create video-service \
    --protocol HTTP \
    --health-checks http-basic-check \
    --global
gcloud compute backend-services create web-map-backend-service \
    --protocol HTTP \
    --health-checks http-basic-check \
    --global
echo "Add your instance groups as backends to the backend services"
gcloud compute backend-services add-backend video-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group video-resources \
    --instance-group-zone us-central1-b \
    --global

gcloud compute backend-services add-backend web-map-backend-service \
    --balancing-mode UTILIZATION \
    --max-utilization 0.8 \
    --capacity-scaler 1 \
    --instance-group www-resources \
    --instance-group-zone us-central1-b \
    --global
echo "create a url map"
gcloud compute url-maps create web-map \
    --default-service web-map-backend-service
echo "Add a path matcher to your URL map and define your request path mappings"
gcloud compute url-maps add-path-matcher web-map \
    --default-service web-map-backend-service \
    --path-matcher-name pathmap \
    --path-rules="/video=video-service,/video/*=video-service"
gcloud compute url-maps add-path-matcher web-map \
    --default-service web-map-backend-service \
    --path-matcher-name bucket-matcher \
    --backend-bucket-path-rules="/static/*=static-bucket"
echo "Create a target HTTP proxy to route requests to your URL map"
gcloud compute target-http-proxies create http-lb-proxy \
    --url-map web-map
echo "Create two global forwarding rules to route incoming requests to the proxy, one for IPv4 and one for IPv6"
gcloud compute forwarding-rules create http-content-rule \
    --address [LB_IP_ADDRESS] \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80

gcloud compute forwarding-rules create http-content-ipv6-rule \
    --address [LB_IPV6_ADDRESS] \
    --global \
    --target-http-proxy http-lb-proxy \
    --ports 80
echo "Find the IP addresses of your global forwarding rules."
gcloud compute forwarding-rules list 
echo "Use the curl command to test the response for various URLs for your services"
curl http://IPv4_ADDRESS/video/
curl http://IPv4_ADDRESS

curl -g -6 "http://[IPv6_ADDRESS]/video/"
curl -g -6 "http://[IPv6_ADDRESS]/"
echo "Shutting off HTTP(S) access from everywhere but the load balancing service"
gcloud compute firewall-rules create allow-lb-and-healthcheck \
    --source-ranges 130.211.0.0/22,35.191.0.0/16 \
    --target-tags http-tag \
    --allow tcp:80
echo "Then, remove the rule that allows HTTP(S) traffic from other sources"
gcloud compute firewall-rules delete www-firewall
echo "Test that the load balancer can reach the instances, but that other sources can't"
echo "Find the IP address of your global forwarding rule"
gcloud compute addresses list
echo "Use the curl command to test the response for various URLs for your services. All of these commands should work."
curl http://IP_ADDRESS/video/
curl http://IP_ADDRESS
# Find the IP address of your individual instances and note the addresses in the EXTERNAL_IP column.
gcloud compute instances list
# Use the curl command to test the response for various URLs for your services. For each curl command, use the EXTERNAL_IP of the appropriate instance. All of these commands should time out
curl http://EXTERNAL_IP/video/
curl http://EXTERNAL_IP
#Optional: Removing external IP addresses except for a bastion host
#Run the following command. Make a note of the name of the instance as shown in the NAME field.
gcloud compute instances list
# Delete the access config for the instance. For NAME, put the name of the instance.
gcloud compute instances delete-access-config NAME

echo "Use the gsutil mb command and a unique name to create a bucket"

gsutil mb gs://my-awesome-bucket/
gsutil cp [OBJECT_NAME] gs://[EXAMPLE_BUCKET]/static/[OBJECT_NAME]

#[EXAMPLE_BUCKET] - the bucket you already created
#[OBJECT_NAME] - the filename of an object to upload

# Make the object publicly readable so it can be served through load balancing
gsutil acl ch -u AllUsers:R gs://[EXAMPLE_BUCKET]/static/[OBJECT_NAME]
# Instead of creating a backend service for static content as you did for video content, create a new backend bucket that points to the Cloud Storage bucket you created above.
gcloud compute backend-buckets create static-bucket \
    --gcs-bucket-name [EXAMPLE_BUCKET]
# [EXAMPLE_BUCKET] - the bucket you created
# Fetching resources from your Cloud Storage bucket
gcloud compute forwarding-rules list
# curl http://[IP_ADDRESS]/static/[OBJECT_NAME]
# curl -k https://[IP_ADDRESS]/static/[OBJECT_NAME]
#    [IP_ADDRESS] - the IP address of your global forwarding rule
#    [OBJECT_NAME] - use the name of the example object you uploaded
#This command should respond with [OBJECT_NAME] from your [EXAMPLE_BUCKET] Cloud Storage bucket.
#If you store an object in the bucket with name of static/path/to/[OBJECT_NAME], you can retrieve it with a URL of http://[IP_ADDRESS]/static/path/to/[OBJECT_NAME]
