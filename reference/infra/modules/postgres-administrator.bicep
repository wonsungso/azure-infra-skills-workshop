param serverName string
param objectId string
param principalName string
param tenantId string

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' existing = {
  name: serverName
}

resource administrator 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2022-12-01' = {
  parent: postgres
  name: objectId
  properties: {
    principalName: principalName
    principalType: 'ServicePrincipal'
    tenantId: tenantId
  }
}
