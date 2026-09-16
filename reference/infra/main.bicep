@description('Six lowercase alphanumeric characters shared by workshop resources')
@minLength(6)
@maxLength(6)
param workshopId string

@description('Azure region')
param location string = resourceGroup().location

@description('Microsoft Entra tenant ID')
param tenantId string

@description('Trusted AKS API server egress IP ranges')
param authorizedIpRanges array

@description('Address space for the workshop VNet')
param vnetAddressPrefix string = '10.60.0.0/16'

@description('AKS node subnet')
param nodeSubnetPrefix string = '10.60.0.0/24'

@description('Application Gateway for Containers subnet')
param albSubnetPrefix string = '10.60.1.0/24'

@description('PostgreSQL delegated subnet')
param postgresSubnetPrefix string = '10.60.2.0/28'

@description('Overlay pod address range')
param podCidr string = '10.245.0.0/16'

@description('Kubernetes service address range')
param serviceCidr string = '10.1.48.0/20'

@description('DNS service IP within serviceCidr')
param dnsServiceIp string = '10.1.48.10'

@description('System pool VM SKU')
param systemVmSize string = 'Standard_D4s_v5'

@description('User pool VM SKU')
param userVmSize string = 'Standard_D2s_v5'

@description('PostgreSQL compute SKU for the workshop')
param postgresSkuName string = 'Standard_B1ms'

@description('Only for subscriptions that block role assignments')
param testingMode bool = false

var vnetName = 'vnet-aks-lab-${workshopId}'
var aksName = 'aks-lab-${workshopId}'
var nodeResourceGroupName = 'MC_${resourceGroup().name}_${aksName}_${location}'
var postgresName = 'pg-${workshopId}'
var postgresIdentityName = 'id-pg-${workshopId}'
var postgresDatabaseName = 'appdb'

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [vnetAddressPrefix]
    }
    subnets: [
      {
        name: 'snet-nodes'
        properties: {
          addressPrefix: nodeSubnetPrefix
        }
      }
      {
        name: 'snet-alb'
        properties: {
          addressPrefix: albSubnetPrefix
          delegations: [
            {
              name: 'application-gateway-for-containers'
              properties: {
                serviceName: 'Microsoft.ServiceNetworking/trafficControllers'
              }
            }
          ]
        }
      }
      {
        name: 'snet-postgres'
        properties: {
          addressPrefix: postgresSubnetPrefix
          delegations: [
            {
              name: 'postgres-flexible-server'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource postgresPrivateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: 'private.postgres.database.azure.com'
  location: 'global'
}

resource postgresDnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: postgresPrivateDnsZone
  name: 'link-${vnetName}'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnet.id
    }
  }
}

resource postgresIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: postgresIdentityName
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2026-01-02-preview' = {
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
    dnsPrefix: toLower(replace(aksName, '-', ''))
    nodeResourceGroup: nodeResourceGroupName
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
    oidcIssuerProfile: {
      enabled: true
    }
    securityProfile: {
      workloadIdentity: {
        enabled: true
      }
    }
    ingressProfile: {
      gatewayAPI: {
        installation: 'Standard'
      }
      applicationLoadBalancer: {
        enabled: true
      }
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
        nodeTaints: ['CriticalAddonsOnly=true:NoSchedule']
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

resource postgresFederatedCredential 'Microsoft.ManagedIdentity/userAssignedIdentities/federatedIdentityCredentials@2023-01-31' = {
  parent: postgresIdentity
  name: 'aks-postgres-admin'
  properties: {
    audiences: ['api://AzureADTokenExchange']
    issuer: aks.properties.oidcIssuerProfile.issuerURL
    subject: 'system:serviceaccount:lab:postgres-admin'
  }
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: postgresName
  location: location
  sku: {
    name: postgresSkuName
    tier: 'Burstable'
  }
  properties: {
    version: '16'
    authConfig: {
      activeDirectoryAuth: 'Enabled'
      passwordAuth: 'Disabled'
      tenantId: tenantId
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      delegatedSubnetResourceId: vnet.properties.subnets[2].id
      privateDnsZoneArmResourceId: postgresPrivateDnsZone.id
      publicNetworkAccess: 'Disabled'
    }
    storage: {
      storageSizeGB: 32
      autoGrow: 'Enabled'
    }
  }
  dependsOn: [postgresDnsLink]
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgres
  name: postgresDatabaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

module postgresAdministrator 'modules/postgres-administrator.bicep' = {
  name: 'postgres-administrator'
  params: {
    serverName: postgres.name
    objectId: postgresIdentity.properties.principalId
    principalName: postgresIdentity.name
    tenantId: tenantId
  }
}

module albSubnetRole 'modules/alb-subnet-role.bicep' = if (!testingMode) {
  name: 'alb-subnet-role'
  params: {
    identityName: 'applicationloadbalancer-${aks.name}'
    nodeResourceGroupName: nodeResourceGroupName
    vnetName: vnet.name
    subnetName: 'snet-alb'
  }
}

output workshopId string = workshopId
output vnetName string = vnet.name
output aksResourceName string = aks.name
output nodeResourceGroup string = nodeResourceGroupName
output albSubnetId string = vnet.properties.subnets[1].id
output postgresServerName string = postgres.name
output postgresHost string = postgres.properties.fullyQualifiedDomainName
output postgresDatabaseName string = postgresDatabase.name
output postgresIdentityName string = postgresIdentity.name
output postgresIdentityClientId string = postgresIdentity.properties.clientId
