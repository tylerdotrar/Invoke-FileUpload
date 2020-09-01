function Invoke-FileUpload {
#.SYNOPSIS
# Rudimentary custom Python-based flask server file uploading.
# ARBITRARY VERSION NUMBER:  1.1.2
# AUTHOR:  Tyler McCann (@tyler.rar)
#
#.DESCRIPTION
# Script designed to upload files to a custom made Python-based flask server.  Meant to be custom by
# modifying specific packet information, not require HTML templates, and only require the 'server.py'
# and this script.  Server should be configurable, able to toggle between HTTP and HTTPS. Currently,
# PowerShell Core is not supported because I'm ignorant about .NET.
#
# Parameters:
#    -File    -->  File to be uploaded to the flask server
#    -URL     -->  URL of the server hosted upload page
#    
# Example Usage:
#    [] PS C:\Users\Bobby> Invoke-FileUpload -File "NotReal.txt" -URL https://localhost:8081/upload
#       File does not exist!

#    [] PS C:\Users\Bobby> Invoke-FileUpload -File "RealFile.txt" -URL https://localhost:8081/upload
#       Server Response (HTTPS): SUCCESSFUL UPLOAD
#
#    [] PS C:\Users\Bobby> upload
#       Enter filename: RealPic.png
#       Enter server URL: https://localhost:8081/upload
#
#       Server Response (HTTP): SUCCESSFUL UPLOAD
#
#    [] PS C:\Users\Bobby> upload -File "RealFile.txt" -URL localhost:8081/upload
#       URL neither http or https!


    [Alias('upload')]
    Param ( [string]$File, [uri]$URL='<URL>', [switch]$Help )


    # Return Get-Help information
    if ($Help) { return Get-Help Invoke-FileUpload }


    # Return because PowerShell Core is not yet supported.
    if ($PSVersionTable.PSEdition -eq 'Core') {
        Write-Host "Current version does not supported PowerShell Core!" -ForegroundColor DarkRed
        return
    }


    # Prompt for File and/or Server URL
    if (!$File -or ($URL -eq '<URL>')) {

        if (!$File) { Write-Host "Enter filename: " -ForegroundColor Yellow -NoNewline ; $File = Read-Host }

        if ($URL -eq '<URL>') { Write-Host "Enter server URL: " -ForegroundColor Yellow -NoNewline ; $URL = Read-Host }

        Write-Host ""
    }

    
    # If using HTTPS, bypass self-signed cert
    if ($URL -like "https://*") {
        $CertBypass = @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

        Add-Type $CertBypass
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy

        $CommType = "HTTPS"
    }

    # If using HTTP, continue regularly
    elseif ( $URL -like "http://*") { $CommType = "HTTP" }


    # Verify URL
    else {
        Write-Host "URL neither http or https!" -ForegroundColor DarkRed
        return
    }
    

    # Verify File
    if ( !(Test-Path -LiteralPath $File) ) {
        Write-Host "File does not exist!" -ForegroundColor DarkRed
        return
    }

    else {
        $TempFileName = Split-Path -Leaf $File
        $File = (Get-Item $File).FullName
    }


    # Get file Mime type (Content-Type)
    Add-Type -AssemblyName System.Web
    $ContentType = [System.Web.MimeMapping]::GetMimeMapping($File)


    # Create a Class for Sending / Receiving HTTP(s) Data
    Add-Type -AssemblyName System.Net.Http
    $httpClientHandler = New-Object System.Net.Http.HttpClientHandler
    $httpClient = New-Object System.Net.Http.Httpclient $httpClientHandler


    ## Start Multipart Form Creation ##

    $FileStream = New-Object System.IO.FileStream @($File, [System.IO.FileMode]::Open)
    $DispositionHeader = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue "form-data"

    # IMPORTANT: Custom Python Server Specific
    $DispositionHeader.Name = "`"TYLER.RAR`""
    $DispositionHeader.FileName = "`"$TempFileName`""

    $StreamContent = New-Object System.Net.Http.StreamContent $FileStream
    $StreamContent.Headers.ContentDisposition = $DispositionHeader
    $StreamContent.Headers.ContentType = New-Object System.Net.Http.Headers.MediaTypeHeaderValue $ContentType
        
    $MultipartContent = New-Object System.Net.Http.MultipartFormDataContent
    $MultipartContent.Add($StreamContent)

    ## End Multipart Form Creation ##


    # Attempt to upload file and return server response
    Try {
        $Transmit = $httpClient.PostAsync($URL, $MultipartContent).Result
        $ServerMessage = $Transmit.Content.ReadAsStringAsync().Result

        Write-Host "Server Response ($CommType): " -ForegroundColor Yellow -NoNewline
        Write-Host $ServerMessage
    }

    # This error will appear if you put in an incorrect URL (and other things)
    Catch { Write-Host "File failed to upload!" -ForegroundColor DarkRed; return }

    # Cleanup Hanging Processes
    Finally {
        if ($NULL -ne $httpClient) { $httpClient.Dispose() }
        if ($NULL -ne $Transmit) { $Transmit.Dispose() }
    }
}