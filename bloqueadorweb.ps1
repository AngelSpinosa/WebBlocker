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
$sites = Get-Content '.\blocked_sites.txt' |
         Where-Object { $_.Trim() -ne '' -and -not $_.Trim().StartsWith('#') }

# 3. Copia de seguridad del hosts
$hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupPath = "$hostsPath.bak_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
Copy-Item $hostsPath $backupPath

# 4. Construir nuevo contenido
$newHosts = @()
$newHosts += "127.0.0.1 localhost"
foreach ($site in $sites) {
    $newHosts += "127.0.0.1`t$site"
}

# 5. Escribir hosts
$newHosts | Out-File $hostsPath -Encoding ASCII

# 6. Vaciar caché DNS
ipconfig /flushdns | Out-Null

# 7. Resumen
Write-Host "Bloqueados $($sites.Count) sitios. Hosts respaldado en $backupPath."