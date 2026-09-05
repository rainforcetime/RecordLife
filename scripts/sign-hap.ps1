# HAP 签名助手（方案 B：unsigned 包 + 单独签名，release/debug 通用）
# 用途：上架前用 release 证书给 unsigned HAP 签名；也可给 debug unsigned 包签 debug 证书。
# 用法示例（release）：
#   powershell -File scripts/sign-hap.ps1 `
#     -InFile "entry/build/default/outputs/default/entry-default-release-unsigned.hap" `
#     -OutFile "RecordLife_V3.0.90_release.hap" `
#     -Keystore "证书.p12" `
#     -StorePwd "你的 p12 密码" -KeyPwd "你的别名密码" `
#     -KeyAlias "recordlife_key" `
#     -Cert "证书.cer" `
#     -Profile "profile.p7b"
# 密码也可用环境变量 HOS_STORE_PWD / HOS_KEY_PWD 传入（避免出现在命令行历史）。
param(
  [string]$InFile,          # 输入 unsigned HAP
  [string]$OutFile,         # 输出 signed HAP
  [string]$Keystore,        # .p12
  [string]$StorePwd,        # p12 密码（或环境变量 HOS_STORE_PWD）
  [string]$KeyAlias,        # 别名（如 recordlife_key）
  [string]$KeyPwd,          # 别名密码（或环境变量 HOS_KEY_PWD）
  [string]$Cert,            # .cer
  [string]$Profile,         # .p7b
  [string]$ToolJar = "D:\Software\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
)

$ErrorActionPreference = 'Stop'
if (-not $StorePwd) { $StorePwd = $env:HOS_STORE_PWD }
if (-not $KeyPwd) { $KeyPwd = $env:HOS_KEY_PWD }

if (-not $InFile -or -not $OutFile -or -not $Keystore -or -not $KeyAlias -or -not $Cert -or -not $Profile -or -not $StorePwd -or -not $KeyPwd) {
  Write-Host '缺少参数。用法见文件头部注释。' -ForegroundColor Yellow
  exit 2
}

if (-not (Test-Path $ToolJar)) { Write-Error "找不到 hap-sign-tool: $ToolJar" }
if (-not (Test-Path $InFile)) { Write-Error "找不到输入 HAP: $InFile" }

Write-Host "签名中: $InFile -> $OutFile"
java -jar $ToolJar sign-app `
  -keyAlias $KeyAlias `
  -signAlg "SHA256withECDSA" `
  -mode "localSign" `
  -appCertFile $Cert `
  -profileFile $Profile `
  -inFile $InFile `
  -keystoreFile $Keystore `
  -outFile $OutFile `
  -keyPwd $KeyPwd `
  -keystorePwd $StorePwd `
  -signCode "1"
if ($LASTEXITCODE -eq 0) {
  Write-Host "签名成功: $OutFile" -ForegroundColor Green
} else {
  Write-Host "签名失败（exit=$LASTEXITCODE）" -ForegroundColor Red
}
exit $LASTEXITCODE
