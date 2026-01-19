# 🚀 Quick Setup Script for Emergency Integration

Write-Host "=================================" -ForegroundColor Cyan
Write-Host "MediLinko Emergency Integration" -ForegroundColor Cyan
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""

# Check if emergencyMed directory exists
$emergencyMedPath = "C:\Users\SushilSC\Desktop\emergencyMed"
if (-Not (Test-Path $emergencyMedPath)) {
    Write-Host "❌ EmergencyMed directory not found at: $emergencyMedPath" -ForegroundColor Red
    Write-Host "   Please update the path in this script." -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ EmergencyMed directory found" -ForegroundColor Green

# Step 1: Install axios in MediLinko backend
Write-Host ""
Write-Host "📦 Step 1: Installing axios in MediLinko backend..." -ForegroundColor Yellow
Set-Location "C:\Users\SushilSC\MediLinko\backend"
npm install axios
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Axios installed successfully" -ForegroundColor Green
} else {
    Write-Host "❌ Failed to install axios" -ForegroundColor Red
    exit 1
}

# Step 2: Check emergencyMed server dependencies
Write-Host ""
Write-Host "📦 Step 2: Checking emergencyMed dependencies..." -ForegroundColor Yellow
Set-Location "$emergencyMedPath\server"
if (Test-Path "package.json") {
    Write-Host "✅ EmergencyMed server found" -ForegroundColor Green
    npm install
} else {
    Write-Host "❌ EmergencyMed server not found" -ForegroundColor Red
    exit 1
}

# Step 3: Verify configuration
Write-Host ""
Write-Host "🔧 Step 3: Checking configuration..." -ForegroundColor Yellow
Set-Location "C:\Users\SushilSC\MediLinko"

# Check backend .env
if (Test-Path "backend\.env") {
    $envContent = Get-Content "backend\.env" -Raw
    if ($envContent -match "EMERGENCY_MED_URL") {
        Write-Host "✅ EMERGENCY_MED_URL found in .env" -ForegroundColor Green
    } else {
        Write-Host "⚠️  EMERGENCY_MED_URL not found in .env" -ForegroundColor Yellow
        Write-Host "   Add: EMERGENCY_MED_URL=http://localhost:5000" -ForegroundColor Yellow
    }
} else {
    Write-Host "❌ backend\.env not found" -ForegroundColor Red
}

# Summary
Write-Host ""
Write-Host "=================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "=================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "📝 Next Steps:" -ForegroundColor Yellow
Write-Host ""
Write-Host "1. Start EmergencyMed Service:" -ForegroundColor White
Write-Host "   cd $emergencyMedPath\server" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Start MediLinko Backend:" -ForegroundColor White
Write-Host "   cd C:\Users\SushilSC\MediLinko\backend" -ForegroundColor Gray
Write-Host "   npm start" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Run Flutter App:" -ForegroundColor White
Write-Host "   cd C:\Users\SushilSC\MediLinko" -ForegroundColor Gray
Write-Host "   flutter run" -ForegroundColor Gray
Write-Host ""
Write-Host "📖 Read the integration guide:" -ForegroundColor Yellow
Write-Host "   EMERGENCY_INTEGRATION.md" -ForegroundColor Gray
Write-Host ""
