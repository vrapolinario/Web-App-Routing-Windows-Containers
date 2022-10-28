#This script will create a new AKS cluster and deploy 

#Log into the Azure subscription
$Az_Sub = Read-Host -Prompt 'Please provide the Azure subscription ID to be used'
az login --use-device-code
az account set --subscription $Az_Sub

# Install the aks-preview extension
az extension add --name aks-preview
# Update the extension to make sure you have the latest version installed
az extension update --name aks-preview

# Create a self-signed SSL certificate
$Hostname = Read-Host -Prompt 'Please provide the Hostname to be used for the certificate'
openssl req -new -x509 -nodes -out aks-ingress-tls.crt -keyout aks-ingress-tls.key -subj "/CN=$Hostname" -addext "subjectAltName=DNS:$Hostname"
# Export the SSL certificate, skipping the password prompt
openssl pkcs12 -export -in aks-ingress-tls.crt -inkey aks-ingress-tls.key -out aks-ingress-tls.pfx

#Create new Resource Group
$RGName = Read-Host -Prompt 'Please provide the Resource Group name'
$RGLocation = Read-Host -Prompt 'Please provide the location of the RG and its resources'
az group create -n $RGName -l $RGLocation

#Create the Azure Key Vault
$AKVName = Read-Host -Prompt 'Please provide the name of the Azure Key Vault'
az keyvault create -g $RGName -l $RGLocation -n $AKVName

#Import certificate to Azure Key Vault
$AKVCertName = Read-Host -Prompt 'Please provide a name for the certificate to be stored on Azure Key Vault'
az keyvault certificate import --vault-name $AKVName -n $AKVCertName -f aks-ingress-tls.pfx

#Create the AKS cluster
Write-Host 'Next, we will create an AKS cluster'
$AKSClusterName = Read-Host -Prompt 'Please provide the name for the Azure Kubernetes Service cluster'
$WinUsername = Read-Host -Prompt 'Please create a username for the administrator credentials on your Windows Server nodes'
$WinPassword = Read-Host -Prompt 'Please create a password for the administrator credentials on your Windows Server nodes' -AsSecureString
az aks create -g $RGName -n $AKSClusterName -l $RGLocation --node-count 2 --enable-addons azure-keyvault-secrets-provider,web_application_routing,monitoring --generate-ssh-keys --enable-secret-rotation --network-plugin azure --vm-set-type VirtualMachineScaleSets --windows-admin-username $WinUsername --windows-admin-password $WinPassword`
$AKSNodepoolName = Read-Host -Prompt 'Please provide the name for the nodepool (max 6 characters)'
az aks nodepool add -g $RGName --cluster-name $AKSClusterName --os-type Windows --name $AKSNodepoolName --node-count 1

#Retrieve user managed identity object ID for the add-on
$ManagedIdentityName = "webapprouting-$AKSClusterName"
$MCRGName = az aks show -g $RGName -n $AKSClusterName --query nodeResourceGroup -o tsv
$UserManagedIdentity_ResourceID = "/subscriptions/$Az_Sub/resourceGroups/$MCRGName/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$ManagedIdentityName"
$ManagedIdentity_ObjectID = az resource show --id $UserManagedIdentity_ResourceID --query "properties.principalId" -o tsv | tr -d '[:space:]'

#Grant the add-on permissions to retrieve certificates from Azure Key Vault
az keyvault set-policy --name $AKVName --object-id $ManagedIdentity_ObjectID --secret-permissions get --certificate-permissions get

#Connect to your AKS cluster
az aks get-credentials -g $RGName -n $AKSClusterName

#Create a namespace for the application on your AKS cluster
$NamespaceName = Read-Host -Prompt 'Please provide the name for the samespace on which the app will be deployed'
kubectl create namespace $NamespaceName

