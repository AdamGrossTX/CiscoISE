    [CmdletBinding()]
    param (
        #[parameter(Mandatory)]
        [string]$TenantId,

        #[parameter(Mandatory)]
        [string]$AppID,

        #[parameter(Mandatory)]
        [string]$AppSecret,

        [string]$DeviceMAC
    )


    ##Get Token for Service Discovery
    $HeaderServiceToken = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }

    $BodyServiceToken = @{
        "grant_type" = "client_credentials"
        "client_secret" = $AppSecret
        "scope" = "https://api.manage.microsoft.com/"
        "client_id" = $AppID
    }

    $UriServiceToken = "https://login.microsoftonline.com/$($TenantID)/oauth2/token"
    $ResultServiceToken = Invoke-RestMethod -Uri $UriServiceToken -Method Post -Headers $HeaderServiceToken -Body $BodyServiceToken
    if($ResultServiceToken) {
        $ServiceToken = $ResultServiceToken.access_token
    }
    else {
        $ResultServiceToken
    }
    ####

    ##Get Discovery Service
    $HeaderService = @{
        "Content-Type" = "application/x-www-form-urlencoded"
        "api-version" = "1.6"
        "client-request-id" = $AppID
        "Authorization" = "Bearer $($ServiceToken)"
    }
    $UriService = "https://graph.windows.net/$($TenantId)/servicePrincipalsByAppId/0000000a-0000-0000-c000-000000000000/serviceEndpoints"
    $ResultService = Invoke-RestMethod -Uri $UriService -Method Get -Headers $HeaderService
    $NACAPIServiceUri = $ResultService.Value | Where-Object {$_.serviceName -eq "NACAPIService"}
    #####

    ##Get Device Token
    $HeaderDeviceToken = @{
        "Content-Type" = "application/x-www-form-urlencoded"
    }

    $BodyDeviceToken = @{
        "grant_type" = "client_credentials"
        "client_secret" = $AppSecret
        "resource" = "https://api.manage.microsoft.com/"
        "client_id" = $AppID
    }

    $UriDeviceToken = "https://login.microsoftonline.com/$($TenantID)/oauth2/token"
    $ResultDeviceToken = Invoke-RestMethod -Uri $UriServiceToken -Method Post -Headers $HeaderDeviceToken -Body $BodyDeviceToken
    if($ResultDeviceToken) {
        $TokenDevice = $ResultDeviceToken.access_token
    }
    else {
        $ResultDeviceToken
    }
    ###

    ##Get Device from NAC by MAC
    $HeaderDevice = @{
        "Authorization" = "Bearer $($TokenDevice)"
    }

    if($DeviceMAC) {
        $DeviceMAC = $DeviceMAC.Replace("-","").Replace(":","")
        $Criteria = "macaddress"
        $UriDevice = "$($NACAPIServiceUri.uri)/devices/?value=$($DeviceMac)&querycriteria=$($Criteria)&paging=0&api-version=1.1"
    }

    if($UriDevice) {
        $ResultDevice = Invoke-RestMethod -Uri $UriDevice -Method Get -Headers $HeaderDevice
        if($ResultDevice) {
            $Device = $ResultDevice
        }
        else {
            $ResultDevice
        }


        $Device
    }


    $UriDevice = "$($NACAPIServiceUri.uri)/ciscodeviceinfo/mdm/api/devices/?paging=0&querycriteria=compliance&value=false&filter=all"
    $ResultCiscoISE = Invoke-RestMethod -Uri $UriDevice -Method Get -Headers $HeaderDevice

    $ResultCiscoISE.ise_api.deviceList.device.attributes