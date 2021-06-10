# Code runs under loacal Administrator account and starts in root folder '/'

# create log file in c:\Windows\temp
$filePath = $env:SystemRoot + "\Temp\" + (Get-Date).ToString("yyyy-MM-dd-hh-mm") + ".log"
New-Item -Force $filePath -ItemType file
 
# log statements
Add-Content $filePath ("region: {0}" -f "$TF_REGION")
Add-Content $filePath ("instance type: {0}`n" -f "$TF_INSTANCE_TYPE")
$content = Get-Content $filePath
Write-Host $content
