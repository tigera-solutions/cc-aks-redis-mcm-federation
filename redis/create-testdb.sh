#!/usr/bin/env bash
# This is a really hacky script that is dumb and only works with 2 clusters/arguments due to keeping the --instance flags static in the command for a copy-paste workshop setup. Needs work.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
source $SCRIPT_DIR/setup.env

for i in "${!K8S_CONTEXTS[@]}"
do
    kubectl config use-context ${K8S_CONTEXTS[i]}
    REC=$(kubectl -n $NAMESPACE get rec | cut -d " " -f 1 | grep -v NAME)
    echo "Getting the passwords from secrets"
    PASSWORD+=($(kubectl -n $NAMESPACE get secret $REC -o jsonpath='{.data.password}' | base64 --decode))
done

kubectl -n $NAMESPACE exec -it $REC-0 -- sh -c " crdb-cli crdb create \
    --name testdb \
    --memory-size 500MB \
    --encryption yes \
    --port 11069 \
    --instance fqdn=demo-clustera.redis.svc.cluster.local,url=https://api-clustera.tigera.redisdemo.com,username=demo@redislabs.com,password=${PASSWORD[0]},replication_endpoint=testdb-clustera.tigera.redisdemo.com:443,replication_tls_sni=testdb-clustera.tigera.redisdemo.com \
    --instance fqdn=demo-clusterb.redis.svc.cluster.local,url=https://api-clusterb.tigera.redisdemo.com,username=demo@redislabs.com,password=${PASSWORD[1]},replication_endpoint=testdb-clusterb.tigera.redisdemo.com:443,replication_tls_sni=testdb-clusterb.tigera.redisdemo.com "