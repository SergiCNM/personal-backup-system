# Read configuration from JSON file
$configPath = Join-Path $PSScriptRoot "config_personal.json"

if (!(Test-Path $configPath)) {
    Write-Error "Configuration file not found: $configPath"
    exit
}

$config = Get-Content $configPath | ConvertFrom-Json

Write-Host "Starting backup process..."

$startTime = Get-Date

$totalErrors = 0

# Iterate over sources and copy
foreach ($source in $config.sources) {
    $destPath = $source.destination
    if ([string]::IsNullOrWhiteSpace($destPath)) {
        Write-Warning "No destination specified for source: $($source.path). Skipping."
        continue
    }

    if ($source.type -eq "android") {
        $sourceLeaf = $source.path.Split([char[]]@('/', '\'), [StringSplitOptions]::RemoveEmptyEntries)[-1]
        $destLeaf = Split-Path $destPath -Leaf
        $destParent = Split-Path $destPath -Parent
        
        # Ensure parent destination directory exists
        if (!(Test-Path $destParent)) { 
            New-Item -ItemType Directory -Path $destParent -Force | Out-Null 
        }

        if ($sourceLeaf -eq $destLeaf) {
            # Pull into the parent so adb merges correctly without double folders
            Write-Host "Copying from Android device: $($source.path) to $destPath"
            # Execute natively on the console to preserve live progress
            adb pull -a $($source.path) $destParent
        } else {
            # Pull into destPath directly
            if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
            Write-Host "Copying from Android device: $($source.path) to $destPath"
            # Execute natively on the console to preserve live progress
            adb pull -a $($source.path) $destPath
            
            # Avoid the nested folder by moving files up if it was created
            $nestedPath = Join-Path $destPath $sourceLeaf
            if (Test-Path $nestedPath) {
                Get-ChildItem -Path $nestedPath | Move-Item -Destination $destPath -Force
                Remove-Item -Path $nestedPath -Recurse -Force
            }
        }

        # Native error fallback in case adb failed
        if ($LASTEXITCODE -ne 0 -and $LASTEXITCODE -ne $null) { $totalErrors++ }

    } elseif ($source.type -eq "local") {
        # Create destination folder if it doesn't exist
        if (!(Test-Path $destPath)) { New-Item -ItemType Directory -Path $destPath -Force | Out-Null }
        
        Write-Host "Copying from local drive: $($source.path) to $destPath"
        if (Test-Path $source.path) {
            Copy-Item -Path "$($source.path)\*" -Destination $destPath -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            Write-Warning "Local path not found: $($source.path)"
            $totalErrors++
        }
    } else {
        Write-Warning "Unknown source type: $($source.type)"
    }
}

$totalFiles = 0
$totalBytes = 0

# Calculate combined totals of all backup destinations
foreach ($source in $config.sources) {
    if (Test-Path $source.destination) {
        $stats = Get-ChildItem -Path $source.destination -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum
        if ($null -ne $stats.Count) { $totalFiles += $stats.Count }
        if ($null -ne $stats.Sum) { $totalBytes += [long]$stats.Sum }
    }
}

Write-Host "`n========================================="
if ($totalErrors -eq 0) {
    Write-Host "[OK] BACKUP COMPLETED CORRECTLY" -ForegroundColor Green
} else {
    Write-Host "[!] BACKUP COMPLETED WITH ERRORS" -ForegroundColor Yellow
}
Write-Host "========================================="
Write-Host ("Total Files in Backup : {0}" -f $totalFiles)

if ($totalErrors -gt 0) {
    Write-Host ("Errors Encountered    : {0}" -f $totalErrors) -ForegroundColor Red
}

$mb = [math]::Round($totalBytes / 1MB, 2)
Write-Host ("Total Size Across All : {0} MB" -f $mb)

$endTime = Get-Date
$duration = $endTime - $startTime
Write-Host ("Total Execution Time  : {0:hh\:mm\:ss}" -f $duration)
Write-Host "========================================="