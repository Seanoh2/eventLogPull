BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1','.ps1')
    $Env:directory = "C:\Users\sohora\Videos"
    $Env:eventCode = "*"
    $Env:applications = "Applications, System, Fails"
    $Env:Time = 34
    $Env:limit = 10
    $Env:sources = "MsiInstaller,Outlook ,Obvious fake source"
}

Describe "Event Code Validation" {
    It "Validate codes" {
        $eventCodes = "MsiInstaller"
        Test-EventLog $eventCodes | should -be True
    }
}
