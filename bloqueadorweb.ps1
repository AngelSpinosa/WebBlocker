# Bloqueador de sitios web

function Test-IsAdmin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 1. Verificar permisos
if (-not (Test-IsAdmin)) {
    Write-Error "Debe ejecutarse como administrador."
    exit 1
}

# 2. Leer y limpiar lista
$rawSites = Get-Content '.\blocked_sites.txt' |
            Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') }

# 2.1 Detectar duplicados (case-insensitive)
$seen = @{}
$uniqueSites = @()
foreach ($site in $rawSites) {
    $normalized = $site.Trim().ToLower()
    if ($seen.ContainsKey($normalized)) {
        Write-Warning "El sitio '$site' ya fue añadido anteriormente. Línea duplicada ignorada."
    } else {
        $seen[$normalized] = $true
        $uniqueSites += $site.Trim()
    }
}

if ($uniqueSites.Count -eq 0) {
    Write-Warning "La lista de sitios válidos está vacía. No se aplicaron bloqueos."
    exit 0
}

# 3. Copia de seguridad del hosts
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupPath = "$hostsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $hostsPath $backupPath

# 4. Construir nuevo contenido del archivo hosts
$newHosts = @()
$newHosts += "127.0.0.1 localhost"
foreach ($site in $uniqueSites) {
    $newHosts += "127.0.0.1`t$site"
}

# 5. Escribir hosts
$newHosts | Out-File $hostsPath -Encoding ASCII

# 6. Vaciar caché DNS
ipconfig /flushdns | Out-Null

# 7. Resumen
Write-Host "`n✔ Se bloquearon $($uniqueSites.Count) sitios:`n"

$i = 1
foreach ($site in $uniqueSites) {
    Write-Host ("{0,3}. {1}" -f $i, $site)
    $i++
}

Write-Host "`n✔ Hosts respaldado en: $backupPath"
