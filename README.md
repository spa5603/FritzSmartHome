# FritzSmartHome
Development of a PowerShell Module for AVM FritzBox open HTTP API

Version 1.0.2.0
Updates: Renaming of cmdlets and new cmdlet to set the temperature at a specific controller.
Available Cmdlets:
- Get-StringMD5Hash
- Get-FSHSID
- Get-FSHMeasuredTemp
- Get-FSHDevices
- Set-FSHTemperature
Example: Set-FSHTemperature -Ain <Ain of Controller> -SID <Get-FSHSID> -Temperature <8-28; OFF; ON>

Version 1.0.0.2
Available Cmdlets:
- Get-StringMD5Hash
- Get-FritzBoxSID
- Get-HtrMeasuredTemp
- Get-HtrDevices
News:
The Get-HtrDevices Cmdlet returns a pscustomobject with a lot of information about all existing radiator controllers.
- AIN            : 119590144168
- Name           : Keller
- Manufacturer   : AVM
- ProductName    : Comet DECT
- FirmWare       : 03.54
- Active         : True
- Temperature    : 21
- Offset         : 0
- TempDesired    : 20
- TempEco        : 20
- TempComfort    : 20
- DeviceLock     : True
- ReplaceBattery : False

Version 1.0.0.1
Available Cmdlets:
- Get-StringMD5Hash
- Get-FritzBoxSID
- Get-HtrMeasuredTemp
