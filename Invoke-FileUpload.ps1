function Invoke-FileUpload {
#.SYNOPSIS
# Python x PowerShell file transfer script.
# ARBITRARY VERSION NUMBER:  2.1.5
# AUTHOR:  Tyler McCann (@tyler.rar)
#
#.DESCRIPTION
# This script is designed to upload files to a custom Python-based flask web server; supporting both HTTP and HTTPS 
# protocols.  The Python web server should only accept files sent from this script due to the modified HTTP 
# Content-Disposition header name.  If PowerShell Core is used, file MIME types are determined based off of a hard-
# coded list of file extensions; whereas with Desktop Powershell, MIME types are automatically determined based off
# of file contents.
#
# Alternate data streams (ADS) are NOT supported.
#
# Recommendations:
# -- Use 'FileTransfer.psm1' (and included instructions) from the repo to load this script from your $PROFILE.
# -- Replace the default URL value if you don't plan on modifying server settings.
#
# Parameters:
#    -File          -->   File to upload to the web server
#    -URL           -->   URL of the server upload webpage
#    -Help          -->   (Optional) Return Get-Help information
#    
# Example Usage:
#    []  PS C:\Users\Bobby> Invoke-FileUpload -File 'FakeFile.txt' -URL 'https://localhost:54321/upload'
#        File does not exist!
#
#    []  PS C:\Users\Bobby> upload .\RealFile.txt localhost:54321/upload
#        URL neither HTTP nor HTTPS!
#
#    []  PS C:\Users\Bobby> Invoke-FileUpload -File 'RealFile.txt' -URL 'https://localhost:54321/upload'
#        Server Response (HTTPS): SUCCESSFUL UPLOAD
#
#    []  PS C:\Users\Bobby> upload
#        Enter filename: RealPic.png
#        Enter server URL: http://192.168.0.25:54321/upload
#        Server Response (HTTP): SUCCESSFUL UPLOAD
#
#.LINK
# https://github.com/tylerdotrar/Invoke-FileUpload


    [Alias('upload')]

    Param (
        [string] $File,
        [uri]    $URL = '<url>',
        [switch] $Help
    )


    # Return Get-Help information
    if ($Help) { return Get-Help Invoke-FileUpload }


    # Prompt for File and/or Server URL
    if (!$File -or ($URL -eq '<url>')) {

        if (!$File) { Write-Host 'Enter filename: ' -ForegroundColor Yellow -NoNewline ; $File = Read-Host }

        if ($URL -eq '<url>') { Write-Host 'Enter server URL: ' -ForegroundColor Yellow -NoNewline ; $URL = Read-Host }

    }

    
    # [!] Required by non-Core PowerShell for self-signed certificate bypass and HttpClient / HttpClientHandler creation
    if ($PSEdition -ne 'Core') {
        Add-Type -AssemblyName System.Net.Http
    }


    # Self-signed certificate bypass (HTTPS)
    if ($URL -like "https://*") {

        # C# code for HttpClientHandler certificate validation bypass (.NET Version Independent)
        $CertBypass = @'
using System;
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
'@
        
        # Reference [!] comment above
        if ($PSEdition -ne 'Core') {
            Add-Type $CertBypass -ReferencedAssemblies System.Net.Http
        }
        else {
            Add-Type $CertBypass
        }

        $Protocol = 'HTTPS'

    }

    # Continue regularly (HTTP)
    elseif ( $URL -like "http://*") {
        $Protocol = 'HTTP'
    }

    # Incorrect URL format (neither)
    else {
        Write-Host 'URL neither HTTP nor HTTPS!' -ForegroundColor DarkRed
        return
    }
    

    # Verify input file exists
    if (Test-Path -LiteralPath $File) {
        $TempFileName = Split-Path -Leaf $File
        $File = (Get-Item $File).FullName
    }

    else {
        Write-Host 'File does not exist!' -ForegroundColor DarkRed
        return
    }


    # MIME Type Detection (PowerShell Core)
    if ($PSVersionTable.PSEdition -eq 'Core') {

        # Extension-Based Content-Type Map
        $MimeTypeMap = @{
            '.txt'   =  'text/plain';
            '.jpg'   =  'image/jpeg';
            '.jpeg'  =  'image/jpeg';
            '.png'   =  'image/png';
            '.gif'   =  'image/gif';
            '.zip'   =  'application/zip';
            '.rar'   =  'application/x-rar-compressed';
            '.gzip'  =  'application/x-gzip';
            '.json'  =  'application/json';
            '.xml'   =  'application/xml';
            '.ps1'   =  'application/octet-stream';
        }

        # Get file MIME type / Content-Type (Hard-Coded)
        $Extension = (Get-Item $File).Extension.ToLower()
        $ContentType = $MimeTypeMap[$Extension]
    }


    # MIME Type Detection (Desktop PowerShell)
    else {

        # Get file MIME type / Content-Type (.NET)
        Add-Type -AssemblyName System.Web
        $ContentType = [System.Web.MimeMapping]::GetMimeMapping($File)
    }


    # Create a message handler object for the HttpClient (.NET)
    $Handler = [System.Net.Http.HttpClientHandler]::new()

    if ($Protocol -eq 'HTTPS') {
        $Handler.ServerCertificateCustomValidationCallback = [SelfSignedCerts.Bypass]::ValidationCallback
    }


    # Create an HttpClient object for sending / receiving HTTP(S) data (.NET)
    $httpClient = [System.Net.Http.HttpClient]::new($Handler)


    ## Start Multipart Form Creation ##

    $FileStream = New-Object System.IO.FileStream @($File, [System.IO.FileMode]::Open)
    $DispositionHeader = New-Object System.Net.Http.Headers.ContentDispositionHeaderValue 'form-data'

    # Custom Content-Disposition header name (Custom Python Server Specific)
    $DispositionHeader.Name = 'TYLER.RAR'
    $DispositionHeader.FileName = $TempFileName

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


    # This error will appear if you put in an incorrect URL (or other less obvious things)
    Catch { 
        Write-Host 'Failed to reach the server!' -ForegroundColor DarkRed
        return
    }


    # Cleanup Hanging Processes
    Finally {
        if ($NULL -ne $httpClient) { $httpClient.Dispose() }
        if ($NULL -ne $Transmit) { $Transmit.Dispose() }
        if ($NULL -ne $FileStream) { $FileStream.Dispose() }
    }
}