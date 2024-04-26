﻿<#
 # Copyright 2002 - 2014 Caphyon LTD. All rights reserved.
 #
 # mailto: eng@caphyon.com
 # http://www.caphyon.com
 #
 #>

<# 
 # This script file contains helper functions that generate the XML digest
 # that is udes to create SMS_Application objects for SCCM 2012
 # 
 # VERY IMPORTANT: The script is dependent of the existence of the SCCM Admin Console
 # on the computer were it is ran.
 #
 #>


function Import-SCCMAssemblies($SCCMAdminConsolePath)
{
  $path = "$SCCMAdminConsolePath\Microsoft.ConfigurationManagement.ApplicationManagement.dll"
  if (Test-Path $path) 
  { 
    $t = [System.Reflection.Assembly]::LoadFrom($path)
  }
   
  $path = "$SCCMAdminConsolePath\Microsoft.ConfigurationManagement.ApplicationManagement.AppVInstaller.dll"
  if (Test-Path $path) 
  { 
    $t = [System.Reflection.Assembly]::LoadFrom($path)
  }
   
  $path = "$SCCMAdminConsolePath\Microsoft.ConfigurationManagement.ApplicationManagement.AppV5XInstaller.dll"
  if (Test-Path $path) 
  { 
    $t = [System.Reflection.Assembly]::LoadFrom($path)
  }

  $path = "$SCCMAdminConsolePath\Microsoft.ConfigurationManagement.ZipArchive.dll"
  if (Test-Path $path) 
  { 
    $t = [System.Reflection.Assembly]::LoadFrom($path)
  }

  $path = "$SCCMAdminConsolePath\Microsoft.ConfigurationManagement.ApplicationManagement.MsiInstaller.dll"
  if (Test-Path $path) 
  { 
    $t = [System.Reflection.Assembly]::LoadFrom($path)
  }

  $path = "$SCCMAdminConsolePath\Microsoft.ConfigurationManagement.ApplicationManagement.Win8Installer.dll"
  if (Test-Path $path) 
  { 
    $t = [System.Reflection.Assembly]::LoadFrom($path)
  }
}


function New-SmsApplication
{
  #Named parameters list for the function
  [CmdletBinding()]
  Param
  ( 
    [Parameter(Mandatory=$true)]
    [System.String]$appScopeId,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appTitle,
    
    [System.String]$appDescription,
    
    [System.String]$appVersion,
    
    [System.String]$appPublisher,

    [System.String]$appLanguage
  )

  #Compute Authoring ScopeID. This should be provided by the SMS site
  $scopeid = $appScopeId   
  if ([System.String]::IsNullOrEmpty($scopeid)) 
  {
    $scopeid = "ScopeId_" + [System.Guid]::NewGuid().ToString() 
  }

  #Set the
  [Microsoft.ConfigurationManagement.ApplicationManagement.NamedObject]::DefaultScope = $scopeid

  #Create an unique id for the application and the deployment type
  $newApplicationID    = "Application_" + [System.Guid]::NewGuid().ToString()

  #Create SCCM 2012 object id for application and deployment type
  $newApplicationID = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.ObjectID($scopeid, $newApplicationID)

   #Create all the objects necessary for the creation of the application
  $newApplication = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.Application($newApplicationID)
  $newDisplayInfo = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.AppDisplayInfo

  #Setting Display Info
  $newDisplayInfo.Title       = $appTitle 
  $newDisplayInfo.Language    = $appLanguage 
  $newDisplayInfo.Description = $appDescription
  $newDisplayInfo.Publisher   = $appPublisher 
  $newDisplayInfo.Version     = $appVersion

  #Add display info to application
  $newApplication.DisplayInfo.Add($newDisplayInfo)

  #Setting default Language must be set and display info must exists
  $newApplication.DisplayInfo.DefaultLanguage = $appLanguage 
  $newApplication.Title                       = $appTitle 
  $newApplication.Version                     = 1
  $newApplication.Publisher                   = $appPublisher 
  $newApplication.Description                 = $appDescription
  $newApplication.SoftwareVersion             = $appVersion
  $newApplication.CustomId                    = $appTitle

  return $newApplication
}

<############################################################################>
#Compute Retrieve XML digest for a Appv 4.x package 
function Get-SmsAppV4xApplicationXml
{
  #Named parameters list for the function
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$true)]
    [System.String]$sccmAdminConsolePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$packagePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appScopeId,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appTitle,
    
    [System.String]$appDescription,
    
    [System.String]$appVersion,
    
    [System.String]$appPublisher,

    [System.String]$appLanguage
  )

  #Load the referenced SCCM assemblies
  Import-SCCMAssemblies $sccmAdminConsolePath 
  
  $newApplication = New-SmsApplication $appScopeId $appTitle $appDescription $appVersion $appPublisher $appLanguage

  #Deployment Type AppV
  $newAppV4xContentImporter = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.AppvContentImporter
  $newAppV4xDeploymentType  = $newAppV4xContentImporter.CreateDeploymentType($packagePath)
  $newAppV4xDeploymentType.Installer.Contents[0].OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newAppV4xDeploymentType.Installer.Contents[0].OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newApplication.DeploymentTypes.Add($newAppV4xDeploymentType)


  #Serialize the object to an xml blob
  $newApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToSTring($newApplication, $true)

  return $newApplicationXML
}

<############################################################################>

function Get-SmsAppV5xApplicationXml
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$true)]
    [System.String]$sccmAdminConsolePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$packagePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appScopeId,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appTitle,
    
    [System.String]$appDescription,
    
    [System.String]$appVersion,
    
    [System.String]$appPublisher,

    [System.String]$appLanguage
  )
  
  #Load the referenced SCCM assemblies
  Import-SCCMAssemblies $sccmAdminConsolePath 

  $newApplication = New-SmsApplication $appScopeId $appTitle $appDescription $appVersion $appPublisher $appLanguage

  #Deployment Type AppV
  $newAppV5xContentImporter  = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.Appv5XContentImporter
  $newAppV5xDeploymentType   = $newAppV5xContentImporter.CreateDeploymentType($packagePath)
  $newAppV5xDeploymentType.Installer.Contents[0].OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newAppV5xDeploymentType.Installer.Contents[0].OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newApplication.DeploymentTypes.Add($newAppV5xDeploymentType)



  #Serialize the object to an xml blob
  $newApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToSTring($newApplication, $true)
  
  return $newApplicationXML
 }

<############################################################################>

