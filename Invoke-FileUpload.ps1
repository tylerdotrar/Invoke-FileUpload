function Invoke-FileUpload {
#.SYNOPSIS
# Python x PowerShell file transfer.
# ARBITRARY VERSION NUMBER:  2.0.1
# AUTHOR:  Tyler McCann (@tyler.rar)
#
#.DESCRIPTION
# Script designed to upload files to a custom Python-based flask web server.  Supports HTTP and HTTPS
# protocols.  Python server should only accept files sent from this script due to a modified content
# disposition header name. Version 2.0.0 now supprts PowerShell Core.  
#
# Parameters:
#    -File    -->   File to upload to the web server
#    -URL     -->   URL of the server upload webpage
#    -Help    -->   Return Get-Help information
#    
# Example Usage:
#    [ ]  PS C:\Users\Bobby> Invoke-FileUpload -File "NotReal.txt" -URL https://localhost:8081/upload
#     -   File does not exist!
#
#    [ ]  PS C:\Users\Bobby> Invoke-FileUpload -File "RealFile.txt" -URL https://localhost:8081/upload
#     -   Server Response (HTTPS): SUCCESSFUL UPLOAD
#
#    [ ]  PS C:\Users\Bobby> upload
#     -   Enter filename: RealPic.png
#     -   Enter server URL: https://localhost:8081/upload
#     -
#     -   Server Response (HTTPS): SUCCESSFUL UPLOAD
#
#    [ ]  PS C:\Users\Bobby> upload -File "RealFile.txt" -URL localhost:8081/upload
#     -   URL neither http or https!


    [Alias('upload')]
    Param ( [string]$File, [uri]$URL='<URL>', [switch]$Help )


    # Return Get-Help information
    if ($Help) { return Get-Help Invoke-FileUpload }


    # Prompt for File and/or Server URL
    if (!$File -or ($URL -eq '<URL>')) {

        if (!$File) { Write-Host "Enter filename: " -ForegroundColor Yellow -NoNewline ; $File = Read-Host }

        if ($URL -eq '<URL>') { Write-Host "Enter server URL: " -ForegroundColor Yellow -NoNewline ; $URL = Read-Host }

        Write-Host ""
    }

    
    # Bypass self-signed certs (HTTPS)
    if ($URL -like "https://*") {

        $CertBypass = @"
using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Net.Security;
using System.Security.Cryptography.X509Certificates;

namespace SelfSignedCerts
{
    public class Bypass
    {
         public static Func<HttpRequestMessage,X509Certificate2,X509Chain,SslPolicyErrors,Boolean> ValidationCallback = 
            (message, cert, chain, errors) => {
                return true; 
            };
    }
}
"@
        $Protocol = "HTTPS"

        if ($PSVersionTable.PSEdition -eq 'Core') {
            Add-Type $CertBypass
        }
        else {
            Add-Type -AssemblyName System.Net.Http
            Add-Type $CertBypass -ReferencedAssemblies System.Net.Http
        }
    }

    # Continue regularly (HTTP)
    elseif ( $URL -like "http://*") {
        $Protocol = "HTTP"
    }

    # Incorrect URL format (neither)
    else {
        Write-Host "URL neither http or https!" -ForegroundColor DarkRed
        return
    }
    

    # Verify File
    if (Test-Path -LiteralPath $File) {
        $TempFileName = Split-Path -Leaf $File
        $File = (Get-Item $File).FullName
    }

    else {
        Write-Host "File does not exist!" -ForegroundColor DarkRed
        return
    }


    # Mime Type Detection (PowerShell Core)
    if ($PSVersionTable.PSEdition -eq 'Core') {

        # Create Content Type Map
        $MimeTypeMap = @{
	        ".txt"  = "text/plain";
	        ".jpg"  = "image/jpeg";
	        ".jpeg" = "image/jpeg";
	        ".png"  = "image/png";
	        ".gif"  = "image/gif";
	        ".zip"  = "application/zip";
	        ".rar"  = "application/x-rar-compressed";
	        ".gzip" = "application/x-gzip";
	        ".json" = "application/json";
	        ".xml"  = "application/xml";
        }

        # Get file Mime type (Content-Type)
        $Extension = (Get-Item $File).Extension.ToLower()
        $ContentType = $MimeTypeMap[$Extension]
    }

    # Mime Type Detection (Desktop PowerShell)
    else {

        # Get file Mime type (Content-Type)
        Add-Type -AssemblyName System.Web
        $ContentType = [System.Web.MimeMapping]::GetMimeMapping($File)
    }


    # Create a Class for Sending / Receiving HTTP(s) Data
    Add-Type -AssemblyName System.Net.Http
    $httpClientHandler = [System.Net.Http.HttpClientHandler]::new()

    if ($Protocol -eq 'HTTPS') {
        $httpClientHandler.ServerCertificateCustomValidationCallback = [SelfSignedCerts.Bypass]::ValidationCallback
    }

    $httpClient = [System.Net.Http.HttpClient]::new($httpClientHandler)


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

        Write-Host "Server Response ($Protocol): " -ForegroundColor Yellow -NoNewline
        Write-Host $ServerMessage
    }

    # This error will appear if you put in an incorrect URL (and other things)
    Catch { 
        Write-Host "File failed to upload!" -ForegroundColor DarkRed
        return
    }

    # Cleanup Hanging Processes / Remove Self-Signed Certificate Bypass
    Finally {
        if ($NULL -ne $httpClient) { $httpClient.Dispose() }
        if ($NULL -ne $Transmit) { $Transmit.Dispose() }
        if ($NULL -ne $FileStream) { $FileStream.Dispose() }
    }
}