param(
    [string]$Device = "R58NC08VNWD"
)

& (Join-Path $PSScriptRoot "run_supabase_role.ps1") -Role student -Device $Device
