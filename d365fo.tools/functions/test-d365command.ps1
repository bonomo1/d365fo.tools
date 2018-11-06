﻿<#
    .SYNOPSIS
        Validate or show parameter set details with colored output

    .DESCRIPTION
        Analyze a function and it's parameters

        The cmdlet / function is capable of validating a string input with function name and parameters

    .PARAMETER CommandText
        The string that you want to analyze

        If there is parameter value present, you have to use the opposite quote strategy to encapsulate the string correctly

        E.g. for double quotes
        -CommandText 'Import-D365Bacpac -ImportModeTier2 -SqlUser "sqladmin" -SqlPwd "XyzXyz" -BacpacFile2 "C:\temp\uat.bacpac"'
        
        E.g. for single quotes
        -CommandText "Emport-D365Bacpac -ExportModeTier2 -SqlUser 'sqladmin' -SqlPwd 'XyzXyz' -BacpacFile2 'C:\temp\uat.bacpac'"

    .PARAMETER Mode
        The operation mode of the cmdlet / function

        Valid options are:
        - Validate
        - ShowParameters

    .PARAMETER IncludeHelp
        Switch to instruct the cmdlet / function to output a simple guide with the colors in it

    .EXAMPLE
        PS C:\> Show-PSMDSyntax -CommandText 'Import-D365Bacpac -ImportModeTier2 -SqlUser "sqladmin" -SqlPwd "XyzXyz" -BacpacFile2 "C:\temp\uat.bacpac"' -Mode "Validate"

        This will validate all the parameters that have been passed to the Import-D365Bacpac cmdlet.
        All supplied parameters that matches a parameter will be marked with an asterisk.
        
    .EXAMPLE
        PS C:\> Show-PSMDSyntax -CommandText 'Import-D365Bacpac' -Mode "ShowParameters"

        This will display all the parameter sets and their individual parameters.

    .NOTES
        Author: Mötz Jensen (@Splaxi)
        
