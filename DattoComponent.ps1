﻿using namespace System.Collections.Generic

#
# Datto component - Extract event logs and saves them to a CSV
# Variables :
# Event Codes - What codes you will pull (Default: ALL)
# Time - How many days from now will you pull these variables from (Default: 7)
# Catalogue - What log will be pulled from the event log (Default: Application)
# Source - What sources need to be present (Default: None)
# Export - Where to export the finished CSV (Default: C:\Program Data\Centrastage)
#
# Author: Sean O'Hora - 07/04/2024
#

# Test Block - Remove at end
$Array = "30,40,20,50,2000"
$tmpArray = $Array.Split(",")

# Test Block  - Applciation verification
$ArrayApplications = "Application, System, Fails"
[List[String]]$tmpArrayApplcations = $ArrayApplications.Split(",")
$tmpArrayApplcations = $tmpArrayApplcations | ForEach-Object -MemberName Trim

#Test block - Time
$Time = 34

#Test Directory
$Directory = 'C:\Users\Sean\Music'


# First we need to convert the given variables to valid inputs
# $tmpArray = %EventCodes%.Split(",")

#
# Validation
#

#Check if all event codes given are valid
foreach ($eventCode in $tmpArray) {
 
    #Check if the given code is valid
    if ($eventCode -match '^\d+$' -and [int]$eventCode -le 65535) {
        #Valid Error Code
    } else {
        throw [System.ArgumentException]"Invalid directory, Event codes given were not in the correct format or a number dosen't exceeds 65535"
    }
}

#Validate logs
#Pull full list of log views on device:
$LogList = Get-EventLog -List | Select-Object -ExpandProperty Log

#Compare list - Looping on provided list from user and will compare each variable based and check each one
#Will remove any event log not found.
#For loop used to allow for removal of catalogue not available as foreach changes to collection will crash

for($i = 0; $i+1 -le ($tmpArrayApplcations | Measure-Object).Count; $i++)  {
    if(-not ($LogList.Contains($tmpArrayApplcations[$i]))) {
        #Application provided by user not found in available log list
        Write-Host "Event log $($tmpArrayApplcations[$i]) is not present on this device, Skipping."
        $tmpArrayApplcations.RemoveAt($i)
    }
}

#Validate time
#Check if number provided
if ($eventCode -match '^\d+$') {
    Write-Host "Time validated"
} else {
    throw [System.ArgumentException]"Invalid link, Please ensure that a fully-qualified paths is used."
    exit 1
}

#Validate export
#Check if valid directory - first check if valid link

if([System.IO.Path]::IsPathRooted($Directory)) {
    if(Test-Path $Directory) {
        Write-Host "Directory found & validated"
    } else {
        throw [System.ArgumentException]"Missing directory, Please ensure that this path exists on the device."
    }
} else {
    throw [System.ArgumentException]"Invalid link, Please ensure that a fully-qualified paths is used."
}