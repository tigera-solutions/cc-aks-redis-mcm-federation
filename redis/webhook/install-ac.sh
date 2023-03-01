#!/bin/bash
NAMESPACE=redis
LABEL_KEY=namespace-name
LABEL_VALUE=redis
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
CERT=`kubectl -n $NAMESPACE get secret admission-tls -o jsonpath='{.data.cert}'`
sed "s/NAMESPACE_OF_SERVICE_ACCOUNT/$NAMESPACE/g" $SCRIPT_DIR/webhook.yaml | kubectl create -f -
cat > $SCRIPT_DIR/modified-webhook.yaml <<EOF
webhooks:
- name: redb.admission.redislabs
  clientConfig:
    caBundle: $CERT
  admissionReviewVersions: ["v1beta1"]
EOF
kubectl patch ValidatingWebhookConfiguration redb-admission --patch "$(cat $SCRIPT_DIR/modified-webhook.yaml)"
kubectl label namespace $NAMESPACE $LABEL_KEY=$LABEL_VALUE
cat > $SCRIPT_DIR/modified-webhook.yaml <<EOF
webhooks:
- name: redb.admission.redislabs
  namespaceSelector:
    matchLabels:
      $LABEL_KEY: $LABEL_VALUE
EOF
kubectl patch ValidatingWebhookConfiguration redb-admission --patch "$(cat $SCRIPT_DIR/modified-webhook.yaml)"