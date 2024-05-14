#!/bin/bash

function create_sa_read_api() {
    echo "Create SA liveoptics-read-api"
    kubectl create serviceaccount liveoptics-read-api
    cat >sa-secret-token.yaml <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: liveoptics-read-api-token
  annotations:
    kubernetes.io/service-account.name: "liveoptics-read-api"
type: kubernetes.io/service-account-token
EOF
  kubectl apply -f sa-secret-token.yaml

    echo "Create ClusterRoleBinding"
    cat >cluster_role.yaml <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: storage-and-metrics-access
rules:
- apiGroups: ["storage.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["snapshot.storage.k8s.io/v1"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["metrics.k8s.io"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""] # "" indicates the core API group
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["daemonsets"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["replicasets"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["statefulsets"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["persistentvolumeclaims"]
  verbs: ["get", "watch", "list"]
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "watch", "list"]
EOF

    kubectl apply -f cluster_role.yaml

    kubectl create clusterrolebinding liveoptics-read-api --clusterrole=storage-and-metrics-access --serviceaccount=default:liveoptics-read-api

    echo "Obtain token"

    # secret_name=$(kubectl get serviceaccount liveoptics-read-api -o jsonpath='{.secrets[0].name}')
    # token get
    token=$(kubectl get secret liveoptics-read-api-token -o jsonpath='{.data.token}' | base64 --decode)

    echo "Token: $token for serviceaccount read-api"

    echo "Generate kubeconfig file for the account"

    certificate_authority=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}')
    endpoint=$(kubectl config view --raw -o jsonpath='{.clusters[0].cluster.server}')

    cat >kubeconfig_liveoptics-read-api.yaml <<EOF
apiVersion: v1
kind: Config
clusters:
- cluster:
    certificate-authority-data: $certificate_authority
    server: $endpoint
  name: default-cluster
contexts:
- context:
    cluster: default-cluster
    namespace: default
    user: liveoptics-read-api
  name: default-context
current-context: default-context
users:
- name: liveoptics-read-api
  user:
    token: $token
EOF
}
function cleanup() {
    kubectl delete clusterrolebinding liveoptics-read-api
    kubectl delete serviceaccount liveoptics-read-api
    kubectl delete clusterrole storage-and-metrics-access
    rm sa-secret-token.yaml
    rm cluster_role.yaml
    rm kubeconfig_liveoptics-read-api.yaml
}

if [ $# -eq 0 ]; then
  echo "Error: No option provided."
  echo "Usage: $0 [--create|--delete]"
  exit 1
fi

for arg in "$@"
do
  case $arg in
    --create)
    create_sa_read_api
    ;;
    --delete)
    cleanup
    ;;
    *)
    echo "Usage: $0 [--create|--delete]"
    exit 1
  esac
done
