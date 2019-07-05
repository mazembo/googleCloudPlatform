# for instance in worker-0 worker-1 worker-2; do
export instance="minion-node"
gcloud compute scp ca.pem ${instance}-key.pem ${instance}.pem ${instance}:~/
# done
