@description('Six lowercase alphanumeric characters shared by every resource in this workshop, including the resource group name you create beforehand. Generate once and reuse everywhere.')
@minLength(6)
@maxLength(6)
param workshopId string

@description('Base name placed before the workshop ID')
param namePrefix string = 'aks-lab'

@description('Azure region')
param location string = resourceGroup().location

@description('Microsoft Entra tenant ID')
param tenantId string

@description('Trusted API server egress IP ranges')
param authorizedIpRanges array

@description('Address space for the workshop VNet')
param vnetAddressPrefix string = '10.60.0.0/16'

@description('Address range for the AKS node subnet')
param nodeSubnetPrefix string = '10.60.0.0/24'

@description('Overlay pod address range')
param podCidr string = '10.245.0.0/16'

@description('Service address range')
param serviceCidr string = '10.1.48.0/20'

@description('DNS service IP within serviceCidr')
param dnsServiceIp string = '10.1.48.10'

@description('System pool VM SKU')
param systemVmSize string = 'Standard_D4s_v5'

@description('User pool VM SKU')
param userVmSize string = 'Standard_D2s_v5'

@description('Only for restricted subscriptions where Microsoft.Authorization role assignment calls are blocked: disables Azure RBAC for Kubernetes and re-enables local accounts so `az aks get-credentials --admin` works. Keep false for normal use.')
param testingMode bool = false

var vnetName = 'vnet-${namePrefix}-${workshopId}'
var subnetName = 'snet-nodes'
var aksName = '${namePrefix}-${workshopId}'
var dnsPrefix = toLower(replace('${namePrefix}${workshopId}', '-', ''))

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: nodeSubnetPrefix
        }
      }
    ]
  }
}

resource aks 'Microsoft.ContainerService/managedClusters@2024-10-01' = {
  name: aksName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: dnsPrefix
    enableRBAC: true
    disableLocalAccounts: !testingMode
    aadProfile: {
      managed: true
      enableAzureRBAC: !testingMode
      tenantID: tenantId
    }
    apiServerAccessProfile: {
      authorizedIPRanges: authorizedIpRanges
    }
    agentPoolProfiles: [
      {
        name: 'system'
        count: 2
        vmSize: systemVmSize
        osType: 'Linux'
        mode: 'System'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: vnet.properties.subnets[0].id
        nodeTaints: [
          'CriticalAddonsOnly=true:NoSchedule'
        ]
      }
      {
        name: 'user'
        count: 1
        vmSize: userVmSize
        osType: 'Linux'
        mode: 'User'
        type: 'VirtualMachineScaleSets'
        vnetSubnetID: vnet.properties.subnets[0].id
      }
    ]
    networkProfile: {
      networkPlugin: 'azure'
      networkPluginMode: 'overlay'
      networkDataplane: 'cilium'
      podCidr: podCidr
      serviceCidr: serviceCidr
      dnsServiceIP: dnsServiceIp
      outboundType: 'loadBalancer'
    }
  }
}

output workshopId string = workshopId
output vnetName string = vnetName
output aksResourceName string = aksName
output aksDnsPrefix string = dnsPrefix
output nodeResourceGroup string = aks.properties.nodeResourceGroup
