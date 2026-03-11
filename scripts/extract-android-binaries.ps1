# Android Termux 构建脚本 (PowerShell)
# 使用方法: .\scripts\build-termux.ps1

$ImageName = "openfang-termux"
$ContainerName = "openfang-termux-builder"

Write-Host "==> 构建 Docker 镜像..." -ForegroundColor Green
docker build -f Dockerfile.termux -t $ImageName .

Write-Host "==> 创建容器并编译..." -ForegroundColor Green
docker create --name $ContainerName $ImageName

Write-Host "==> 复制编译产物..." -ForegroundColor Green
docker cp "$ContainerName`:/output/openfang" "./target/openfang-termux"

Write-Host "==> 清理容器..." -ForegroundColor Green
docker rm $ContainerName

Write-Host "==> 打包..." -ForegroundColor Green
Compress-Archive -Path "./target/openfang-termux" -DestinationPath "./target/openfang-aarch64-linux-android.tar.gz" -Force

Write-Host "==> 完成!" -ForegroundColor Green
Write-Host "输出文件: target\openfang-aarch64-linux-android.tar.gz" -ForegroundColor Cyan
Write-Host ""
Write-Host "在 Termux 中安装:" -ForegroundColor Yellow
Write-Host "   apt install openssl" -ForegroundColor White
Write-Host "   tar xzf openfang-aarch64-linux-android.tar.gz" -ForegroundColor White
Write-Host "   ./openfang-termux" -ForegroundColor White
