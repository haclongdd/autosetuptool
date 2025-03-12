param ([string]$taskId)

# Đảm bảo script chạy với quyền Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "Dang khoi dong lai script voi quyen Administrator..." -ForegroundColor Yellow
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $taskId"
    Start-Process powershell -Verb RunAs -ArgumentList $arguments
    exit
}

# Các hàm từ script gốc của bạn
function Install-PiNetwork {
    $piInstaller = "$env:TEMP\Pi_Network_Setup.exe"
    $url = "https://downloads.minepi.com/Pi%20Network%20Setup%200.5.0.exe"
    
    Write-Host "`n[PiNetwork] Dang tai xuong tu: $url" -ForegroundColor Green
    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($url, $piInstaller)
        Write-Host "[PiNetwork] Tai xuong hoan tat: $piInstaller" -ForegroundColor Green
        Write-Host "[PiNetwork] Bat dau cai dat..."
        Start-Process -FilePath $piInstaller -Wait
        Write-Host "[PiNetwork] Cai dat hoan tat!" -ForegroundColor Green
    }
    catch {
        Write-Host "[PiNetwork] Loi khi tai xuong hoac cai dat: $($_)" -ForegroundColor Red
    }
}

function Update-WSL2 {
    Write-Host "`n[WSL2] Dang cap nhat WSL2..." -ForegroundColor Green
    try {
        wsl --update
        Write-Host "[WSL2] Cap nhat WSL2 thanh cong!" -ForegroundColor Green
    }
    catch {
        Write-Host "[WSL2] Loi khi cap nhat WSL2: $($_)" -ForegroundColor Red
    }
}

function Install-Docker {
    Write-Host "`n[Docker] Dang tai va cai dat Docker Desktop..."
    $dockerInstaller = "$env:TEMP\DockerDesktopInstaller.exe"
    $dockerURL = "https://desktop.docker.com/win/main/amd64/Docker%20Desktop%20Installer.exe"
    $webClient = New-Object System.Net.WebClient
    try {
        $webClient.DownloadFile($dockerURL, $dockerInstaller)
        Write-Host "[Docker] Tai xuong hoan tat: $dockerInstaller" -ForegroundColor Green
        Write-Host "[Docker] Bat dau cai dat Docker Desktop..." -ForegroundColor Green
        Start-Process -FilePath $dockerInstaller -Wait
        Write-Host "[Docker] Cai dat Docker Desktop hoan tat!" -ForegroundColor Green
    }
    catch {
        Write-Host "[Docker] Loi khi tai xuong hoac cai dat: $($_)" -ForegroundColor Red
    }
}

function Configure-Firewall {
    Write-Host "`n[Firewall] Dang cau hinh Firewall (Inbound Rule) mo cong 31400-31409..."
    try {
        New-NetFirewallRule -DisplayName "Allow MyApp Inbound" -Direction Inbound -Action Allow -Protocol TCP -LocalPort 31400-31409 -Profile Any
        Write-Host "[Firewall] Cau hinh Firewall hoan tat (Inbound)!" -ForegroundColor Green
    }
    catch {
        Write-Host "[Firewall] Loi khi cau hinh Firewall: $($_)" -ForegroundColor Red
    }
}

function Set-PrivateNetwork {
    Write-Host "`n[Network] Dang chuyen doi cau hinh mang sang Private..."
    try {
        $networks = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Public" }
        foreach ($net in $networks) {
            Set-NetConnectionProfile -InterfaceAlias $net.InterfaceAlias -NetworkCategory Private
            Write-Host "[Network] Da chuyen $($net.InterfaceAlias) sang Private." -ForegroundColor Green
        }
        if ($networks.Count -eq 0) {
            Write-Host "[Network] Khong co ket noi Public nao can chuyen." -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "[Network] Loi khi chuyen doi cau hinh mang: $($_)" -ForegroundColor Red
    }
}

function Enable-WindowsUpdate {
    Write-Host "`n[WindowsUpdate] Dang bat Windows Update va cau hinh tu dong cap nhat..."
    try {
        Set-Service -Name wuauserv -StartupType Automatic
        Start-Service -Name wuauserv
        Write-Host "[WindowsUpdate] Windows Update da duoc bat va cau hinh tu dong cap nhat." -ForegroundColor Green
    }
    catch {
        Write-Host "[WindowsUpdate] Loi khi cau hinh Windows Update: $($_)" -ForegroundColor Red
    }
}

function Set-HighPerformance {
    Write-Host "`n[PowerOption] Dang chuyen sang High Performance (turn off hard disk after = never)..."
    try {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Host "[PowerOption] Da chuyen sang High Performance." -ForegroundColor Green
        
        powercfg -x -disk-timeout-ac 0
        powercfg -x -disk-timeout-dc 0
        Write-Host "[PowerOption] Turn off hard disk after = never (AC/DC)!" -ForegroundColor Green
    }
    catch {
        Write-Host "[PowerOption] Loi khi chuyen sang High Performance: $($_)" -ForegroundColor Red
    }
}

function Clean-System {
    Write-Host "`n[CleanSystem] Dang don dep he thong Windows va o C..."
    try {
        Write-Host "[CleanSystem] Dang xoa file tam trong %TEMP%..."
        Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
        
        Write-Host "[CleanSystem] Dang xoa Recycle Bin..."
        Clear-RecycleBin -Force -Confirm:$false
        
        Write-Host "[CleanSystem] Dang chay DISM StartComponentCleanup..."
        Start-Process powershell -ArgumentList "-Command DISM.exe /Online /Cleanup-Image /StartComponentCleanup /NoRestart" -Verb RunAs -Wait
        
        Write-Host "[CleanSystem] Don dep hoan tat!" -ForegroundColor Green
    }
    catch {
        Write-Host "[CleanSystem] Loi khi don dep: $($_)" -ForegroundColor Red
    }
}

# Chạy tác vụ dựa trên taskId
switch ($taskId) {
    "1" { Install-PiNetwork }
    "5" { Update-WSL2 }
    "6" { Install-Docker }
    "7" { Configure-Firewall }
    "8" { Set-PrivateNetwork }
    "9" { Enable-WindowsUpdate }
    "10" { Set-HighPerformance }
    "11" { Clean-System }
    default { Write-Host "Task ID khong hop le: $taskId" }
}