function Set-TomatoNat {
    param(
        [parameter(Mandatory)]
        $server,
        [parameter(Mandatory)]
        $credential = (Get-Credential),
        [parameter(ParameterSetName = "Enable",Mandatory)]
        [switch]$enable,
        [parameter(ParameterSetName = "Disable",Mandatory)]
        [switch]$Disable
    )
    # Collect current rules
    $invokation = Invoke-RestMethod "http://$($server)/forward-basic.asp" -Credential $credential -AllowUnencryptedAuthentication
    $multi = [System.Text.RegularExpressions.RegexOptions]::Multiline
    $single = [System.Text.RegularExpressions.RegexOptions]::Singleline
    $Rules = [regex]::Match($invokation, "(?<=nvram = ).*?(?=;)",@($multi,$single)).value | ConvertFrom-Json
    $current_rules = $Rules.portforward.trim(">") -split ">" | foreach-object {
        $rulesp = $_ -split "<"
        [pscustomobject]@{
            "Enabled"           = $rulesp[0]
            "Protocol"          = $rulesp[1]
            "source_address"    = $rulesp[2]
            "External_Port"     = $rulesp[3]
            "Internal_port"     = $rulesp[4]
            "Internal_address"  = $rulesp[5]
            "Comment"           = $rulesp[6]
        }
    }

    # Write-verbose $current_rules

    if ($Disable) {
        Write-Output "disable"
        $state = 0
    }

    if ($enable) {
        write-output "enable"
        $state = 1
    }

    if (!($current_rules | where-object external_port -eq "53")) {
        Write-Verbose "No rule yet. Creating new one."
        $current_rules += [pscustomobject]@{
            "Enabled"           = $state
            "Protocol"          = "3"
            "source_address"    = ""
            "External_Port"     = "53"
            "Internal_port"     = "53"
            "Internal_address"  = ""
            "Comment"           = "ScriptGenerated"
        }
    }

    $current_rules | where-object external_port -eq "53" | foreach-object {$_.enabled = $state}

    # Reconstruct data
    $data = "_nextpage=forward-basic.asp&_service=firewall-restart&portforward=" + (($current_rules| foreach-object {
        $current = $_
        (($current.psobject.Members | where-object MemberType -eq "NoteProperty").name | foreach-object {$current.$_}) -join "<"
    }) -join ">") + ">&_http_id=$($rules.http_id)"


    # Send data to firewall
    $params = @{
        "body"          = $data
        "uri"           = "http://$($server)/tomato.cgi"
        "method"        = "POST"
        "Credential"    = $credential
    }

    Invoke-RestMethod @params -AllowUnencryptedAuthentication| out-null
}
