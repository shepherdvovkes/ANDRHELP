# Скрипт для сборки приложения с credentials
param(
    [string]$CredentialsPath = "..\backend\speech-to-text-key.json",
    [string]$OpenAIApiKey = ""
)

# Читаем credentials
$credentialsJson = Get-Content $CredentialsPath -Raw
# Экранируем для dart-define (заменяем переносы строк и кавычки)
$credentialsEscaped = $credentialsJson -replace "`"", '\"' -replace "`r`n", '\n' -replace "`n", '\n'

# Собираем команду
$buildCmd = "flutter build apk --release"

if ($credentialsEscaped) {
    $buildCmd += " --dart-define=GOOGLE_CREDENTIALS_JSON=`"$credentialsEscaped`""
}

if ($OpenAIApiKey) {
    $buildCmd += " --dart-define=OPENAI_API_KEY=$OpenAIApiKey"
}

Write-Host "Building with credentials..."
Invoke-Expression $buildCmd

