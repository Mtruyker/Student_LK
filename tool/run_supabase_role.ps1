param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("student", "admin", "teacher")]
    [string]$Role,

    [string]$Device = "windows",

    [string]$SupabaseUrl = "https://gfxkyhnaljhfiuqzclcs.supabase.co",

    [string]$SupabaseAnonKey = "sb_publishable__Bgm1BiIXbxU8yAVbkAdSQ_L5PD-OXP"
)

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $projectRoot

$target = switch ($Role) {
    "admin" { "lib/main_admin.dart" }
    "teacher" { "lib/main_teacher.dart" }
    default { $null }
}

$arguments = @("run", "-d", $Device)

if ($null -ne $target) {
    $arguments += @("-t", $target)
}

$arguments += @(
    "--dart-define=SUPABASE_URL=$SupabaseUrl",
    "--dart-define=SUPABASE_ANON_KEY=$SupabaseAnonKey"
)

Write-Host "Starting $Role on $Device with Supabase config..." -ForegroundColor Green
& flutter @arguments
