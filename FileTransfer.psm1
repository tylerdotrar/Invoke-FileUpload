<#
----------------------------------
AUTHOR:  Tyler McCann (@tyler.rar)
----------------------------------

This module has been added to expedite the process of loading scripts into PowerShell sessions via the user's
$PROFILE, as well as alleviate the process of having to find and update hardcoded scripts inside of the $PROFILE;
whereas once that file becomes a few thousand (or even a few hundred) lines long, the process of updating
quickly becomes tedious.


The below syntax will recursively find all PowerShell script module files within the specified directory and
load them into your terminal; just set $GitDirectory to the desired folder. Rather than setting that variable to
the main repo folder, set it to the folder containing all of your repos so you only have to put the below code
into your $PROFILE a single time.


$PROFILE SYNTAX:
-------------------------------------------------------------------------------------------------------------------
$GitDirectory = 'C:\Users\Bobby\Documents\GitHub'
(Get-ChildItem -Path $GitDirectory -Include *.psm1 -Recurse).Fullname | % { Import-Module $_ -DisableNameChecking }
-------------------------------------------------------------------------------------------------------------------
#>


. $PSScriptRoot\Invoke-FileUpload.ps1
. $PSScriptRoot\Invoke-UploadServer.ps1