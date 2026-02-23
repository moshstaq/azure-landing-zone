set -e

echo "Fetching current Terraform outputs..."

CD_DIR=$(dirname "$0")
cd "$CD_DIR"

CLIENT_ID=$(terraform output -raw workload_identity_client_id)
KV_NAME=$(terraform output -raw key_vault_name)

echo "Client ID: $CLIENT_ID"
echo "Key Vault: $KV_NAME"

echo "Updating manifests..."

sed -i '' "s|azure.workload.identity/client-id:.*|azure.workload.identity/client-id: \"$CLIENT_ID\"|" \
  manifests/serviceaccount.yaml

sed -i '' "s|clientID:.*|clientID: \"$CLIENT_ID\"|" \
  manifests/secretprovider.yaml

sed -i '' "s|keyvaultName:.*|keyvaultName: \"$KV_NAME\"|" \
  manifests/secretprovider.yaml

echo "Done. Apply manifests with:"
echo "  kubectl apply -f manifests/serviceaccount.yaml"
echo "  kubectl apply -f manifests/secretprovider.yaml"

AGIC_CLIENT_ID=$(terraform output -raw agic_client_id)
APPGW_ID=$(terraform output -raw appgw_id 2>/dev/null || echo "")

echo ""
echo "AGIC Helm install command:"
echo "helm install ingress-azure \\"
echo "  oci://mcr.microsoft.com/azure-application-gateway/charts/ingress-azure \\"
echo "  --namespace kube-system \\"
echo "  --set appgw.applicationGatewayID=$APPGW_ID \\"
echo "  --set armAuth.type=workloadIdentity \\"
echo "  --set armAuth.identityClientID=$AGIC_CLIENT_ID \\"
echo "  --set rbac.enabled=true"