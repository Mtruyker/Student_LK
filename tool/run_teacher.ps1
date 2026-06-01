param(
    [string]$Device = "windows"
)

& (Join-Path $PSScriptRoot "run_supabase_role.ps1") -Role teacher -Device $Device
