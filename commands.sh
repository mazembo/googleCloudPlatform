gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"
gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"
gcloud compute instances list
gcloud compute addresses list --filter="name=('openshift-network')"
#list all systemd services in state running
systemctl list-units --type service --state runningjournalctl -u service-name.service
journalctl -u service-name.service
# List the etcd cluster members:
sudo ETCDCTL_API=3 etcdctl member list \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/etcd/ca.pem \
  --cert=/etc/etcd/kubernetes.pem \
  --key=/etc/etcd/kubernetes-key.pem
gcloud compute instances describe [INSTANCE_NAME]
# in order to delete the access config
gcloud compute instances delete-access-config [INSTANCE_NAME] \
    --access-config-name "[ACCESS_CONFIG_NAME]"
