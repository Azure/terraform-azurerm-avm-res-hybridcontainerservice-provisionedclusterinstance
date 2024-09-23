param (
    [string] $customLocationResourceId,
    [string] $kubernetesVersion,
    [string] $osSku
)

$ErrorActionPreference = "Stop"

az extension add --name aksarc --yes

while ($true) {
    if ($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN) {
        $resp = Invoke-WebRequest -Uri "$env:ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" -Headers @{"Authorization" = "bearer $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN"}
        $token = (echo $resp.Content | ConvertFrom-Json).value
    
        az login --federated-token $token --tenant $env:ARM_TENANT_ID -u $env:ARM_CLIENT_ID --service-principal
        az account set --subscription $env:ARM_SUBSCRIPTION_ID
    }
    # delete the default version to avoid unsynchronized state between ARM and on-prem
    $token = $(az account get-access-token --query accessToken)
    $url = "https://management.azure.com${customLocationResourceId}/providers/Microsoft.HybridContainerService/kubernetesVersions/default?api-version=2024-01-01"
    echo "Deleting default version to keep sync: $url"
    az rest --headers "Authorization=Bearer $token" "Content-Type=application/json;charset=utf-8" --uri $url --method DELETE
    sleep 5
    echo "Getting versions"
    $state = az aksarc get-versions --custom-location $customLocationResourceId -o json --only-show-errors
    $state = "$state".Replace("`n", "").Replace("`r", "").Replace("`t", "").Replace(" ", "")
    echo $state

    $pos = $state.IndexOf("{")
    $state = $state.Substring($pos)
    $quotePos = $state.IndexOf('"')

    # Workaround for warning messages in the CLI
    if ($quotePos -gt 1) {
        echo "workaround for warning messages in the CLI"
        $state = $state.Substring($quotePos)
        $state = "{$state"
    }
    $ready = $false

    foreach ($version in (echo $state  | ConvertFrom-Json).properties.values) {
        if (!$kubernetesVersion.StartsWith($version.version)) {
            continue
        }

        if ($version.patchVersions.PSobject.Properties.name -notcontains $kubernetesVersion) {
            break
        }

        foreach ($readiness in $version.patchVersions.$kubernetesVersion.readiness) {
            if ($readiness.osSku -eq $osSku) {
                $ready = $readiness.ready
            }
        }
    }

    if ($ready) {
        echo "Kubernetes version $kubernetesVersion is ready for osSku $osSku."
        break
    }

    echo "Kubernetes version $kubernetesVersion is not ready yet for osSku $osSku. Retrying in 10 seconds."
    sleep 10
}