#>
function Test-D365Command {
    [CmdletBinding()]
    
    param (
        [Parameter(Mandatory = $true, Position = 1)]
        [string] $CommandText,

        [ValidateSet('Validate', 'ShowParameters')]
        [string] $Mode,

        [switch] $IncludeHelp
    )

    $commonParameters = 'Verbose', 'Debug', 'ErrorAction', 'WarningAction', 'InformationAction', 'ErrorVariable', 'WarningVariable', 'InformationVariable', 'OutVariable', 'OutBuffer', 'PipelineVariable', 'Confirm', 'WhatIf'

    #Match to find the command name: Non-Whitespace until the first whitespace
    $commandMatch = ($CommandText | Select-String '\S+\s*').Matches

    if (-not ($null -eq $commandMatch)) {
        #$commandName = ($CommandText | Select-String '\S+\s{1}').Matches.Value.Trim()
        $commandName = $commandMatch.Value.Trim()

        $res = Get-Command $commandName -ErrorAction Ignore

        if (-not ($null -eq $res)) {

            $null = $sbHelp = New-Object System.Text.StringBuilder
            $null = $sbParmsNotFound = New-Object System.Text.StringBuilder

            switch ($Mode) {
                "Validate" {
                    #Match to find the parameters: Whitespace Dash Non-Whitespace
                    $inputParameterMatch = ($CommandText | Select-String '\s{1}[-]\S+' -AllMatches).Matches
                    
                    if (-not ($null -eq $inputParameterMatch)) {
                        $inputParameterNames = $inputParameterMatch.Value.Trim("-", " ")
                    }
                    else {
                        Write-PSFMessage -Level Host -Message "The function was unable to extract any parameters from the supplied command text. Please try again."
                        Stop-PSFFunction -Message "Stopping because of missing input parameters."
                        return
                    }

                    $availableParameterNames = (Get-Command $commandName).Parameters.keys | Where-Object {$commonParameters -NotContains $_}
                    $inputParameterNotFound = $inputParameterNames | Where-Object {$availableParameterNames -NotContains $_}

                    $null = $sbParmsNotFound.AppendLine("Parameters that <c='em'>don't exists</c>")
                    $inputParameterNotFound | ForEach-Object {
                        $null = $sbParmsNotFound.AppendLine("<c='Red'>$($_)</c>")
                    }

                    (Get-Command $commandName).ParameterSets | ForEach-Object {
                        $null = $sb = New-Object System.Text.StringBuilder
                        
                        $null = $sb.AppendLine("ParameterSet Name: <c='em'>$($_.Name)</c> - Validated List")
                      
        
                        $null = $sb.Append("<c='Green'>$commandName </c>")
                        $parmSetParameters = $_.Parameters | Where-Object name -NotIn $commonParameters
        
                        $parmSetParameters | ForEach-Object {
                            $parmFoundInCommandText = $_.Name -In $inputParameterNames
                            
                            $color = "Darkgray"
        
                            if ($_.IsMandatory -eq $true) { $color = "Yellow" }
        
                            $null = $sb.Append("<c='$color'>-$($_.Name)</c>")
                            
        
                            if ($parmFoundInCommandText) {
                                $color = "Green"
                                $null = $sb.Append("<c='$color'>* </c>")
                            }
                            elseif ($_.IsMandatory -eq $true) {
                                $color = "Magenta"
                                $null = $sb.Append("<c='$color'>* </c>")
                            }
                            else {
                                $null = $sb.Append(" ")
                            }
        
                            if (-not ($_.ParameterType -eq [System.Management.Automation.SwitchParameter])) {
                                $null = $sb.Append("<c='DarkCyan'>PARAMVALUE </c>")
                            }
                        }
        
                        $null = $sb.AppendLine("")
                        Write-PSFMessage -Level Host -Message "$($sb.ToString())"
                    }

                    $null = $sbHelp.AppendLine("")
                    $null = $sbHelp.AppendLine("<c='Red'>Red</c> = Parameter not found")
                    $null = $sbHelp.AppendLine("<c='Green'>Green</c> = Command Name")
                    $null = $sbHelp.AppendLine("<c='Yellow'>Yellow</c> = Mandatory Parameter")
                    $null = $sbHelp.AppendLine("<c='DarkGray'>DarkGray</c> = Optional Parameter")
                    $null = $sbHelp.AppendLine("<c='DarkCyan'>DarkCyan</c> = Parameter value")
                    $null = $sbHelp.AppendLine("<c='Green'>*</c> = Parameter was filled")
                    $null = $sbHelp.AppendLine("<c='Magenta'>*</c> = Mandatory missing")
                }

                "ShowParameters" {
                    (Get-Command $commandName).ParameterSets | ForEach-Object {
                        $null = $sb = New-Object System.Text.StringBuilder
                        
                        $null = $sb.AppendLine("ParameterSet Name: <c='em'>$($_.Name)</c> - Parameter List")
                        
                        $null = $sb.Append("<c='Green'>$commandName </c>")
                        $parmSetParameters = $_.Parameters | Where-Object name -NotIn $commonParameters
        
                        $parmSetParameters | ForEach-Object {
                            $color = "DarkGray"
        
                            if ($_.IsMandatory -eq $true) { $color = "Yellow" }
        
                            $null = $sb.Append("<c='$color'>-$($_.Name) </c>")
        
                            if (-not ($_.ParameterType -eq [System.Management.Automation.SwitchParameter])) {
                                $null = $sb.Append("<c='DarkCyan'>PARAMVALUE </c>")
                            }
                        }
        
                        $null = $sb.AppendLine("")
                        Write-PSFMessage -Level Host -Message "$($sb.ToString())"
                    }

                    $null = $sbHelp.AppendLine("")
                    $null = $sbHelp.AppendLine("<c='Green'>Green</c> = Command Name")
                    $null = $sbHelp.AppendLine("<c='Yellow'>Yellow</c> = Mandatory Parameter")
                    $null = $sbHelp.AppendLine("<c='DarkGray'>DarkGray</c> = Optional Parameter")
                    $null = $sbHelp.AppendLine("<c='DarkCyan'>DarkCyan</c> = Parameter value")
                }
                Default {}
            }

            Write-PSFMessage -Level Host -Message "$($sbParmsNotFound.ToString())"

            if ($IncludeHelp) {
                Write-PSFMessage -Level Host -Message "$($sbHelp.ToString())"
            }
        }
        else {
            Write-PSFMessage -Level Host -Message "The function was unable to get the help of the command. Make sure that the command name is valid and try again."
            Stop-PSFFunction -Message "Stopping because command name didn't return any help."
            return
        }
    }
    else {
        Write-PSFMessage -Level Host -Message "The function was unable to extract a valid command name from the supplied command text. Please try again."
        Stop-PSFFunction -Message "Stopping because of missing command name."
        return
    }
}