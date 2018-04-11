function Get-StringMD5Hash {

    Param (
        [Parameter (Mandatory = $true)]
        [string]$string
        )
    
        $MD5 = [System.Security.Cryptography.md5]::Create()
        $InputString = [System.Text.Encoding]::Unicode.GetBytes($string)
        $Hash = $MD5.ComputeHash($InputString)
    
        $StringBuilder = New-Object System.Text.StringBuilder
        for ($i = 0; $i -lt $Hash.Length; $i++)
        {
            $null = $StringBuilder.Append($Hash[$i].ToString("x2"))
        }
        $MD5Hash = $StringBuilder.ToString()

    # Return
    Return $MD5Hash
}

function Get-FSHSID {

    Param (
        [Parameter (Mandatory = $true)][string]$Password,
        [string]$LoginUrl = 'http://fritz.box/login_sid.lua'
        )

        # Get Challenge
        [xml]$ChallengeXML = (Invoke-WebRequest -Uri $LoginUrl).Content
        [string]$Challenge = $ChallengeXML.SessionInfo.Challenge
        [string]$HashString = $Challenge + '-' + $Password
        [string]$Response = $Challenge + '-' + (Get-StringMD5Hash -string $HashString)
        # Get SID

        [xml]$SIDXML = (Invoke-WebRequest -Uri ($LoginUrl + '?response=' + $Response)).Content
        [string]$SID = $SIDXML.SessionInfo.SID
    
    # Return
    Return $SID
}

function Get-FSHMeasuredTemp {

    Param (
        [Parameter (Mandatory = $true)][string]$Ain,
        [Parameter (Mandatory = $true)][string]$SID
        )

        [double]$Temp = (((Invoke-WebRequest -Uri ("http://fritz.box/webservices/homeautoswitch.lua?ain=$Ain&switchcmd=gettemperature&sid=$SID")).Content).ToString()).Insert(2,'.')

        # Return
    Return $Temp
}

function Get-FSHDevices {
    
    Param (
        [Parameter (Mandatory = $true)][string]$SID
        )

       [xml]$RawData = (Invoke-WebRequest -Uri "http://fritz.box/webservices/homeautoswitch.lua?&switchcmd=getdevicelistinfos&sid=$SID").Content

        $Devices = $RawData.devicelist.device

        [array]$PowerOutlet = $null
        [array]$RadiatorControl = $null
        [array]$CustomRadiatorControllerObjects = $null
        [array]$CustomPowerOutletObjects = $null

        # Separation into RadiatorControl and PowerOutlet
        foreach ($Device in $Devices) {
            if ($Device.InnerXML | Select-String -Pattern 'powermeter') 
            {
                [array]$PowerOutlets += $Device
            }
            elseif ($Device.InnerXML | Select-String -Pattern 'hkr')
            {
                [array]$RadiatorController += $Device
            }
            else
            {
                [array]$Misc += $Device
            }
        }

        foreach ($RadiatorControl in $RadiatorController) {

        if (($RadiatorControl.temperature.offset) -ne 0) {[double]$offset = ($RadiatorControl.temperature.offset).Insert(2,'.')}
        else {[double]$offset = ($RadiatorControl.temperature.offset)}

        $CustomRadiatorControllerObject = [PSCustomObject]@{
            'DeviceId(AIN)' =           [string]$RadiatorControl.identifier -replace ' ',''
            'DeviceName' =              [string]$RadiatorControl.name
            'Manufacturer' =            [string]$RadiatorControl.manufacturer
            'ProductName' =             [string]$RadiatorControl.productname
            'DeviceType' =              [string]'Radiator Controller'
            'FirmWare' =                [string]$RadiatorControl.fwversion
            'DECTConnection' =          ([bool]$DeviceLock = ([int]$RadiatorControl.present))
            'Temperature(C)' =          [double]($RadiatorControl.hkr.tist)/2
            'TemperatureOffset(C)' =    $offset
            'TempDesired(C)' =          [double]($RadiatorControl.hkr.tsoll)/2
            'TempEco(C)' =              [double]($RadiatorControl.hkr.absenk)/2
            'TempComfort(C)' =          [double]($RadiatorControl.hkr.komfort)/2
            'DeviceLock' =              ([bool]$DeviceLock = ([int]$RadiatorControl.hkr.devicelock))
            'ReplaceBattery' =          ([bool]$Replacebattery = ([int]$RadiatorControl.hkr.batterylow))
            }

        $CustomRadiatorControllerObject

        }

        foreach ($PowerOutlet in $PowerOutlets) {

        if (($PowerOutlet.temperature.offset) -ne 0) {[doubel]$offset = ($PowerOutlet.temperature.offset).Insert(2,'.')}
        else {[double]$offset = ($PowerOutlet.temperature.offset)}

        $CustomPowerOutletObject = [PSCustomObject]@{
            'DeviceId(AIN)' =           [string]$PowerOutlet.identifier -replace ' ',''
            'DeviceName' =              [string]$PowerOutlet.name
            'Manufacturer' =            [string]$PowerOutlet.manufacturer
            'ProductName' =             [string]$PowerOutlet.productname
            'DeviceType' =              [string]'Power Outlet'
            'FirmWare' =                [string]$PowerOutlet.fwversion
            'DECTConnection' =          ([bool]$Active = ([int]$PowerOutlet.present))
            'DeviceMode' =              [string]$PowerOutlet.switch.mode
            'WorkingState' =            ([bool]$Working = ([int]$PowerOutlet.switch.state))
            'CapacityCurent(W)' =       [double]($PowerOutlet.powermeter.power)/1000
            'Temperature(C)' =          [double]($PowerOutlet.temperature.celsius).Insert(2,'.')
            'TemperatureOffset(C)' =    $offset
            'DeviceLock' =              ([bool]$DeviceLock = ([int]$PowerOutlet.switch.devicelock))
            }

        $CustomPowerOutletObject

        }

}

function Set-FSHTemperature {
    
    Param (
        [Parameter (Mandatory = $true)][string]$Ain,
        [Parameter (Mandatory = $true)][string]$SID,
        [Parameter (Mandatory = $true)][string]$Temperature
        )

    # Check the Value and recalculate
    if ($Temperature -match "\d") {
        [double]$Temperature = $Temperature
        }
    
    switch ($Temperature)
    {
        ('On') {$Temp = '254'}
        ('Off'){$Temp = '253'}
        {$_ -ge 8 -and $_ -le 28} {[string]$Temp = ($Temperature*2)}
        default {Write-Error 'Temperature is out of range. range is 8-28 C.' -Category InvalidArgument -ErrorAction Stop}
    }

(Invoke-WebRequest -Uri ("http://fritz.box/webservices/homeautoswitch.lua?ain=$Ain&switchcmd=sethkrtsoll&sid=$SID") -Body @{param = $Temp}).StatusDescription

}