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

function Get-FritzBoxSID {

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

function Get-HtrMeasuredTemp {

    Param (
        [Parameter (Mandatory = $true)][string]$Ain,
        [Parameter (Mandatory = $true)][string]$SID
        )

        [double]$Temp = (((Invoke-WebRequest -Uri ("http://fritz.box/webservices/homeautoswitch.lua?ain=$Ain&switchcmd=gettemperature&sid=$SID")).Content).ToString()).Insert(2,'.')

        # Return
    Return $Temp
}

function Get-HtrDevices {
    
    Param (
        [Parameter (Mandatory = $true)][string]$SID
        )

        [xml]$RawData = (Invoke-WebRequest -Uri "http://fritz.box/webservices/homeautoswitch.lua?&switchcmd=getdevicelistinfos&sid=$SID").Content

        $Devices = $RawData.devicelist.device

        $CustomObjects = $null

        foreach ($Device in $Devices) {

        $CustomObject = [PSCustomObject]@{
            AIN =            [string]$Device.identifier -replace ' ',''
            Name =           [string]$Device.name
            Manufacturer =   [string]$Device.manufacturer
            ProductName =    [string]$Device.productname
            FirmWare =       [string]$Device.fwversion
            Active =         ([bool]$DeviceLock = ([int]$Device.present))
            Temperature =    [double]($Device.hkr.tist)/2
            Offset =         [double]$Device.temperature.offset
            TempDesired =    [double]($Device.hkr.tsoll)/2
            TempEco =        [double]($Device.hkr.absenk)/2
            TempComfort =    [double]($Device.hkr.komfort)/2
            DeviceLock =     ([bool]$DeviceLock = ([int]$Device.hkr.devicelock))
            ReplaceBattery = ([bool]$Replacebattery = ([int]$Device.hkr.batterylow))
            }

        [array]$CustomObjects += $CustomObject

        }

    Return $CustomObjects
}