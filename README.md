# Invoke-FileUpload
PowerShell script to upload files over HTTPS to a custom Python-based flask server.

# Overview
This is a small, stripped down version of a feature from a project I was working 
on about a month ago, before I had a GitHub page.  Also, figured I'd revitalize it
because I was getting tired of constantly having to use a thumbdrive to move tiny
documents from my desktop to my laptop.

I do **NOT** endorse malicious use of this content in any way, shape, or form.

The idea is that one system will host '**upload_server.py**', and using **Invoke-FileUpload.ps1** you
can upload files to said system hosting the server over an HTTPS connection (*utilizing self-signed
certificates*) entirely via PowerShell.  The server is specifically configured to only accept POST
requests from the script.

# upload_server.py
The server is entirely self contained, not requiring HTML templates or communications with a web
browser.  By default, the server utilizes port **54321**, with **/upload** being the only hosted
webpage -- the default (local) URL for the web server is **http://localhost:54321/upload**.

As of version 2.0.1, **upload_server.py** now supports parameters for quick configuration.

**PARAMETERS:**

 *[] **--ssl**  (Enable HTTPS)*
 
 *[] **--debug**  (Enable debugger)*
 
 *[] **--ip**  (Change default IP address)*
 
 *[] **--port**  (Change default port)*
 
**Syntax:** PS C:\Users\Bobby> *python3 .\upload_server.py --port 8081 --ssl* 

The server is also configured to respond with successful **200** status codes, regardless of if the upload
was successful; the response message should indicate the actual upload status or error.

**200 OK STATUS CODES / SERVER MESSAGES:**

 *[] "FILETYPE NOT ALLOWED"  --  File extension not contained in extension list.*
 
 *[] "FILENAME NULL"  -- File was POST'd, but the filename was empty.*
 
 *[] "UPLOAD ONLY"  --  GET request to the upload webpage*
 
 *[] "SUCCESSFUL UPLOAD" --  File successfully uploaded to 'uploads' folder*

**ACCEPTED FILETYPES:**

By default, the server accepts '**.png**', '**.jpg**', '**.pdf**', '**.txt**', and '**.zip**' files.
Modify the allowed extensions via the **[UPLOAD_EXTENSIONS]** variable.

**REQUIREMENTS:**

  *[] Python installed (Microsoft Store Python3.8 will suffice)*
  
  *[] In PowerShell: **pip install flask** (required for web server)*
  
  *[] In PowerShell: **pip install pyopensll** (required for HTTPS)*
  
  *[] Folder named "**uploads**" in the same directory as the server*

# Invoke-FileUpload.ps1
As of arbitrary version number 2.0.1, the script now supports both legacy PowerShell (aka Desktop)
and PowerShell Core.  It was a pain in the ass.  The only caveat is when using PowerShell Core,
file MIME types are simply generated based off of a list of file extensions instead of proper file contents
(*this is due to .NET Core not having a MimeMapping class**).

If the **-File** or **-URL** parameters aren't used the user will be prompted for those values.

The script also has an alias titled '**upload**'

**Tip:**  Paste the script into your **$PROFILE** and change the default URL value below the alias to the upload webpage.

**PARAMETERS:**

  *[] **-File**    --  File to be uploaded to the flask server*

  *[] **-URL**     --  URL of the server upload webpage*
  
  *[] **-Help**    --  Return Get-Help information*
  
**EXAMPLE USAGE:**

**[]** PS C:\Users\Bobby> *Invoke-FileUpload -File "NotReal.txt" -URL https://localhost:54321/upload*

File does not exist!

**[]** PS C:\Users\Bobby> *Invoke-FileUpload -File "RealFile.txt" -URL https://localhost:54321/upload*

Server Response (HTTPS): SUCCESSFUL UPLOAD

**[]** PS C:\Users\Bobby> *upload*

Enter filename: *RealPic.png*

Enter server URL: *https://localhost:54321/upload*

Server Response (HTTPS): SUCCESSFUL UPLOAD
