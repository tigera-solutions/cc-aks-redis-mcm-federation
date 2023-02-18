#! /usr/bin/env bash

REGIONS=( "canadacentral" "eastus" "westus2" )
KUBECONFIG_PATH=( "$HOME/.kube/config" "$HOME/.kube/config" "$HOME/.kube/config")
contexts=$(kubectl config get-contexts | awk '{print $2}' | grep -v "NAME")
readarray -t contexts_array <<<"$contexts"
declare -p contexts_array

# Make sure kubectl is installed
if ! [ -x "$(command -v kubectl)" ]; then
  echo 'Error: kubectl is required and was not found' >&2
  exit 1
fi

# Create and test the remote cluster kubeconfig files
for i in "${!REGIONS[@]}"
do
export KUBECONFIG=${KUBECONFIG_PATH[i]}
kubectl config use-context ${contexts_array[i]} 


echo "Create remote cluster kubeconfig for ${REGIONS[i]}"
cat > ./calico-demo-${REGIONS[i]}-kubeconfig <<'EOF'
apiVersion: v1
kind: Config
users:
- name: tigera-federation-remote-cluster
  user:
    token: YOUR_SERVICE_ACCOUNT_TOKEN
clusters:
- name: tigera-federation-remote-cluster
  cluster:
    certificate-authority-data: YOUR_CERTIFICATE_AUTHORITY_DATA
    server: YOUR_SERVER_ADDRESS
contexts:
- name: tigera-federation-remote-cluster-ctx
  context:
    cluster: tigera-federation-remote-cluster
    user: tigera-federation-remote-cluster
current-context: tigera-federation-remote-cluster-ctx
EOF

YOUR_SERVICE_ACCOUNT_TOKEN=$(kubectl get secret -n kube-system $(kubectl get sa -n kube-system tigera-federation-remote-cluster -o jsonpath='{range .secrets[*]}{.name}{"\n"}{end}' | grep token) -o go-template='{{.data.token|base64decode}}')
YOUR_CERTIFICATE_AUTHORITY_DATA=$(kubectl config view --flatten --minify -o jsonpath='{range .clusters[*]}{.cluster.certificate-authority-data}{"\n"}{end}')
YOUR_SERVER_ADDRESS=$(kubectl config view --flatten --minify -o jsonpath='{range .clusters[*]}{.cluster.server}{"\n"}{end}')

sed -i  s,YOUR_SERVICE_ACCOUNT_TOKEN,$YOUR_SERVICE_ACCOUNT_TOKEN,g ./calico-demo-${REGIONS[i]}-kubeconfig
sed -i  s,YOUR_CERTIFICATE_AUTHORITY_DATA,$YOUR_CERTIFICATE_AUTHORITY_DATA,g ./calico-demo-${REGIONS[i]}-kubeconfig
sed -i  s,YOUR_SERVER_ADDRESS,$YOUR_SERVER_ADDRESS,g ./calico-demo-${REGIONS[i]}-kubeconfig

echo "Test remote cluster kubeconfig for ${REGIONS[i]}"
kubectl --kubeconfig ./calico-demo-${REGIONS[i]}-kubeconfig get services
echo
done