function Get-SmsMsiApplicationXml
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$true)]
    [System.String]$sccmAdminConsolePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$packagePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appScopeId,
    
    [Parameter(Mandatory=$true)] 
    [System.String]$appTitle,
    
    [System.String]$appDescription,
    
    [System.String]$appVersion,
    
    [System.String]$appPublisher,

    [System.String]$appLanguage
  )
  
  #Load the referenced SCCM assemblies
  Import-SCCMAssemblies $sccmAdminConsolePath 

  $newApplication = New-SmsApplication $appScopeId $appTitle $appDescription $appVersion $appPublisher $appLanguage

  #Deployment Type AppV
  $newMsiContentImporter  = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.MsiContentImporter
  $newMsiDeploymentType   = $newMsiContentImporter.CreateDeploymentType($packagePath)
  $newMsiDeploymentType.Installer.Contents[0].OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newMsiDeploymentType.Installer.Contents[0].OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newApplication.DeploymentTypes.Add($newMsiDeploymentType)

  #Serialize the object to an xml blob
  $newApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToSTring($newApplication, $true)
  
  return $newApplicationXML
 }

 <############################################################################>

function Get-SmsWin8ApplicationXml
{
  [CmdletBinding()]
  Param
  (
    [Parameter(Mandatory=$true)]
    [System.String]$sccmAdminConsolePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$packagePath,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appScopeId,
    
    [Parameter(Mandatory=$true)]
    [System.String]$appTitle,
    
    [System.String]$appDescription,
    
    [System.String]$appVersion,
    
    [System.String]$appPublisher,

    [System.String]$appLanguage
  )
  
  #Load the referenced SCCM assemblies
  Import-SCCMAssemblies $sccmAdminConsolePath 

  $newApplication = New-SmsApplication $appScopeId $appTitle $appDescription $appVersion $appPublisher $appLanguage

  #Deployment Type AppV
  $newWin8ContentImporter  = New-Object Microsoft.ConfigurationManagement.ApplicationManagement.Windows8AppContentImporter
  $newWin8DeploymentType   = $newWin8ContentImporter.CreateDeploymentType($packagePath)
  $newWin8DeploymentType.Installer.Contents[0].OnFastNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newWin8DeploymentType.Installer.Contents[0].OnSlowNetwork = [Microsoft.ConfigurationManagement.ApplicationManagement.ContentHandlingMode]::Download
  $newApplication.DeploymentTypes.Add($newWin8DeploymentType)



  #Serialize the object to an xml blob
  $newApplicationXML = [Microsoft.ConfigurationManagement.ApplicationManagement.Serialization.SccmSerializer]::SerializeToSTring($newApplication, $true)
  
  return $newApplicationXML
 }
