param (
    [string] $customLocationResourceId,
    [string] $kubernetesVersion = "",
    [string] $osSku
)

$ErrorActionPreference = "Stop"

while ($true) {
    if ($env:ACTIONS_ID_TOKEN_REQUEST_TOKEN) {
        $resp = Invoke-WebRequest -Uri "$env:ACTIONS_ID_TOKEN_REQUEST_URL&audience=api://AzureADTokenExchange" -Headers @{"Authorization" = "bearer $env:ACTIONS_ID_TOKEN_REQUEST_TOKEN"}
        $token = (echo $resp.Content | ConvertFrom-Json).value
    
        az login --federated-token $token --tenant $env:ARM_TENANT_ID -u $env:ARM_CLIENT_ID --service-principal
        az account set --subscription $env:ARM_SUBSCRIPTION_ID
    }
    
    # GET first, only PUT if 404
    $accessToken = $(az account get-access-token --query accessToken -o tsv)
    $url = "https://management.azure.com${customLocationResourceId}/providers/Microsoft.HybridContainerService/kubernetesVersions/default?api-version=2024-01-01"
    
    Write-Host "Checking if kubernetesVersions resource already exists..."
    $state = $null
    $needsPut = $false
    
    $ErrorActionPreference = "Continue"
    $getResponse = az rest --headers "Authorization=Bearer $accessToken" "Content-Type=application/json;charset=utf-8" --uri $url --method GET 2>&1
    $ErrorActionPreference = "Stop"
    
    # Check if response contains error code
    if ($LASTEXITCODE -ne 0) {
        $errorString = $getResponse | Out-String
        if ($errorString -match '\{"error":\{[^}]+\}\}') {
            try {
                $errorJson = $matches[0] | ConvertFrom-Json
                if ($errorJson.error.code -eq 'ResourceNotFound') {
                    Write-Host "Resource not found, will create with PUT"
                    $needsPut = $true
                } else {
                    Write-Error "GET request failed with error code: $($errorJson.error.code)"
                    Write-Error "Error message: $($errorJson.error.message)"
                    throw "Failed to get kubernetesVersions resource"
                }
            } catch {
                Write-Error "Failed to parse error response: $errorString"
                throw "Failed to get kubernetesVersions resource"
            }
        } else {
            Write-Error "GET request failed with unexpected error: $errorString"
            throw "Failed to get kubernetesVersions resource"
        }
    } else {
        $state = $getResponse | Out-String
        
        if ($state -and $state.Contains('"properties"')) {
            $stateJson = $state | ConvertFrom-Json
            $provisioningState = $stateJson.properties.provisioningState
            
            Write-Host "Resource exists with provisioningState: $provisioningState"
            
            if ($provisioningState -eq "Succeeded") {
                Write-Host "Resource already in Succeeded state, skipping PUT"
            } else {
                throw "KubernetesVersions resource is not in Succeeded state"
            }
        } else {
            Write-Errpr "GET succeeded but response is invalid (no properties). Response: $state"
            throw "Invalid kubernetesVersions response"
        }
    }
    
    # Only PUT if we got 404
    if ($needsPut) {
        Write-Host "Creating kubernetesVersions resource..."
        $requestBody = "{'extendedLocation':{'type':'CustomLocation','name':'$customLocationResourceId'}}"
        az rest --headers "Authorization=Bearer $accessToken" "Content-Type=application/json;charset=utf-8" `
          --uri $url `
          --method PUT `
          --body $requestBody
        
        if ($LASTEXITCODE -ne 0) {
            Write-Error "PUT request failed"
            throw "Failed to create kubernetesVersions resource"
        }
      
        # Wait for the resource to be fully provisioned after PUT
        Write-Host "Waiting for kubernetesVersions resource to be available..."
        $maxRetries = 30  # 10 minutes total (30 * 20 seconds)
        $retryCount = 0
        $state = $null
        
        while ($retryCount -lt $maxRetries) {
            Start-Sleep -Seconds 20
            $retryCount++
            
            Write-Host "Attempt $retryCount/$maxRetries, getting versions..."
            $ErrorActionPreference = "Continue"
            $getResponse = az rest --headers "Authorization=Bearer $accessToken" "Content-Type=application/json;charset=utf-8" --uri $url --method GET 2>&1
            $ErrorActionPreference = "Stop"
            
            if ($LASTEXITCODE -eq 0) {
                $state = $getResponse | Out-String
                
                if ($state -and $state.Contains('"properties"')) {
                    $stateJson = $state | ConvertFrom-Json
                    $provisioningState = $stateJson.properties.provisioningState
                    
                    Write-Host "Resource provisioning state: $provisioningState"
                    
                    if ($provisioningState -eq "Succeeded") {
                        Write-Host "Resource is now fully provisioned"
                        break
                    } else {
                        Write-Host "Resource exists but not yet Succeeded (current state: $provisioningState), retrying..."
                    }
                }
            } else {
                $errorString = $getResponse | Out-String
                if ($errorString -match '\{"error":\{[^}]+\}\}') {
                    try {
                        $errorJson = $matches[0] | ConvertFrom-Json
                        if ($errorJson.error.code -eq 'ResourceNotFound') {
                            Write-Host "Resource not yet available, retrying..."
                        } else {
                            Write-Warning "Unexpected error during retry (error.code=$($errorJson.error.code)): $($errorJson.error.message)"
                        }
                    } catch {
                        Write-Warning "Failed to parse error response during retry: $errorString"
                    }
                } else {
                    Write-Warning "Unexpected error during retry: $errorString"
                }
            }
        }
        
        if (-not $state -or $state.Length -eq 0 -or -not $state.Contains('"properties"')) {
            Write-Error "Failed to get kubernetesVersions after $maxRetries attempts"
            throw "Timeout waiting for kubernetesVersions resource"
        }
    }
    
    # Parse the response
    $state = "$state".Replace("`n", "").Replace("`r", "").Replace("`t", "").Replace(" ", "")
    Write-Host "Received response: $state"
    
    $ready = $false

    # Default to the latest version
    if ($kubernetesVersion -eq "[PLACEHOLDER]")
    {
        $json = $state | ConvertFrom-Json
        $latestPatchVersion = $json.properties.values |
        ForEach-Object {
            $_.patchVersions.PSObject.Properties |
                ForEach-Object {
                [PSCustomObject]@{
                    Version = [version]$_.Name
                    Patch   = $_.Name
                }
            }
        }  |   Sort-Object Version -Descending | Select-Object -First 1

        Write-Verbose "Using kubernetes version = $($latestPatchVersion.Patch)" -Verbose
        $kubernetesVersion = $latestPatchVersion.Patch
    }

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
