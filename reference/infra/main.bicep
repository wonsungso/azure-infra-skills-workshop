@description('AKS cluster base name; a unique suffix is appended automatically to avoid name/DNS collisions across teams and regions')
param aksName string

@description('Azure region')
param location string = resourceGroup().location

@description('DNS prefix base; a unique suffix is appended automatically because this must be unique within the region')
param dnsPrefix string

@description('Existing delegated node subnet resource ID')
param nodeSubnetResourceId string

@description('Microsoft Entra tenant ID')
param tenantId string

@description('Trusted API server egress IP ranges')
param authorizedIpRanges array

@description('Overlay pod address range')
param podCidr string

@description('Service address range')
param serviceCidr string

@description('DNS service IP within serviceCidr')
param dnsServiceIp string

@description('Rehearsed system pool VM SKU')
param systemVmSize string

@description('Rehearsed user pool VM SKU')
param userVmSize string

@description('Only for restricted test subscriptions where Microsoft.Authorization role assignment calls are blocked: disables Azure RBAC for Kubernetes and re-enables local accounts so `az aks get-credentials --admin` works without a role assignment. Must stay false for actual workshop delivery.')
param testingMode bool = false

@description('Deterministic per-resource-group suffix appended to name-collision-prone resources')
var uniqueSuffix = uniqueString(resourceGroup().id, aksName)

var resourceName = '${aksName}-${uniqueSuffix}'
var resolvedDnsPrefix = toLower('${dnsPrefix}${uniqueSuffix}')

resource aks 'Microsoft.ContainerService/managedClusters@2024-10-01' = {
  name: resourceName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'Base'
    tier: 'Free'
  }
  properties: {
    dnsPrefix: resolvedDnsPrefix
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
        vnetSubnetID: nodeSubnetResourceId
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
        vnetSubnetID: nodeSubnetResourceId
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


output aksId string = aks.id
output aksResourceName string = resourceName
output aksDnsPrefix string = resolvedDnsPrefix
output uniqueSuffix string = uniqueSuffix

