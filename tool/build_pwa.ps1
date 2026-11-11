# PWA build script for Student Cabinet
# Usage: .\tool\build_pwa.ps1 -Target student|admin|teacher

param(
    [Parameter(Mandatory=$false)]
    [ValidateSet('student','admin','teacher')]
    [string]$Target = 'student'
)

# Load Supabase credentials from .env or prompt
$envFile = ".env"
if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^#][^=]+?)\s*=\s*(.+?)\s*$') {
            $key = $matches[1]
            $value = $matches[2]
            Set-Variable -Name $key -Value $value -Scope Script
        }
    }
}

if (-not $SUPABASE_URL) {
    $SUPABASE_URL = Read-Host "Enter SUPABASE_URL"
}
if (-not $SUPABASE_ANON_KEY) {
    $SUPABASE_ANON_KEY = Read-Host "Enter SUPABASE_ANON_KEY"
}

# Determine entry point
$entryPoint = switch ($Target) {
    'student' { 'lib/main.dart' }
    'admin'   { 'lib/main_admin.dart' }
    'teacher' { 'lib/main_teacher.dart' }
}

Write-Host "Building PWA for $Target..." -ForegroundColor Cyan
Write-Host "Entry point: $entryPoint" -ForegroundColor Gray

# Build command
flutter build web --release `
    -t $entryPoint `
    --dart-define=USE_SUPABASE=true `
    --dart-define=SUPABASE_URL=$SUPABASE_URL `
    --dart-define=SUPABASE_ANON_KEY=$SUPABASE_ANON_KEY

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n✅ Build successful!" -ForegroundColor Green
    Write-Host "Output: build\web\" -ForegroundColor Gray
    Write-Host "`nNext steps:" -ForegroundColor Cyan
    Write-Host "1. Test locally: flutter run -d chrome -t $entryPoint ..."
    Write-Host "2. Deploy to hosting: firebase deploy / vercel / netlify"
    Write-Host "3. See PWA_DEPLOYMENT.md for instructions"
} else {
    Write-Host "`n❌ Build failed!" -ForegroundColor Red
    exit 1
}
