# Create a service account 
gcloud iam service-accounts create jenkins --display-name jenkins

# Get email and project 
export SA_EMAIL=$(gcloud iam service-accounts list \
    --filter="displayName:jenkins" --format='value(email)')
export PROJECT=$(gcloud info --format='value(config.project)')

# Associate these roles 
gcloud projects add-iam-policy-binding $PROJECT \
    --role roles/storage.admin --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/compute.instanceAdmin.v1 \
    --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/compute.networkAdmin \
    --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/compute.securityAdmin \
    --member serviceAccount:$SA_EMAIL
gcloud projects add-iam-policy-binding $PROJECT --role roles/iam.serviceAccountActor \
    --member serviceAccount:$SA_EMAIL
# Create the key of the service account and download it 
gcloud iam service-accounts keys create jenkins-sa.json --iam-account $SA_EMAIL

# Create ssh key and put it project metadata 
ls ~/.ssh/id_rsa.pub || ssh-keygen -N "" 
gcloud compute project-info describe \
    --format=json | jq -r '.commonInstanceMetadata.items[] | select(.key == "ssh-keys") | .value' > sshKeys.pub
echo "$USER:$(cat ~/.ssh/id_rsa.pub)" >> sshKeys.pub
gcloud compute project-info add-metadata --metadata-from-file ssh-keys=sshKeys.pub

# download and decompress packer 
wget https://releases.hashicorp.com/packer/0.12.3/packer_0.12.3_linux_amd64.zip
unzip packer_0.12.3_linux_amd64.zip

export PROJECT=$(gcloud info --format='value(config.project)')
cat > jenkins-agent.json <<EOF
{
  "builders": [
    {
      "type": "googlecompute",
      "project_id": "$PROJECT",
      "source_image_family": "ubuntu-1604-lts",
      "source_image_project_id": "ubuntu-os-cloud",
      "zone": "us-central1-a",
      "disk_size": "10",
      "image_name": "jenkins-agent-{{timestamp}}",
      "image_family": "jenkins-agent",
      "ssh_username": "ubuntu"
    }
  ],
  "provisioners": [
    {
      "type": "shell",
      "inline": ["sudo apt-get update",
                  "sudo apt-get install -y default-jdk"]
    }
  ]
}
EOF



