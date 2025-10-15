$subscriptionId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
$secretName = "env"

Connect-AzAccount
Set-AzContext -SubscriptionId $subscriptionId 

$ressources = Get-AzResource -ResourceType "Microsoft.KeyVault/vaults"
$vaultName = $ressources[0].Name

Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName -AsPlainText | ConvertTo-SecureString -AsPlainText -Force