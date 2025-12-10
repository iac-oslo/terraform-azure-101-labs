@export()
func getResourcePrefix(location string) string => '${location}-dnsresolver-labs'

@export()
var hubAddressRange = '10.9.0.0/23'

@export()
var adminUsername = 'iac-admin'

@export()
var adminPassword = 'fooBar123!'

@export()
var dnsServerVNetAddressRange = '10.9.4.0/29'

@export()
var dnsServerIpAddress = '10.9.4.4'

@export()
var firewallPrivateIpAddress = '10.9.0.4'


@export()
var dnsResolverIpAddress = '10.9.0.132'

@export()
var spoke1VNetAddressRange = '10.9.11.0/24'

