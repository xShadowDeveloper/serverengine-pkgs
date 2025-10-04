# You can write to the Applications Log by Writing a specific string to Write-Host
# 
# Start index must be:               Write-Host "<WRITE-LOG = ""*
# Between * you can log              this is a test :)
# End Index must be:                 *"">"
#
# 
#
# you can log text like this:
Write-Host "<WRITE-LOG = ""*this is a test :)*"">"
Start-Sleep 2

# or a variable with $myvariablename like this:
$log = "this is another test :)"
Write-Host "<WRITE-LOG = ""*$log*"">"
Start-Sleep 2


