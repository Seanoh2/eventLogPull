using namespace System.Collections.Generic

#
# Datto component - Extract event logs and saves them to a CSV
# Variables :
# Event Codes - What codes you will pull (Default: ALL)
# Time - How many days from now will you pull these variables from (Default: 7)
# Catalogue - What log will be pulled from the event log (Default: Application)
# Source - What sources need to be present (Default: None)
# Export - Where to export the finished CSV (Default: C:\Program Data\Centrastage)
# Limit - How many events to grab per log
#
# Author: Sean O'Hora - 07/04/2024
#

# Requires admin may need to be removed/changed
function Test-EventLog {
    Param(
        [Parameter(Mandatory=$true)]
        [string] $Source
    )
    try {
        [System.Diagnostics.EventLog]::SourceExists($Source)
    } catch {
        $false
    }
}

$currentTime = Get-Date -Format "yyyy-MM-dd--HH-mm"

[List[String]]$sources = $env:sources.Split(",")
$sources = $sources | ForEach-Object -MemberName Trim

$eventCodes = $env:eventCodes.Split(",")

[List[String]]$applications = $env:$applications.Split(",")
$applications = $applications | ForEach-Object -MemberName Trim

#
# Validation
#

# Check if all event codes given are valid
foreach ($eventCode in $eventCodes) {
 
    # Check if the given code is valid
    if (($eventCode -match '^\d+$' -and [int]$eventCode -le 65535) -or ($eventCode -eq "*")) {
        #Valid Error Code
    } else {
        throw [System.ArgumentException]"Invalid given event code, Event codes given were not in the correct format or a number dosen't exceeds 65535"
    }
}

# Validate logs
# Pull full list of log views on device:
$LogList = Get-EventLog -List | Select-Object -ExpandProperty Log

# Compare list - Looping on provided list from user and will compare each variable based and check each one
# Will remove any event log not found.
# For loop used to allow for removal of catalogue not available as foreach changes to collection will crash
for($i = 0; $i+1 -le ($applications | Measure-Object).Count; $i++)  {
    if(-not ($LogList.Contains($applications[$i]))) {

        #Application provided by user not found in available log list
        Write-Host "Event log $($applications[$i]) is not present on this device, Excluding."
        $applications.RemoveAt($i)
    }
}

# Validate Time
# Check if number provided
if ($env:$Time -match '^\d+$') {
    Write-Host "Time validated"
} else {
    throw [System.ArgumentException]"Invalid Days, Please ensure that a valid number of days are set."
    exit 1
}


# Validate Limit
# Check if number provided
if ($env:limit -match '^\d+$') {
    Write-Host "Limit validated"
} else {
    throw [System.ArgumentException]"Invalid Limit, Please ensure that a valid limit is set."
    exit 1
}

#Validate export
#Check if valid directory - first check if valid link

if([System.IO.Path]::IsPathRooted($env:directory)) {
    if(Test-Path $env:directory) {
        Write-Host "Directory found & validated"
    } else {
        throw [System.ArgumentException]"Missing directory, Please ensure that this path exists on the device."
    }
} else {
    throw [System.ArgumentException]"Invalid link, Please ensure that a fully-qualified paths is used."
}

# Validate sources
# Requires admin may need to be removed
# Compare list - Looping on provided list from user and will compare each variable based and check each one
# Will remove any event log not found.
# For loop used to allow for removal of sources not available as foreach changes to collection will crash
for($i = 0; $i+1 -le ($sources | Measure-Object).Count; $i++)  {
    if(-not (Test-EventLog $sources[$i])) {
        #Application provided by user not found in available log list
        Write-Host "Event source $($sources[$i]) is not present on this device, Excluding."
        $sources.RemoveAt($i)
    }
}


#
# Execution
# Now all variables have been validated we can go ahead with the execution
# What will be done:
# Loop on each LogNames
# We will save each log as a seperate csv
#

$applications | ForEach-Object {
    $logName = $_
    $events = Get-WinEvent -LogName $logName -MaxEvents $env:limit

    # We will need to check if the array contains a *
    # If the array contains '*',than skip the filter
    if ($eventCodes -notcontains '*') {
        $events = $events | Where-Object { $_.Id -in $eventCodes }
    }

    $events | Select-Object -Property ID,TimeCreated,ProviderName,LevelDisplayName,LogName,Message | 
         Export-Csv -path "$env:directory\$logName-$currentTime.csv" -NoTypeInformation
}

