# Set TLS to accept TLS, TLS 1.1 and TLS 1.2
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls -bor [Net.SecurityProtocolType]::Tls11 -bor [Net.SecurityProtocolType]::Tls12

try {
    $groupId = $datasource.selectedGroup.Id

    Write-Information "Generating Microsoft Graph API Access Token.."

    $baseUri = "https://login.microsoftonline.com/"
    $authUri = $baseUri + "$AADTenantID/oauth2/token"

    $body = @{
        grant_type    = "client_credentials"
        client_id     = "$AADAppId"
        client_secret = "$AADAppSecret"
        resource      = "https://graph.microsoft.com"
    }
 
    $Response = Invoke-RestMethod -Method POST -Uri $authUri -Body $body -ContentType 'application/x-www-form-urlencoded'
    $accessToken = $Response.access_token;

    Write-Information "Searching for AzureAD group [$groupId]"

    #Add the authorization header to the request
    $authorization = @{
        Authorization  = "Bearer $accesstoken";
        'Content-Type' = "application/json";
        Accept         = "application/json";
    }

    $properties = @("displayName", "description", "mailEnabled", "mail", "securityEnabled")
 
    $baseSearchUri = "https://graph.microsoft.com/"
    $searchUri = $baseSearchUri + "v1.0/groups/$groupId" + '?$select=' + ($properties -join ",")
    $azureADGroup = Invoke-RestMethod -Uri $searchUri -Method Get -Headers $authorization -Verbose:$false
    Write-Information "Finished searching AzureAD group [$groupId]"
      
    foreach ($tmp in $azureADGroup.psObject.properties) {
        if ($tmp.Name -in $properties) {
            $returnObject = @{
                name  = $tmp.Name
                value = $tmp.value
            }
            Write-Output $returnObject
        }
    }
}
catch {
    Write-Error "Error getting AzureAD group [$groupId]. Error: $($_.Exception.Message)"
}