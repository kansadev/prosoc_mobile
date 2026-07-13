# Configuration initiale de la signature release Prosoc (Windows).
# Usage : .\scripts\setup_release_signing.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot

Write-Host "=== Signature release Prosoc ===" -ForegroundColor Cyan

# --- Android ---
$androidKeyProps = Join-Path $root "android\key.properties"
$androidKeyExample = Join-Path $root "android\key.properties.example"
$androidKeystore = Join-Path $root "android\app\upload-keystore.jks"

if (-not (Test-Path $androidKeyProps)) {
    Copy-Item $androidKeyExample $androidKeyProps
    Write-Host "[Android] key.properties créé depuis l'exemple. Éditez-le avec vos mots de passe." -ForegroundColor Yellow
} else {
    Write-Host "[Android] key.properties existe déjà." -ForegroundColor Green
}

if (-not (Test-Path $androidKeystore)) {
    Write-Host "[Android] Génération du keystore upload-keystore.jks..." -ForegroundColor Yellow
    Write-Host "Répondez aux questions keytool (nom, organisation, etc.)." -ForegroundColor Gray
    keytool -genkey -v `
        -keystore $androidKeystore `
        -keyalg RSA `
        -keysize 2048 `
        -validity 10000 `
        -alias upload
    Write-Host "[Android] Keystore créé : $androidKeystore" -ForegroundColor Green
} else {
    Write-Host "[Android] Keystore existe déjà." -ForegroundColor Green
}

# --- iOS ---
$iosSigning = Join-Path $root "ios\Signing.xcconfig"
$iosSigningExample = Join-Path $root "ios\Signing.xcconfig.example"

if (-not (Test-Path $iosSigning)) {
    Copy-Item $iosSigningExample $iosSigning
    Write-Host "[iOS] Signing.xcconfig créé depuis l'exemple. Renseignez DEVELOPMENT_TEAM." -ForegroundColor Yellow
} else {
    Write-Host "[iOS] Signing.xcconfig existe déjà." -ForegroundColor Green
}

Write-Host ""
Write-Host "Étapes suivantes :" -ForegroundColor Cyan
Write-Host "  1. Éditer android/key.properties (mots de passe + chemin keystore)"
Write-Host "  2. Éditer ios/Signing.xcconfig (Team ID Apple + bundle ID définitif)"
Write-Host "  3. Android : flutter build appbundle --release"
Write-Host "  4. iOS     : flutter build ipa --release (sur macOS avec certificats Apple)"
