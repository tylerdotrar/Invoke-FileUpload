# Invoke-FileUpload
**This repository is outdated and no longer maintained.  Check out the successor `P2.FileTransfer` [here](https://github.com/tylerdotrar/P2.FileTransfer).**

![Python x PowerShell](https://cdn.discordapp.com/attachments/620986290317426698/751195478976102420/Invoke-FileUpload.gif)

Higher resolution GIF [here](https://gfycat.com/scratchyeducateddragon).

# Overview
`Python x PowerShell encrypted file transfer using a custom Python-based flask server and self-signed certs.`

This is a small, stripped down version of a feature from a project I was working 
on about a month ago, before I had a GitHub page.  Also, figured I'd revitalize it
because I was getting tired of constantly having to use a thumbdrive to move tiny
documents from my desktop to my laptop.

I do **NOT** endorse malicious use of this content in any way, shape, or form.

The idea is that one system will host '**upload_server.py**', and using '**Invoke-FileUpload.ps1**'
you can upload files to said system hosting the server over an HTTPS connection (*utilizing self-signed
certificates*) entirely via PowerShell.  The server is configured to only accept specific, modified POST
requests from the **Invoke-FileUpload** script.

Recently included is '**Invoke-UploadServer.ps1**' -- a script that expedites the (already easy) process
of starting, stopping, and configuring the Python server.  It even includes Windows Terminal support; 
creating a new tab running the server, adjusting the title to relevenat server info, and tabbing back
to the originally used window.

Tested on PowerShell **v5.1.19041.1** (Desktop), **v7.0.3** (Core), and **v7.1.0-preview.6** (Core).

# Invoke-UploadServer.ps1 / upload_server.py
The server is entirely self contained, not requiring HTML templates or communications with a web
browser.  By default, the server utilizes port **54321**, with **/upload** being the only hosted
webpage -- the default (local) URL for the web server is `http://localhost:54321/upload`.

As of version 2.0.0, '**upload_server.py**' now supports parameters for quick configuration.  These 
parameters are included (and expanded upon) in '**Invoke-UploadServer.ps1**'.

**PARAMETERS:**

 *[] **--ssl**  (Enable HTTPS)*
 
 *[] **--debug**  (Enable debugger)*
 
 *[] **--ip**  (Change default IP address; NOT really recommended)*
 
 *[] **--port**  (Change default port; default 54321)*
 
 **[`Invoke-UploadServer.ps1 Specific:`]**
 
 *[] **-Server** (Absolute path to 'upload_server.py'; if not input, script will attempt to find it)*
 
 *[] **-Start**  (Start the server; Only works if no instance of Python3.8 is running)*
 
 *[] **-Stop**  (Stop the server; Not reliable if more than one instance of Python3.8 is running)*
 
 *[] **-Focus**  (Give new server window focus instead of returning focus to current terminal)*
 
 *[] **-Help** (Return Get-Help Information)*
 
**Python Syntax:**

`PS C:\Users\Bobby> python3 .\upload_server.py --port 8081 --ssl`

**PowerShell Syntax and Tips:**

**[1]** `PS C:\Users\Bobby> Invoke-UploadServer -Start`
**[2]** `PS C:\Users\Bobby> server -SSL -Port 4444 -Debug -Start`

 -- Place script contents inside user **$PROFILE** instead of calling '**Invoke-UploadServer.ps1**' script
 
 -- Replace the default **$Server** value (*`<absolutepath>`*) to the absolute path of '**upload_server.py**'

The server is also configured to respond with successful **200** status codes, regardless of if the upload
was successful; the response message should indicate the actual upload status or error.

**200 OK STATUS CODES / SERVER MESSAGES:**

 *[] `"FILETYPE NOT ALLOWED"`  --  File extension not contained in extension list.*
 
 *[] `"FILENAME NULL"`  -- File was POST'd, but the filename was empty.*
 
 *[] `"UPLOAD ONLY"`  --  GET request to the upload webpage*
 
 *[] `"SUCCESSFUL UPLOAD"` --  File successfully uploaded to 'uploads' folder*

**ACCEPTED FILETYPES:**

By default, the server accepts '**.png**', '**.jpg**', '**.pdf**', '**.txt**', and '**.zip**' files.
Modify the allowed extensions via the **[UPLOAD_EXTENSIONS]** variable.

**REQUIREMENTS:**

  *[] Python installed (Microsoft Store Python3.8 will suffice)*
  
  *[] In PowerShell: `pip install flask` (required for web server)*
  
  *[] In PowerShell: `pip install pyopensll` (required for HTTPS)*
  
  *[] Folder named '**uploads**' in the same directory as the server; '**Invoke-UploadServer.ps1**'
  creates this folder if it doesn't already exist.*

# Invoke-FileUpload.ps1
As of arbitrary version number 2.0.1, the script now supports both legacy PowerShell (aka Desktop)
and PowerShell Core.  It was a pain in the ass.  The only caveat is when using PowerShell Core,
file MIME types are simply generated based off of a hard-coded hashtable of file extensions rather
than of proper file contents (*this is due to .NET Core not having a MimeMapping class*).

If the **-File** or **-URL** parameters aren't used the user will be prompted for those values.

The script also has an alias titled '**upload**'

**Tip:**  Paste the script into your **$PROFILE** and change the default URL value (*`<url>`*) to the upload webpage.

**PARAMETERS:**

  *[] **-File**    --  File to be uploaded to the flask server*

  *[] **-URL**     --  URL of the server upload webpage*
  
  *[] **-Help**    --  Return Get-Help information*
  
**EXAMPLE USAGE:**

**[]** `PS C:\Users\Bobby> Invoke-FileUpload -File 'NotReal.txt' -URL 'https://localhost:54321/upload'`

`File does not exist!`

**[]** `PS C:\Users\Bobby> upload .\RealFile.txt localhost:54321/upload`

`URL neither HTTP nor HTTPS!`

**[]** `PS C:\Users\Bobby> Invoke-FileUpload -File 'RealFile.txt' -URL 'https://localhost:54321/upload'`

`Server Response (HTTPS): SUCCESSFUL UPLOAD`

**[]** `PS C:\Users\Bobby> upload`

`Enter filename: RealPic.png`

`Enter server URL: http://192.168.0.25:54321/upload`

`Server Response (HTTP): SUCCESSFUL UPLOAD`
