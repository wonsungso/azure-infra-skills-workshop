param identityName string
param nodeResourceGroupName string
param vnetName string
param subnetName string

resource albIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  scope: resourceGroup(nodeResourceGroupName)
  name: identityName
}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  parent: vnet
  name: subnetName
}

resource networkContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(subnet.id, identityName, 'Network Contributor')
  scope: subnet
  properties: {
    principalId: albIdentity.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4d97b98b-1d4f-4787-a291-c67834d212e7')
  }
}
