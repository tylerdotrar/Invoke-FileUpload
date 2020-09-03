function Invoke-UploadServer {
#.SYNOPSIS
# Python x PowerShell server automation script.
# ARBITRARY VERSION NUMBER:  1.2.1
# AUTHOR:  Tyler McCann (@tyler.rar)
#
#.DESCRIPTION
# This script is designed to automate server usage; instead of having to navigate to the working
# working directory of 'upload_server.py,' you can paste this script into your $PROFILE to be able
# to start and stop the server on the fly from directory.  It creates an entirely new window for
# the server, allowing you to continue usage of your current terminal; not making your sacrifice
# your terminal to run the server.
#
# This script has Windows Terminal support; meaning it detects if the terminal you are using is 
# inside of Windows Terminal, and creates an array of open Windows Terminal sessions to determine
# which one you are using.  If you are using Windows Terminal, a new tab will be opened and run the
# server.  Note: this functionality only works if PowerShell is your default profile.
#
# On top of Windows Terminal support, it also works on both desktop PowerShell and PowerShell Core.
# If not using Windows Terminal, the new terminal running server will be running the same version 
# of PowerShell as this script.
#
# Recommendations:
#    -- Place script contents inside user $PROFILE instead of calling 'Invoke-UploadServer.ps1' script
#    -- Replace the default $Server value (<absolutepath>) to the absolute path of 'upload_server.py'
#
# Parameters:
#    -Start     -->  Start the upload server (ONLY works if NO other Python3.8 instance is open)
#    -Stop      -->  Stop the upload server (unreliable if more than one Python3.8 instance is open)
#    -Focus     -->  Give new server window focus (instead of returning focus to current terminal)
#    -Help      -->  Return Get-Help information
#
#    (Server Configuration)
#    -Server    -->  Absolute path to 'upload_server.py'
#    -SSL       -->  Use HTTPS
#    -IP        -->  Change IP address (NOT recommended; only change to 127.0.0.1)
#    -Port      -->  Change port (default is 54321)
#    -Debug     -->  Enable debugger
#    
# Example Usage:
#    []  PS C:\Users\Bobby> Invoke-UploadServer
#        No action specified.
#
#    []  PS C:\Users\Bobby> server -SSL -Port 4444 -Start
#        Server started.
#
#.LINK
# https://github.com/tylerdotrar/Invoke-FileUpload
    

    [Alias('server')]

    Param ( 
        [switch] $Start,
        [switch] $Stop,
        [switch] $Focus,
        [switch] $Help,
        
        # Server Options
        [string] $Server = '<absolutepath>',
        [switch] $SSL,
        [switch] $Debug,
        [string] $IP,
        [int]    $Port
    )

    
    # Return Get-Help information
    if ($Help) {
        Get-Help Upload-Server
        return
    }


    # Attempt to find the server if it is not input
    if ($Server -eq '<absolutepath>') {

        $Temp = Get-ChildItem $env:USERPROFILE -Recurse -Name 'upload_server.py'

        if ($Temp) { $Server = (Get-Item "$env:UserProfile\$Temp").FullName }
    }
    
    # Verify server path is an absolute path
    elseif (Test-Path -LiteralPath $Server) {
        $Server = (Get-Item $Server).FullName
    }
 

    # Server location not properly specified
    if (($Server -eq '<absolutepath>') -or !(Test-Path -LiteralPath $Server)) {
        Write-Host 'Server does not exist!' -ForegroundColor Red
        return
    }


    # Determine if current PowerShell terminal is inside Windows Terminal
    if ( (((Get-Process -Name 'OpenConsole').StartTime) | ForEach-Object { [string]$_ } ) -Contains [string](Get-Process -ID $PID).StartTime 2>$NULL ) {

        # Create an ordered hashtable of Windows Terminal tabs (Main:PID or Arbitrary:PID)
        $WindowContext = [ordered]@{}
        $OpenWindows = (Get-Process -Name 'OpenConsole') | Sort-Object -Property StartTime
        $Inc = 1
        
        foreach ($WinTerm in $OpenWindows) {

            if ( ($WinTerm).StartTime -match (Get-Process -ID $PID).StartTime ) {
                $WindowContext += @{'Main' = $WinTerm.ID}
            }
            else { $WindowContext += @{"Arbitrary$Inc" = $WinTerm.ID} ; $Inc++ }

        }


        # Get Index Number of Current Windows Terminal Session
        if ($WindowContext.count -eq 1) { $MainWindow = 1 }
        else { $MainWindow = $($WindowContext.Keys).IndexOf('Main') + 1 }

        $UsingWindowsTerminal = $TRUE
    }


    # Determine PowerShell Version to use for the server
    else {
        if ($PSEdition -eq 'Core') { $PowerShell = 'pwsh' }
        else { $PowerShell = 'powershell' }
    }
    

    # Create 'uploads' folder if it doesn't already exist
    $ServerPath = $Server.Replace($Server.Split('\')[-1], $NULL)
    $UploadsFolder = $ServerPath + 'uploads'

    if (!(Test-Path -LiteralPath $UploadsFolder)) {
        New-Item -Path $UploadsFolder | Out-Null
    }

    
    # Configure Optional Server Parameters (Windows Terminal)
    if ($UsingWindowsTerminal) {

        # Windows Terminal server tab title
        if ($SSL) { $Title = 'HTTPS Server' }
        else { $Title = 'HTTP Server' }

        if ($Port) { $Title += " : $Port" }
        else { $Title += ' : 54321' }

        $Commands = "`$Host.UI.RawUI.WindowTitle = '$Title'; Set-Location -LiteralPath $ServerPath; Clear-Host; python3 $Server"

        if ($SSL) { $Commands += " --ssl" }
        if ($Debug) { $Commands += " --debug" }
        if ($IP) { $Commands += " --ip $IP" }
        if ($Port) { $Commands += " --port $Port" }

        $Commands += "; exit"
    }

    # Configure Optional Server Parameters (Desktop PowerShell)
    else {
        
        # Determine server WindowStyle
        if ($Focus) { $Window = 'Normal' }
        else { $Window = 'Minimized' }

        $Commands = "-WindowStyle $Window", "-Command Set-Location -LiteralPath $ServerPath ; python3 $Server"

        if ($SSL) { $Commands[-1] += " --ssl" }
        if ($Debug) { $Commands[-1] += " --debug" }
        if ($IP) { $Commands[-1] += " --ip $IP" }
        if ($Port) { $Commands[-1] += " --port $Port" }

    }
  

    # Determine if server is already running (NOT ACCURATE)
    $Running = Get-Process -Name python3.8 2>$NULL


    # Start server
    if ($Start) {

        if (!$Running) {
            
            # Create a new Windows Terminal window
            if ($UsingWindowsTerminal) {
                
                # Initialize Wscript ComObject to send Keystrokes to Applications
                $WindowsTerminalHack = New-Object -ComObject Wscript.Shell

                # Create new tab (Send CTRL + SHIFT + T to current window)
                $WindowsTerminalHack.SendKeys('^+t')
                Start-Sleep -Milliseconds 250

                # Send commands to title the Window and start the server
                $WindowsTerminalHack.SendKeys("$Commands{ENTER}")

                # Return to original tab (Send CTRL + ALT + Index Number to current window)
                if (!$Focus) {
                    $WindowsTerminalHack.SendKeys("^%$MainWindow")
                }
            }

            # Open new PowerShell session
            else { Start-Process -FilePath $PowerShell -ArgumentList $Commands }

            Write-Host "Server started." -ForegroundColor Green
        }

        else { Write-Host "Server is already running." -ForegroundColor Green }
    }


    # Stop server
    elseif ($Stop) {

        if ($Running) {
            Stop-Process -Name python3.8
            Write-Host "Server stopped." -ForegroundColor Red
        }

        else { Write-Host "Server is already stopped." -ForegroundColor Red }
    }


    # Failed to specify whether to start or stop server
    else { Write-Host "No action specified." -ForegroundColor Red }
}
