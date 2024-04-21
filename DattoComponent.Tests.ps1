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
    It "Returns <expected> (<name>)" -ForEach @(
        @{ Name = "msiInstaller"; Expected = $True}
        @{ Name = "Obvious fake"; Expected = $false}
        @{ Name = "123456789"; Expected = $false}
        @{ Name = "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"; Expected = $false}
        @{ Name = "application"; Expected = $false}
        @{ Name = "system"; Expected = $false}
        @{ Name = "🌵"; Expected = $false}
    ) {
        SourceValidation $name | should -be $expected
    }
}