# SIG # Begin signature block
# MII6ZwYJKoZIhvcNAQcCoII6WDCCOlQCAQExDzANBglghkgBZQMEAgEFADB5Bgor
# BgEEAYI3AgEEoGswaTA0BgorBgEEAYI3AgEeMCYCAwEAAAQQH8w7YFlLCE63JNLG
# KX7zUQIBAAIBAAIBAAIBAAIBADAxMA0GCWCGSAFlAwQCAQUABCA8QRWnz/jYXtuP
# XWZlbnJ1czDJJkiCtfyhKwb+e9IFm6CCInQwggXMMIIDtKADAgECAhBUmNLR1FsZ
# lUgTecgRwIeZMA0GCSqGSIb3DQEBDAUAMHcxCzAJBgNVBAYTAlVTMR4wHAYDVQQK
# ExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jvc29mdCBJZGVu
# dGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRob3JpdHkgMjAy
# MDAeFw0yMDA0MTYxODM2MTZaFw00NTA0MTYxODQ0NDBaMHcxCzAJBgNVBAYTAlVT
# MR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xSDBGBgNVBAMTP01pY3Jv
# c29mdCBJZGVudGl0eSBWZXJpZmljYXRpb24gUm9vdCBDZXJ0aWZpY2F0ZSBBdXRo
# b3JpdHkgMjAyMDCCAiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALORKgeD
# Bmf9np3gx8C3pOZCBH8Ppttf+9Va10Wg+3cL8IDzpm1aTXlT2KCGhFdFIMeiVPvH
# or+Kx24186IVxC9O40qFlkkN/76Z2BT2vCcH7kKbK/ULkgbk/WkTZaiRcvKYhOuD
# PQ7k13ESSCHLDe32R0m3m/nJxxe2hE//uKya13NnSYXjhr03QNAlhtTetcJtYmrV
# qXi8LW9J+eVsFBT9FMfTZRY33stuvF4pjf1imxUs1gXmuYkyM6Nix9fWUmcIxC70
# ViueC4fM7Ke0pqrrBc0ZV6U6CwQnHJFnni1iLS8evtrAIMsEGcoz+4m+mOJyoHI1
# vnnhnINv5G0Xb5DzPQCGdTiO0OBJmrvb0/gwytVXiGhNctO/bX9x2P29Da6SZEi3
# W295JrXNm5UhhNHvDzI9e1eM80UHTHzgXhgONXaLbZ7LNnSrBfjgc10yVpRnlyUK
# xjU9lJfnwUSLgP3B+PR0GeUw9gb7IVc+BhyLaxWGJ0l7gpPKWeh1R+g/OPTHU3mg
# trTiXFHvvV84wRPmeAyVWi7FQFkozA8kwOy6CXcjmTimthzax7ogttc32H83rwjj
# O3HbbnMbfZlysOSGM1l0tRYAe1BtxoYT2v3EOYI9JACaYNq6lMAFUSw0rFCZE4e7
# swWAsk0wAly4JoNdtGNz764jlU9gKL431VulAgMBAAGjVDBSMA4GA1UdDwEB/wQE
# AwIBhjAPBgNVHRMBAf8EBTADAQH/MB0GA1UdDgQWBBTIftJqhSobyhmYBAcnz1AQ
# T2ioojAQBgkrBgEEAYI3FQEEAwIBADANBgkqhkiG9w0BAQwFAAOCAgEAr2rd5hnn
# LZRDGU7L6VCVZKUDkQKL4jaAOxWiUsIWGbZqWl10QzD0m/9gdAmxIR6QFm3FJI9c
# Zohj9E/MffISTEAQiwGf2qnIrvKVG8+dBetJPnSgaFvlVixlHIJ+U9pW2UYXeZJF
# xBA2CFIpF8svpvJ+1Gkkih6PsHMNzBxKq7Kq7aeRYwFkIqgyuH4yKLNncy2RtNwx
# AQv3Rwqm8ddK7VZgxCwIo3tAsLx0J1KH1r6I3TeKiW5niB31yV2g/rarOoDXGpc8
# FzYiQR6sTdWD5jw4vU8w6VSp07YEwzJ2YbuwGMUrGLPAgNW3lbBeUU0i/OxYqujY
# lLSlLu2S3ucYfCFX3VVj979tzR/SpncocMfiWzpbCNJbTsgAlrPhgzavhgplXHT2
# 6ux6anSg8Evu75SjrFDyh+3XOjCDyft9V77l4/hByuVkrrOj7FjshZrM77nq81YY
# uVxzmq/FdxeDWds3GhhyVKVB0rYjdaNDmuV3fJZ5t0GNv+zcgKCf0Xd1WF81E+Al
# GmcLfc4l+gcK5GEh2NQc5QfGNpn0ltDGFf5Ozdeui53bFv0ExpK91IjmqaOqu/dk
# ODtfzAzQNb50GQOmxapMomE2gj4d8yu8l13bS3g7LfU772Aj6PXsCyM2la+YZr9T
# 03u4aUoqlmZpxJTG9F9urJh4iIAGXKKy7aIwggbOMIIEtqADAgECAhMzAAC4wiCd
# paH8EYwDAAAAALjCMA0GCSqGSIb3DQEBDAUAMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjMxMjE0MDc1MDMyWhcNMjMxMjE3
# MDc1MDMyWjBLMQswCQYDVQQGEwJSTzEQMA4GA1UEBxMHQ3JhaW92YTEUMBIGA1UE
# ChMLQ2FwaHlvbiBTUkwxFDASBgNVBAMTC0NhcGh5b24gU1JMMIIBojANBgkqhkiG
# 9w0BAQEFAAOCAY8AMIIBigKCAYEAlAWbeMMJ+wxRFQ45nca9Y9+IbQB65s/uEbka
# EGkSMt3ONYwXV2BXbriY1kig7U+nLgjYrxZap88ZuyRiZrnne+vNSMepnHfnw2N8
# bRncrhfkqrVxlyHr670hqpdK9lQKFXDFbJxh/LmuQqFg94xQtzGGIUTGIzzIxGOn
# RsLm815nWQw0Zo/SgxliaAjfiVWNEPJKJDkiTpQRLRVikUalsXvUC6s57+BrRQri
# 34fJeeabiQyZpBkeVmPBpY89v0c58FuFADQzh6SapLNMTj6QjtEs2jlCk7DencmF
# R1jjCOAmLzkLgQyia/moayrB7cmlCnJHyOZqpImXoUCZ5rPuMe6OppAyILsnaX5m
# Fd6yCwux56gZo4kP8Zw6RdaBzhltPOj4BoeloS49kiuhnXnivBfo5t+Q1w1h42GS
# 3YMpMBeed1z0QG2uSie9j893gTMkBxi1zYF7sATyu/BLCMLC52zljqv/nb/38e8e
# GX8sYVTXU5RDKk3eRnJ+pn9SBy5dAgMBAAGjggIaMIICFjAMBgNVHRMBAf8EAjAA
# MA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0BgorBgEEAYI3YQEABggrBgEFBQcD
# AwYcKwYBBAGCN2GDoY/BNoG0pZl+goH440yB/YauXTAdBgNVHQ4EFgQUzpgewFZm
# /Fox2ZNb0S0Kyf4ajt4wHwYDVR0jBBgwFoAU6IPEM9fcnwycdpoKptTfh6ZeWO4w
# ZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmllZCUyMENTJTIwQU9DJTIwQ0El
# MjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQGCCsGAQUFBzAChlhodHRwOi8v
# d3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElEJTIw
# VmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDEuY3J0MC0GCCsGAQUFBzABhiFo
# dHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29jc3AwZgYDVR0gBF8wXTBRBgwr
# BgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQu
# Y29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRtMAgGBmeBDAEEATANBgkqhkiG
# 9w0BAQwFAAOCAgEATSrIq1+gHJOktOBIcvZG/myrn9CUXiJLA7/M1i73S7EIdcy/
# DUIJ5S8mC/yWdCMFgtO5cpqCIQz2qgFZApqKCE73SivyWmUlNGWxvnvlk95PzeGG
# pNvCmFOvprS6+6/YJE0tyMB7kcxb+t+/odmzyr36LvVvDMOID/J69QA5OrAsPEOP
# tOf8ZgIDMrv7xuSPDlrk3gP3gnaKUQfiN+A1YRDNuvjwNf968bYcQQyeZh+kyCSc
# 3En1V+aY4Ze2s78eenyk/MWQu9ptdmTxUwJ2ZtdKgVqhGnk4Prug7QeQN3Bg1hbE
# jj2ySmgtIVH+H9JWl1vUWhUrEz/Y1K98LgDry2BYR30zzJyhy28WokSsyTYVR/0D
# /f16RKKzo9Yx+6gZ5dNUOz1w2vxHYVpkpfARpvzJFV5+/5QH4j0bjhNfyl4FhqJ0
# xXGi4sGuWFRF34amngS0PtKYnq4fn2ZmNQBtUraJ3FplLNW8tUhgn3rZx/tsM7Ur
# /Ju61MYy0jy3WauM0b2Dr5RyflWkW2pdxdEyplxBiQivsFvJgHg7Gj1Nh0HCA4Xu
# tX+FNkmPvkEClq/1AGWdKD0hy30YGAo4/4UjZKb4L+9XueIy6RKIsYJ1N9mS2QOi
# kFQmjlwBqnX7+sFA7n1gMjhBgXPc60OqNVeMIoL4JKydPv79mPtrWGIc15kwggbO
# MIIEtqADAgECAhMzAAC4wiCdpaH8EYwDAAAAALjCMA0GCSqGSIb3DQEBDAUAMFox
# CzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzAp
# BgNVBAMTIk1pY3Jvc29mdCBJRCBWZXJpZmllZCBDUyBBT0MgQ0EgMDEwHhcNMjMx
# MjE0MDc1MDMyWhcNMjMxMjE3MDc1MDMyWjBLMQswCQYDVQQGEwJSTzEQMA4GA1UE
# BxMHQ3JhaW92YTEUMBIGA1UEChMLQ2FwaHlvbiBTUkwxFDASBgNVBAMTC0NhcGh5
# b24gU1JMMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAlAWbeMMJ+wxR
# FQ45nca9Y9+IbQB65s/uEbkaEGkSMt3ONYwXV2BXbriY1kig7U+nLgjYrxZap88Z
# uyRiZrnne+vNSMepnHfnw2N8bRncrhfkqrVxlyHr670hqpdK9lQKFXDFbJxh/Lmu
# QqFg94xQtzGGIUTGIzzIxGOnRsLm815nWQw0Zo/SgxliaAjfiVWNEPJKJDkiTpQR
# LRVikUalsXvUC6s57+BrRQri34fJeeabiQyZpBkeVmPBpY89v0c58FuFADQzh6Sa
# pLNMTj6QjtEs2jlCk7DencmFR1jjCOAmLzkLgQyia/moayrB7cmlCnJHyOZqpImX
# oUCZ5rPuMe6OppAyILsnaX5mFd6yCwux56gZo4kP8Zw6RdaBzhltPOj4BoeloS49
# kiuhnXnivBfo5t+Q1w1h42GS3YMpMBeed1z0QG2uSie9j893gTMkBxi1zYF7sATy
# u/BLCMLC52zljqv/nb/38e8eGX8sYVTXU5RDKk3eRnJ+pn9SBy5dAgMBAAGjggIa
# MIICFjAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDA9BgNVHSUENjA0Bgor
# BgEEAYI3YQEABggrBgEFBQcDAwYcKwYBBAGCN2GDoY/BNoG0pZl+goH440yB/Yau
# XTAdBgNVHQ4EFgQUzpgewFZm/Fox2ZNb0S0Kyf4ajt4wHwYDVR0jBBgwFoAU6IPE
# M9fcnwycdpoKptTfh6ZeWO4wZwYDVR0fBGAwXjBcoFqgWIZWaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSUQlMjBWZXJpZmll
# ZCUyMENTJTIwQU9DJTIwQ0ElMjAwMS5jcmwwgaUGCCsGAQUFBwEBBIGYMIGVMGQG
# CCsGAQUFBzAChlhodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRz
# L01pY3Jvc29mdCUyMElEJTIwVmVyaWZpZWQlMjBDUyUyMEFPQyUyMENBJTIwMDEu
# Y3J0MC0GCCsGAQUFBzABhiFodHRwOi8vb25lb2NzcC5taWNyb3NvZnQuY29tL29j
# c3AwZgYDVR0gBF8wXTBRBgwrBgEEAYI3TIN9AQEwQTA/BggrBgEFBQcCARYzaHR0
# cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9Eb2NzL1JlcG9zaXRvcnkuaHRt
# MAgGBmeBDAEEATANBgkqhkiG9w0BAQwFAAOCAgEATSrIq1+gHJOktOBIcvZG/myr
# n9CUXiJLA7/M1i73S7EIdcy/DUIJ5S8mC/yWdCMFgtO5cpqCIQz2qgFZApqKCE73
# SivyWmUlNGWxvnvlk95PzeGGpNvCmFOvprS6+6/YJE0tyMB7kcxb+t+/odmzyr36
# LvVvDMOID/J69QA5OrAsPEOPtOf8ZgIDMrv7xuSPDlrk3gP3gnaKUQfiN+A1YRDN
# uvjwNf968bYcQQyeZh+kyCSc3En1V+aY4Ze2s78eenyk/MWQu9ptdmTxUwJ2ZtdK
# gVqhGnk4Prug7QeQN3Bg1hbEjj2ySmgtIVH+H9JWl1vUWhUrEz/Y1K98LgDry2BY
# R30zzJyhy28WokSsyTYVR/0D/f16RKKzo9Yx+6gZ5dNUOz1w2vxHYVpkpfARpvzJ
# FV5+/5QH4j0bjhNfyl4FhqJ0xXGi4sGuWFRF34amngS0PtKYnq4fn2ZmNQBtUraJ
# 3FplLNW8tUhgn3rZx/tsM7Ur/Ju61MYy0jy3WauM0b2Dr5RyflWkW2pdxdEyplxB
# iQivsFvJgHg7Gj1Nh0HCA4XutX+FNkmPvkEClq/1AGWdKD0hy30YGAo4/4UjZKb4
# L+9XueIy6RKIsYJ1N9mS2QOikFQmjlwBqnX7+sFA7n1gMjhBgXPc60OqNVeMIoL4
# JKydPv79mPtrWGIc15kwggdaMIIFQqADAgECAhMzAAAABzeMW6HZW4zUAAAAAAAH
# MA0GCSqGSIb3DQEBDAUAMGMxCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3Nv
# ZnQgQ29ycG9yYXRpb24xNDAyBgNVBAMTK01pY3Jvc29mdCBJRCBWZXJpZmllZCBD
# b2RlIFNpZ25pbmcgUENBIDIwMjEwHhcNMjEwNDEzMTczMTU0WhcNMjYwNDEzMTcz
# MTU0WjBaMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9zb2Z0IENvcnBvcmF0
# aW9uMSswKQYDVQQDEyJNaWNyb3NvZnQgSUQgVmVyaWZpZWQgQ1MgQU9DIENBIDAx
# MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAt/fAAygHxbo+jxA04hNI
# 8bz+EqbWvSu9dRgAawjCZau1Y54IQal5ArpJWi8cIj0WA+mpwix8iTRguq9JELZv
# TMo2Z1U6AtE1Tn3mvq3mywZ9SexVd+rPOTr+uda6GVgwLA80LhRf82AvrSwxmZpC
# H/laT08dn7+Gt0cXYVNKJORm1hSrAjjDQiZ1Jiq/SqiDoHN6PGmT5hXKs22E79Me
# FWYB4y0UlNqW0Z2LPNua8k0rbERdiNS+nTP/xsESZUnrbmyXZaHvcyEKYK85WBz3
# Sr6Et8Vlbdid/pjBpcHI+HytoaUAGE6rSWqmh7/aEZeDDUkz9uMKOGasIgYnenUk
# 5E0b2U//bQqDv3qdhj9UJYWADNYC/3i3ixcW1VELaU+wTqXTxLAFelCi/lRHSjaW
# ipDeE/TbBb0zTCiLnc9nmOjZPKlutMNho91wxo4itcJoIk2bPot9t+AV+UwNaDRI
# bcEaQaBycl9pcYwWmf0bJ4IFn/CmYMVG1ekCBxByyRNkFkHmuMXLX6PMXcveE46j
# Mr9syC3M8JHRddR4zVjd/FxBnS5HOro3pg6StuEPshrp7I/Kk1cTG8yOWl8aqf6O
# JeAVyG4lyJ9V+ZxClYmaU5yvtKYKk1FLBnEBfDWw+UAzQV0vcLp6AVx2Fc8n0vpo
# yudr3SwZmckJuz7R+S79BzMCAwEAAaOCAg4wggIKMA4GA1UdDwEB/wQEAwIBhjAQ
# BgkrBgEEAYI3FQEEAwIBADAdBgNVHQ4EFgQU6IPEM9fcnwycdpoKptTfh6ZeWO4w
# VAYDVR0gBE0wSzBJBgRVHSAAMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAZBgkrBgEEAYI3
# FAIEDB4KAFMAdQBiAEMAQTASBgNVHRMBAf8ECDAGAQH/AgEAMB8GA1UdIwQYMBaA
# FNlBKbAPD2Ns72nX9c0pnqRIajDmMHAGA1UdHwRpMGcwZaBjoGGGX2h0dHA6Ly93
# d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElEJTIwVmVy
# aWZpZWQlMjBDb2RlJTIwU2lnbmluZyUyMFBDQSUyMDIwMjEuY3JsMIGuBggrBgEF
# BQcBAQSBoTCBnjBtBggrBgEFBQcwAoZhaHR0cDovL3d3dy5taWNyb3NvZnQuY29t
# L3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBJRCUyMFZlcmlmaWVkJTIwQ29kZSUy
# MFNpZ25pbmclMjBQQ0ElMjAyMDIxLmNydDAtBggrBgEFBQcwAYYhaHR0cDovL29u
# ZW9jc3AubWljcm9zb2Z0LmNvbS9vY3NwMA0GCSqGSIb3DQEBDAUAA4ICAQB3/utL
# ItkwLTp4Nfh99vrbpSsL8NwPIj2+TBnZGL3C8etTGYs+HZUxNG+rNeZa+Rzu9oEc
# AZJDiGjEWytzMavD6Bih3nEWFsIW4aGh4gB4n/pRPeeVrK4i1LG7jJ3kPLRhNOHZ
# iLUQtmrF4V6IxtUFjvBnijaZ9oIxsSSQP8iHMjP92pjQrHBFWHGDbkmx+yO6Ian3
# QN3YmbdfewzSvnQmKbkiTibJgcJ1L0TZ7BwmsDvm+0XRsPOfFgnzhLVqZdEyWww1
# 0bflOeBKqkb3SaCNQTz8nshaUZhrxVU5qNgYjaaDQQm+P2SEpBF7RolEC3lllfuL
# 4AOGCtoNdPOWrx9vBZTXAVdTE2r0IDk8+5y1kLGTLKzmNFn6kVCc5BddM7xoDWQ4
# aUoCRXcsBeRhsclk7kVXP+zJGPOXwjUJbnz2Kt9iF/8B6FDO4blGuGrogMpyXkuw
# CC2Z4XcfyMjPDhqZYAPGGTUINMtFbau5RtGG1DOWE9edCahtuPMDgByfPixvhy3s
# n7zUHgIC/YsOTMxVuMQi/bgamemo/VNKZrsZaS0nzmOxKpg9qDefj5fJ9gIHXcp2
# F0OHcVwe3KnEXa8kqzMDfrRl/wwKrNSFn3p7g0b44Ad1ONDmWt61MLQvF54LG62i
# 6ffhTCeoFT9Z9pbUo2gxlyTFg7Bm0fgOlnRfGDCCB54wggWGoAMCAQICEzMAAAAH
# h6M0o3uljhwAAAAAAAcwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0
# IElkZW50aXR5IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0
# eSAyMDIwMB4XDTIxMDQwMTIwMDUyMFoXDTM2MDQwMTIwMTUyMFowYzELMAkGA1UE
# BhMCVVMxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjE0MDIGA1UEAxMr
# TWljcm9zb2Z0IElEIFZlcmlmaWVkIENvZGUgU2lnbmluZyBQQ0EgMjAyMTCCAiIw
# DQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBALLwwK8ZiCji3VR6TElsaQhVCbRS
# /3pK+MHrJSj3Zxd3KU3rlfL3qrZilYKJNqztA9OQacr1AwoNcHbKBLbsQAhBnIB3
# 4zxf52bDpIO3NJlfIaTE/xrweLoQ71lzCHkD7A4As1Bs076Iu+mA6cQzsYYH/Cbl
# 1icwQ6C65rU4V9NQhNUwgrx9rGQ//h890Q8JdjLLw0nV+ayQ2Fbkd242o9kH82RZ
# sH3HEyqjAB5a8+Ae2nPIPc8sZU6ZE7iRrRZywRmrKDp5+TcmJX9MRff241UaOBs4
# NmHOyke8oU1TYrkxh+YeHgfWo5tTgkoSMoayqoDpHOLJs+qG8Tvh8SnifW2Jj3+i
# i11TS8/FGngEaNAWrbyfNrC69oKpRQXY9bGH6jn9NEJv9weFxhTwyvx9OJLXmRGb
# AUXN1U9nf4lXezky6Uh/cgjkVd6CGUAf0K+Jw+GE/5VpIVbcNr9rNE50Sbmy/4RT
# CEGvOq3GhjITbCa4crCzTTHgYYjHs1NbOc6brH+eKpWLtr+bGecy9CrwQyx7S/Bf
# YJ+ozst7+yZtG2wR461uckFu0t+gCwLdN0A6cFtSRtR8bvxVFyWwTtgMMFRuBa3v
# mUOTnfKLsLefRaQcVTgRnzeLzdpt32cdYKp+dhr2ogc+qM6K4CBI5/j4VFyC4QFe
# UP2YAidLtvpXRRo3AgMBAAGjggI1MIICMTAOBgNVHQ8BAf8EBAMCAYYwEAYJKwYB
# BAGCNxUBBAMCAQAwHQYDVR0OBBYEFNlBKbAPD2Ns72nX9c0pnqRIajDmMFQGA1Ud
# IARNMEswSQYEVR0gADBBMD8GCCsGAQUFBwIBFjNodHRwOi8vd3d3Lm1pY3Jvc29m
# dC5jb20vcGtpb3BzL0RvY3MvUmVwb3NpdG9yeS5odG0wGQYJKwYBBAGCNxQCBAwe
# CgBTAHUAYgBDAEEwDwYDVR0TAQH/BAUwAwEB/zAfBgNVHSMEGDAWgBTIftJqhSob
# yhmYBAcnz1AQT2ioojCBhAYDVR0fBH0wezB5oHegdYZzaHR0cDovL3d3dy5taWNy
# b3NvZnQuY29tL3BraW9wcy9jcmwvTWljcm9zb2Z0JTIwSWRlbnRpdHklMjBWZXJp
# ZmljYXRpb24lMjBSb290JTIwQ2VydGlmaWNhdGUlMjBBdXRob3JpdHklMjAyMDIw
# LmNybDCBwwYIKwYBBQUHAQEEgbYwgbMwgYEGCCsGAQUFBzAChnVodHRwOi8vd3d3
# Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NlcnRzL01pY3Jvc29mdCUyMElkZW50aXR5
# JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9yaXR5
# JTIwMjAyMC5jcnQwLQYIKwYBBQUHMAGGIWh0dHA6Ly9vbmVvY3NwLm1pY3Jvc29m
# dC5jb20vb2NzcDANBgkqhkiG9w0BAQwFAAOCAgEAfyUqnv7Uq+rdZgrbVyNMul5s
# kONbhls5fccPlmIbzi+OwVdPQ4H55v7VOInnmezQEeW4LqK0wja+fBznANbXLB0K
# rdMCbHQpbLvG6UA/Xv2pfpVIE1CRFfNF4XKO8XYEa3oW8oVH+KZHgIQRIwAbyFKQ
# 9iyj4aOWeAzwk+f9E5StNp5T8FG7/VEURIVWArbAzPt9ThVN3w1fAZkF7+YU9kbq
# 1bCR2YD+MtunSQ1Rft6XG7b4e0ejRA7mB2IoX5hNh3UEauY0byxNRG+fT2MCEhQl
# 9g2i2fs6VOG19CNep7SquKaBjhWmirYyANb0RJSLWjinMLXNOAga10n8i9jqeprz
# SMU5ODmrMCJE12xS/NWShg/tuLjAsKP6SzYZ+1Ry358ZTFcx0FS/mx2vSoU8s8HR
# vy+rnXqyUJ9HBqS0DErVLjQwK8VtsBdekBmdTbQVoCgPCqr+PDPB3xajYnzevs7e
# idBsM71PINK2BoE2UfMwxCCX3mccFgx6UsQeRSdVVVNSyALQe6PT12418xon2iDG
# E81OGCreLzDcMAZnrUAx4XQLUz6ZTl65yPUiOh3k7Yww94lDf+8oG2oZmDh5O1Qe
# 38E+M3vhKwmzIeoB1dVLlz4i3IpaDcR+iuGjH2TdaC1ZOmBXiCRKJLj4DT2uhJ04
# ji+tHD6n58vhavFIrmcxghdJMIIXRQIBATBxMFoxCzAJBgNVBAYTAlVTMR4wHAYD
# VQQKExVNaWNyb3NvZnQgQ29ycG9yYXRpb24xKzApBgNVBAMTIk1pY3Jvc29mdCBJ
# RCBWZXJpZmllZCBDUyBBT0MgQ0EgMDECEzMAALjCIJ2lofwRjAMAAAAAuMIwDQYJ
# YIZIAWUDBAIBBQCggYYwGQYJKoZIhvcNAQkDMQwGCisGAQQBgjcCAQQwLwYJKoZI
# hvcNAQkEMSIEIPkxCDyLU4gasShJHS9Yf7I6N+0nfeV5eJKTeVFO8IgxMDgGCisG
# AQQBgjcCAQwxKjAooCaAJABBAGQAdgBhAG4AYwBlAGQAIABJAG4AcwB0AGEAbABs
# AGUAcjANBgkqhkiG9w0BAQEFAASCAYAkokYGX6fgrubsLERVqiaZaSWIHnpdS1vq
# n9kUjPQRXo79f0WcAeRl2Pt6ga5SOrw4Rg5BYePBiXoVGqrPrbjJd0P6rIYETtMY
# AhZIE7BrnJiNMjf8H+0BhyrpnOUNoylHv/epDVvD9akUdvSGE1jmZ14lU/C0q9nb
# KAk0QFOuKqz9GMotpYjo9LPOm3afJdIaABO8JxRsv4rDEPnPiuVauzGtU0k988wd
# /5T0hmsf0hINndvwNnmzaJP30RwmMLakruGhTg1zqz/7jh29mXXqA6xuafWrG855
# uYce2579HSxHsyEoNQ5kC4zb2MBlXLBcnTzh5awMK5WRscTjh5Ku5R0ZBlcgZDl6
# 69PN/vxxSVuOyjeGva5JnqBmIZwojXPnjoJ4fVlv0XY1JnpyZ325EoPGjr4Y7A+n
# eEL3V88o6Svg3keWot06Jo4yphN6fo9XDChRujggQR8Hmrj+BPD+gPT0CeHoa/sl
# tNsFAJinPXifU0wG3JHRVHLf3J3HGCWhghSgMIIUnAYKKwYBBAGCNwMDATGCFIww
# ghSIBgkqhkiG9w0BBwKgghR5MIIUdQIBAzEPMA0GCWCGSAFlAwQCAQUAMIIBYQYL
# KoZIhvcNAQkQAQSgggFQBIIBTDCCAUgCAQEGCisGAQQBhFkKAwEwMTANBglghkgB
# ZQMEAgEFAAQgy6VD4thWd4IYdwX547kxfSAq44LVbJrnRH77YmDwgDUCBmVkhxZS
# exgTMjAyMzEyMTQxMzA3MjUuODYyWjAEgAIB9KCB4KSB3TCB2jELMAkGA1UEBhMC
# VVMxEzARBgNVBAgTCldhc2hpbmd0b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFt
# ZXJpY2EgT3BlcmF0aW9uczEmMCQGA1UECxMdVGhhbGVzIFRTUyBFU046RTQ2Mi05
# NkYwLTQ0MkUxNTAzBgNVBAMTLE1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3Rh
# bXBpbmcgQXV0aG9yaXR5oIIPIDCCB4IwggVqoAMCAQICEzMAAAAF5c8P/2YuyYcA
# AAAAAAUwDQYJKoZIhvcNAQEMBQAwdzELMAkGA1UEBhMCVVMxHjAcBgNVBAoTFU1p
# Y3Jvc29mdCBDb3Jwb3JhdGlvbjFIMEYGA1UEAxM/TWljcm9zb2Z0IElkZW50aXR5
# IFZlcmlmaWNhdGlvbiBSb290IENlcnRpZmljYXRlIEF1dGhvcml0eSAyMDIwMB4X
# DTIwMTExOTIwMzIzMVoXDTM1MTExOTIwNDIzMVowYTELMAkGA1UEBhMCVVMxHjAc
# BgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0
# IFB1YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjAwggIiMA0GCSqGSIb3DQEB
# AQUAA4ICDwAwggIKAoICAQCefOdSY/3gxZ8FfWO1BiKjHB7X55cz0RMFvWVGR3eR
# wV1wb3+yq0OXDEqhUhxqoNv6iYWKjkMcLhEFxvJAeNcLAyT+XdM5i2CgGPGcb95W
# JLiw7HzLiBKrxmDj1EQB/mG5eEiRBEp7dDGzxKCnTYocDOcRr9KxqHydajmEkzXH
# OeRGwU+7qt8Md5l4bVZrXAhK+WSk5CihNQsWbzT1nRliVDwunuLkX1hyIWXIArCf
# rKM3+RHh+Sq5RZ8aYyik2r8HxT+l2hmRllBvE2Wok6IEaAJanHr24qoqFM9WLeBU
# Sudz+qL51HwDYyIDPSQ3SeHtKog0ZubDk4hELQSxnfVYXdTGncaBnB60QrEuazvc
# ob9n4yR65pUNBCF5qeA4QwYnilBkfnmeAjRN3LVuLr0g0FXkqfYdUmj1fFFhH8k8
# YBozrEaXnsSL3kdTD01X+4LfIWOuFzTzuoslBrBILfHNj8RfOxPgjuwNvE6YzauX
# i4orp4Sm6tF245DaFOSYbWFK5ZgG6cUY2/bUq3g3bQAqZt65KcaewEJ3ZyNEobv3
# 5Nf6xN6FrA6jF9447+NHvCjeWLCQZ3M8lgeCcnnhTFtyQX3XgCoc6IRXvFOcPVrr
# 3D9RPHCMS6Ckg8wggTrtIVnY8yjbvGOUsAdZbeXUIQAWMs0d3cRDv09SvwVRd61e
# vQIDAQABo4ICGzCCAhcwDgYDVR0PAQH/BAQDAgGGMBAGCSsGAQQBgjcVAQQDAgEA
# MB0GA1UdDgQWBBRraSg6NS9IY0DPe9ivSek+2T3bITBUBgNVHSAETTBLMEkGBFUd
# IAAwQTA/BggrBgEFBQcCARYzaHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9w
# cy9Eb2NzL1JlcG9zaXRvcnkuaHRtMBMGA1UdJQQMMAoGCCsGAQUFBwMIMBkGCSsG
# AQQBgjcUAgQMHgoAUwB1AGIAQwBBMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0jBBgw
# FoAUyH7SaoUqG8oZmAQHJ89QEE9oqKIwgYQGA1UdHwR9MHsweaB3oHWGc2h0dHA6
# Ly93d3cubWljcm9zb2Z0LmNvbS9wa2lvcHMvY3JsL01pY3Jvc29mdCUyMElkZW50
# aXR5JTIwVmVyaWZpY2F0aW9uJTIwUm9vdCUyMENlcnRpZmljYXRlJTIwQXV0aG9y
# aXR5JTIwMjAyMC5jcmwwgZQGCCsGAQUFBwEBBIGHMIGEMIGBBggrBgEFBQcwAoZ1
# aHR0cDovL3d3dy5taWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQl
# MjBJZGVudGl0eSUyMFZlcmlmaWNhdGlvbiUyMFJvb3QlMjBDZXJ0aWZpY2F0ZSUy
# MEF1dGhvcml0eSUyMDIwMjAuY3J0MA0GCSqGSIb3DQEBDAUAA4ICAQBfiHbHfm21
# WhV150x4aPpO4dhEmSUVpbixNDmv6TvuIHv1xIs174bNGO/ilWMm+Jx5boAXrJxa
# gRhHQtiFprSjMktTliL4sKZyt2i+SXncM23gRezzsoOiBhv14YSd1Klnlkzvgs29
# XNjT+c8hIfPRe9rvVCMPiH7zPZcw5nNjthDQ+zD563I1nUJ6y59TbXWsuyUsqw7w
# XZoGzZwijWT5oc6GvD3HDokJY401uhnj3ubBhbkR83RbfMvmzdp3he2bvIUztSOu
# FzRqrLfEvsPkVHYnvH1wtYyrt5vShiKheGpXa2AWpsod4OJyT4/y0dggWi8g/tgb
# hmQlZqDUf3UqUQsZaLdIu/XSjgoZqDjamzCPJtOLi2hBwL+KsCh0Nbwc21f5xvPS
# wym0Ukr4o5sCcMUcSy6TEP7uMV8RX0eH/4JLEpGyae6Ki8JYg5v4fsNGif1OXHJ2
# IWG+7zyjTDfkmQ1snFOTgyEX8qBpefQbF0fx6URrYiarjmBprwP6ZObwtZXJ23jK
# 3Fg/9uqM3j0P01nzVygTppBabzxPAh/hHhhls6kwo3QLJ6No803jUsZcd4JQxiYH
# Hc+Q/wAMcPUnYKv/q2O444LO1+n6j01z5mggCSlRwD9faBIySAcA9S8h22hIAcRQ
# qIGEjolCK9F6nK9ZyX4lhthsGHumaABdWzCCB5YwggV+oAMCAQICEzMAAAArdk/U
# jzT8pc4AAAAAACswDQYJKoZIhvcNAQEMBQAwYTELMAkGA1UEBhMCVVMxHjAcBgNV
# BAoTFU1pY3Jvc29mdCBDb3Jwb3JhdGlvbjEyMDAGA1UEAxMpTWljcm9zb2Z0IFB1
# YmxpYyBSU0EgVGltZXN0YW1waW5nIENBIDIwMjAwHhcNMjMwNTE4MTkzODUwWhcN
# MjQwNTE2MTkzODUwWjCB2jELMAkGA1UEBhMCVVMxEzARBgNVBAgTCldhc2hpbmd0
# b24xEDAOBgNVBAcTB1JlZG1vbmQxHjAcBgNVBAoTFU1pY3Jvc29mdCBDb3Jwb3Jh
# dGlvbjElMCMGA1UECxMcTWljcm9zb2Z0IEFtZXJpY2EgT3BlcmF0aW9uczEmMCQG
# A1UECxMdVGhhbGVzIFRTUyBFU046RTQ2Mi05NkYwLTQ0MkUxNTAzBgNVBAMTLE1p
# Y3Jvc29mdCBQdWJsaWMgUlNBIFRpbWUgU3RhbXBpbmcgQXV0aG9yaXR5MIICIjAN
# BgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxkaI0MUc8TLAlFShDz0ZoGgaI35z
# /Kdy9XQfvwWAizI81yK0NyTYMPxMmxZGXatRYQiq8s2n2trzJZSmgL0Vujp+H87/
# zZbEWtsj7C7YzMBZocm1eusJqZBD0v6x0DJKR3jS5zqU1kGW8r4HmpYOmIg7HoEM
# RmBmmKEJnwN20aZy90YlgdcuSLzdyk5kDqH/GnSN52fvKdHeNxRGwwWBmJqzGd+e
# +YRuvfPy65azexRAm1bPvWy+d7udn0OfuaksgRi1GTeaMpR1I4tZG/PiaGIdtzN/
# 55I71d9CIqpE51+dcGv+6YJ1LaYClXmAX9wMh9Hjivu96EQvtK1EDZ5KAfplYXEg
# 3RhWnn8MATkHNIIjgHWtGp4d1ciHG2z/v13vmPe0s7HkxZIjbsLBISGuqNw3QrDM
# qY+vIpRnQTAKJ/t0zwtYYqxsKMkFqcREOQ1aLrq0j7fSAsTRLOxsI09COO/IqiD2
# GrSEkzbGJTiyBnSkpOviMWiOL7qYjbQ61lDXT0AKrEJBb6lDUaG3Uw6Ix+fy0VrJ
# pCBf+iNOBJVCwODUppp3OLE3QQFMxLX3rb06T6qmSH2gUePu4L1MeTwDZ9QtsdKg
# vl/cAIOvETzJI9sdaO6YwSe77KNe/WOANk+Fzh2RS5MS1nl5Upo2Vy3/vqrEFwCh
# qvNaEbp+Q55khzMCAwEAAaOCAcswggHHMB0GA1UdDgQWBBQR3+Wuxw6jSmPjRJ0D
# Hm3lopZo2zAfBgNVHSMEGDAWgBRraSg6NS9IY0DPe9ivSek+2T3bITBsBgNVHR8E
# ZTBjMGGgX6BdhltodHRwOi8vd3d3Lm1pY3Jvc29mdC5jb20vcGtpb3BzL2NybC9N
# aWNyb3NvZnQlMjBQdWJsaWMlMjBSU0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIw
# MjAuY3JsMHkGCCsGAQUFBwEBBG0wazBpBggrBgEFBQcwAoZdaHR0cDovL3d3dy5t
# aWNyb3NvZnQuY29tL3BraW9wcy9jZXJ0cy9NaWNyb3NvZnQlMjBQdWJsaWMlMjBS
# U0ElMjBUaW1lc3RhbXBpbmclMjBDQSUyMDIwMjAuY3J0MAwGA1UdEwEB/wQCMAAw
# FgYDVR0lAQH/BAwwCgYIKwYBBQUHAwgwDgYDVR0PAQH/BAQDAgeAMGYGA1UdIARf
# MF0wUQYMKwYBBAGCN0yDfQEBMEEwPwYIKwYBBQUHAgEWM2h0dHA6Ly93d3cubWlj
# cm9zb2Z0LmNvbS9wa2lvcHMvRG9jcy9SZXBvc2l0b3J5Lmh0bTAIBgZngQwBBAIw
# DQYJKoZIhvcNAQEMBQADggIBAG89FRpqEUfymTQWo2jOAi8i5YhShkIP4t65emi8
# oyGr3lUhP7O+I/YEk84ruahwZjwkVz9l06k2On8QEXFb6tTkxZxW7bvyZ3kPX8iE
# V0bzloIwNIHKX/IcKc1bkL/Vy2cMxSfveSE2FDJ3/OC/qh2mJhNuZx+Ta6w3LpLD
# gBQ6Oejli9uzj4yX9EtPnFjqToq0NxLO+djnJ1twoAHP4JipDLbRD/vldoAq1Xub
# 84qmzFGQ3spC+9pb5uwpnpgPq64NzpulnvF+i1rTX2xvRlVFPHrk8nNhq8r6Tc+m
# Trf7Mne4XhpQS3oSYm6uuIv8ePCJRiQDgfHEHfHEiBp4SSCDU5tjXzrGxAu1mbFm
# F0BvWqbsFs4v9d1P8k7BKsu47DEVIoIwJqdar46SpxUwyzBNJzVwIMSv5QMwm0xZ
# m7ZUwTDoU18OOSQfHSa8x5HDhMqJZELTBvNrrsJvf9HbIVahntNdZhDDPtwV3Coc
# R6NSVjG6bLAZTaMhYnkAGwvFJ6vkyMIK5k0xLp6v4N3gg4ZmzdrELS+M/zgbi1xu
# z9pUOwSc6GNk8xlUMZ8FrGtOWaeII9RmH4kXR32sOLBeNPWTt6OplwNsIK0R3jf2
# U2/rCewzia8Z45MI9/yuRUAyNnohIOyJo8ltG4BLftqQgMtNUKz4zkhOUKc7m80g
# djAeMYID1DCCA9ACAQEweDBhMQswCQYDVQQGEwJVUzEeMBwGA1UEChMVTWljcm9z
# b2Z0IENvcnBvcmF0aW9uMTIwMAYDVQQDEylNaWNyb3NvZnQgUHVibGljIFJTQSBU
# aW1lc3RhbXBpbmcgQ0EgMjAyMAITMwAAACt2T9SPNPylzgAAAAAAKzANBglghkgB
# ZQMEAgEFAKCCAS0wGgYJKoZIhvcNAQkDMQ0GCyqGSIb3DQEJEAEEMC8GCSqGSIb3
# DQEJBDEiBCBDiGox7lfW8ofRDeNbwswU34ccrJPrGx+dSNfhFvlylTCB3QYLKoZI
# hvcNAQkQAi8xgc0wgcowgccwgaAEIPu01crwa/trCJKZTbeuYiGkkchuxJRAgxSF
# aJn+EwA+MHwwZaRjMGExCzAJBgNVBAYTAlVTMR4wHAYDVQQKExVNaWNyb3NvZnQg
# Q29ycG9yYXRpb24xMjAwBgNVBAMTKU1pY3Jvc29mdCBQdWJsaWMgUlNBIFRpbWVz
# dGFtcGluZyBDQSAyMDIwAhMzAAAAK3ZP1I80/KXOAAAAAAArMCIEIGhONzvo5oX1
# dyqaUOoTC9DsidFKdCE8UTVdJ7aZ01PYMA0GCSqGSIb3DQEBCwUABIICAFDyOz4V
# orVi+pxv5+gu0Q9ydK1ZcQGyGNxWiqf7lb8efcXHdIcAt+RwXfUkoAESXzwvdXMr
# un+uIXLIGm63m5dxAj495x5aOvRWdUIvPGKVrR1rISkm2uq2mjmYEnvLUK87USVh
# OYMXXWDJeuIW4d/38YsGKZprRP8p4Jmvj+lp7TRyOED2MHk2P0OeuKKX0F1/pkCg
# tCMZhO6xN9wbjlp0sB06PPKZm/pbQt9xHiwzVOtJtRsnbOKt3G5QQDv3Etij3n47
# lqNS5vpKBIabd/Dk9Nzi2CMViNKgYtmKo3dVMBRLtCs/sOrKcqenAKw40MgG0ZHL
# uLr4kjozQsbw7MfwDB+YDCFJ2hqMVllI5C8Ootji/ZHw4gzJvzft9WNjW3hNtrj0
# /YlB5SAOay+cw2bz4TPTh9rdm1pMXmpAWdrNZAEPjxtJENrOJveqjg7n8VtwFjMP
# RAy7siGf4e2I2+62uBsO6mfmzXKfaLAxkKm2SxIeIRgQNQHRA5SRYRJUDJ7hMmHf
# FgBTEYhjAQxW5PUqup8C3pt57vKAeSan1jCVagHFdAfjDoac7Lg0YVa22xZRDLt3
# NjzWyzla/ZYzPqVEdhbC3/MxOvCuOpCfe2I5CAzJQxmsab2YsnrQ4m/ia36Ttq4t
# xEL2UNs2lA7fJNkiQLsgLHpjCd9oSny1iem4
# SIG # End signature block
