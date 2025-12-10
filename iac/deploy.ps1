$stopwatch = [System.Diagnostics.Stopwatch]::new()
$stopwatch.Start()

$location = 'westeurope'

Write-Host "Deploying workshop lab infra into $location..."
$deploymentName = 'azfw-labs-{0}' -f (-join (Get-Date -Format 'yyyyMMddTHHMMssffffZ')[0..63])
az deployment sub create -l $location --template-file main.bicep -p parLocation=$location -n $deploymentName

$stopwatch.Stop()

Write-Host "Deployment time: " $stopwatch.Elapsed 
