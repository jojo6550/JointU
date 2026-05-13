$host_addr = "localhost"
$port = "8000"
$root = $PSScriptRoot

Write-Host "JointU dev server: http://$host_addr`:$port"
Write-Host "Press Ctrl+C to stop.`n"

php -S "$host_addr`:$port" -t $root
