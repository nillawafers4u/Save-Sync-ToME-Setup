cd "C:\Users\rsjon\ToME Sync\Save-Sync-ToME"

Write-Host "🔄 Syncing latest saves from GitHub..." -ForegroundColor Cyan
git pull

Write-Host "`n🎮 Launching Tales of Maj'Eyal..." -ForegroundColor Yellow
Start-Process `
  -FilePath "C:\Program Files (x86)\Steam\steamapps\common\TalesMajEyal\t-engine.exe" `
  -WorkingDirectory "C:\Program Files (x86)\Steam\steamapps\common\TalesMajEyal" `
  -Wait

Write-Host "`n💾 Syncing your updated saves to GitHub..." -ForegroundColor Cyan
git add .
git commit -m "Auto-sync after playing Tales of Maj'Eyal on $(hostname)" | Out-Null
git push

Write-Host "`n✅ All synced! You’re good to go." -ForegroundColor Green
Read-Host "`nPress Enter to close"