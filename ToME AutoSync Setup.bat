# 2> nul & powershell.exe -ExecutionPolicy Bypass -NoProfile -Command "([System.IO.StreamReader]::new('%~f0')).ReadToEnd() | Invoke-Expression" & EXIT /B
# CONFIGURATION
$RepoUrl = "https://github.com/nillawafers4u/Save-Sync-ToME.git"
$GameFolder = "$env:USERPROFILE\T-Engine\4.0\tome\save"
$LocalRepo = "$env:USERPROFILE\Save-Sync-ToME"
$GameProfiles = "$env:USERPROFILE\T-Engine\4.0\profiles"

# ==========================
# 1️⃣ Clone repo if it doesn't exist
if (-not (Test-Path $LocalRepo)) {
    Write-Host "📥 Cloning repo to $LocalRepo..."

    # Use Start-Process with -Wait to guarantee blocking
    $gitArgs = "clone", $RepoUrl
    $process = Start-Process git -ArgumentList $gitArgs -Wait -NoNewWindow -PassThru -WorkingDirectory $env:USERPROFILE

    if ($process.ExitCode -ne 0) {
        Write-Host "❌ Git clone failed with exit code $($process.ExitCode)!" -ForegroundColor Red
        exit 1
    }

    Write-Host "✅ Clone completed successfully!"
} else {
    Write-Host "🔄 Repo already exists — pulling latest changes..."
    Set-Location $LocalRepo
    git pull
}







# ==========================
# 2️⃣ Merge existing saves (keep newest)

Write-Host "🔀 Starting simple merge: $GameFolder -> $LocalRepo" -ForegroundColor Cyan

# Safety checks
if (-not (Test-Path $GameFolder)) {
    Write-Host "⚠️ Game folder not found: $GameFolder" -ForegroundColor Yellow
    return
}
if (-not (Test-Path $LocalRepo)) {
    Write-Host "⚠️ Local repo folder not found: $LocalRepo" -ForegroundColor Yellow
    return
}
if (-not (Test-Path (Join-Path $LocalRepo ".git"))) {
    Write-Host "⚠️ The target folder is not a git repo: $LocalRepo`nPlease clone your repo first." -ForegroundColor Yellow
    return
}


# Track if any files were copied
$copied = @()

# Get all save files in the game folder
Get-ChildItem -Path $GameFolder -Recurse -File | ForEach-Object {
    $gameFile = $_
    $relative = $gameFile.FullName.Substring($GameFolder.Length).TrimStart('\')
    $targetPath = Join-Path "$LocalRepo\save" $relative
    $targetDir = Split-Path $targetPath -Parent

    # Ensure target directory exists
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    if (-not (Test-Path $targetPath)) {
        # file missing in repo -> copy
        Copy-Item $gameFile.FullName $targetPath
        $copied += $relative
    } else {
        # file exists -> compare timestamps
        $repoTime = (Get-Item $targetPath).LastWriteTime
        $gameTime = $gameFile.LastWriteTime
        if ($gameTime -gt $repoTime) {
            Copy-Item $gameFile.FullName $targetPath -Force
            $copied += $relative
        }
    }
}

# repeat the process but for the profile folder now
Get-ChildItem -Path $GameProfiles -Recurse -File | ForEach-Object {
    $gameFile = $_
    $relative = $gameFile.FullName.Substring($GameProfiles.Length).TrimStart('\')
    $targetPath = Join-Path "$LocalRepo\profiles" $relative
    $targetDir = Split-Path $targetPath -Parent

    # Ensure target directory exists
    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    if (-not (Test-Path $targetPath)) {
        # file missing in repo -> copy
        Copy-Item $gameFile.FullName $targetPath
        $copied += $relative
    } else {
        # file exists -> compare timestamps
        $repoTime = (Get-Item $targetPath).LastWriteTime
        $gameTime = $gameFile.LastWriteTime
        if ($gameTime -gt $repoTime) {
            Copy-Item $gameFile.FullName $targetPath -Force
            $copied += $relative
        }
    }
}

if ($copied.Count -eq 0) {
    Write-Host "✅ No files needed copying — repo already has latest saves." -ForegroundColor Green
} else {
    Write-Host "✅ Copied $($copied.Count) file(s):" -ForegroundColor Green
    $copied | ForEach-Object { Write-Host "  - $_" }

    # Stage, commit, push (only if git sees changes)
    Push-Location $LocalRepo
    git add .
    $status = git status --porcelain
    if ($status) {
        git commit -m "Merged local saves on $(hostname) - auto-merge"
        git push
        Write-Host "📤 Changes committed and pushed." -ForegroundColor Green
    } else {
        Write-Host "ℹ️ No changes to commit after copying." -ForegroundColor Yellow
    }
    Pop-Location
}


# ==========================
# 4️⃣ Replace game folder with Junction link
if (Test-Path $GameFolder) {
    # Check if it's already a symlink pointing to the correct repo
    $attribs = Get-Item $GameFolder -Force
    if ($attribs.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $linkTarget = (Get-Item $GameFolder -Force | Select-Object -ExpandProperty Target)
        if ($linkTarget -eq "$LocalRepo\save") {
            Write-Host "🔗 Junction for save files already exists and points to the correct location. Skipping creation." -ForegroundColor Green
            Read-Host "`nPress Enter to close"
            return
        } else {
            Write-Host "⚠️ Existing symlink points elsewhere. Removing it..." -ForegroundColor Yellow
            Remove-Item $GameFolder -Force
        }
    } else {
        Write-Host "🗑 Deleting existing save folder..." -ForegroundColor Cyan
        Remove-Item $GameFolder -Recurse -Force
    }
}

Write-Host "🔗 Creating Junction link for save folder(admin required)..." -ForegroundColor Cyan
$MklinkCmd = "mklink /J `"$GameFolder`" `"$LocalRepo\save`""
Start-Process cmd.exe -Verb RunAs -ArgumentList "/c $MklinkCmd" -Wait

Write-Host "✅ Junciton Link setup for saves complete!" -ForegroundColor Green

# ==========================
# 4️⃣ Replace Profiles folder with Junction link
if (Test-Path $GameProfiles) {
    # Check if it's already a symlink pointing to the correct repo
    $attribs = Get-Item $GameProfiles -Force
    if ($attribs.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        $linkTarget = (Get-Item $GameProfiles -Force | Select-Object -ExpandProperty Target)
        if ($linkTarget -eq "$LocalRepo\save") {
            Write-Host "🔗 Junction for Profiles already exists and points to the correct location. Skipping creation." -ForegroundColor Green
            Read-Host "`nPress Enter to close"
            return
        } else {
            Write-Host "⚠️ Existing symlink points elsewhere. Removing it..." -ForegroundColor Yellow
            Remove-Item $GameProfiles -Force
        }
    } else {
        Write-Host "🗑 Deleting existing save folder..." -ForegroundColor Cyan
        Remove-Item $GameProfiles -Recurse -Force
    }
}

Write-Host "🔗 Creating Junciton link for profiles folder(admin required)..." -ForegroundColor Cyan
$MklinkCmd = "mklink /J `"$GameProfiles`" `"$LocalRepo\profiles`""
Start-Process cmd.exe -Verb RunAs -ArgumentList "/c $MklinkCmd" -Wait

Write-Host "✅ Junciton Link setup for Profiles complete!" -ForegroundColor Green


Write-Host "🎉 Setup complete! You can now run the game with your shortcut found in the repo folder!" -ForegroundColor Green
Read-Host "`nPress Enter to close"

exit 42