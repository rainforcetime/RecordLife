# HAP 签名助手（方案 B：unsigned 包 + 单独签名，release/debug 通用）
# 用途：上架前用 release 证书给 unsigned HAP 签名；也可给 debug unsigned 包签 debug 证书。
#
# 用法一（命令行全参）：
#   powershell -File scripts/sign-hap.ps1 `
#     -InFile "…unsigned.hap" -OutFile "RecordLife_V3.0.90_release.hap" `
#     -Keystore "证书.p12" `
#     -KeyAlias "recordlife_key" `
#     -Cert "证书.cer" -Profile "profile.p7b" `
#     -StorePwd "p12密码" -KeyPwd "别名密码"
#
# 用法二（推荐，一键）：release 材料存本地配置文件（已 gitignore，含密码不提交）
#   1) 首次：复制下面 JSON 到仓库根 release-config.local.json 并填真实值
#   2) 之后每次上架只需：
#        powershell -File scripts/sign-hap.ps1 -Config release-config.local.json `
#          -InFile "…unsigned.hap" -OutFile "RecordLife_V3.0.90_release.hap"
#   release-config.local.json 示例：
#   {
#     "keystore": "<p12 路径>",
#     "storePwd": "p12密码（或用 HOS_STORE_PWD 环境变量留空）",
#     "keyAlias": "recordlife_key",
#     "keyPwd": "别名密码（或用 HOS_KEY_PWD 环境变量留空）",
#     "cert": "<cer 路径>",
#     "profile": "<p7b 路径>"
#   }
# 密码优先级：命令行参数 > 配置文件 > 环境变量 HOS_STORE_PWD / HOS_KEY_PWD。
param(
  [string]$Config,          # 本地 release 配置 JSON（gitignore），可替代证书路径/密码参数
  [string]$InFile,          # 输入 unsigned HAP
  [string]$OutFile,         # 输出 signed HAP
  [string]$Keystore,        # .p12
  [string]$StorePwd,        # p12 密码（或 HOS_STORE_PWD）
  [string]$KeyAlias,        # 别名（如 recordlife_key）
  [string]$KeyPwd,          # 别名密码（或 HOS_KEY_PWD）
  [string]$Cert,            # .cer
  [string]$Profile,         # .p7b
  [string]$ToolJar = "D:\Software\DevEco Studio\sdk\default\openharmony\toolchains\lib\hap-sign-tool.jar"
)

$ErrorActionPreference = 'Stop'

# 1) 从本地配置文件补缺省（证书路径/别名/密码），再补环境变量
if ($Config) {
  if (-not (Test-Path $Config)) { Write-Error "找不到配置文件: $Config" }
  $cfg = Get-Content $Config -Raw | ConvertFrom-Json
  if (-not $Keystore) { $Keystore = $cfg.keystore }
  if (-not $KeyAlias) { $KeyAlias = $cfg.keyAlias }
  if (-not $Cert) { $Cert = $cfg.cert }
  if (-not $Profile) { $Profile = $cfg.profile }
  if (-not $StorePwd) { $StorePwd = $cfg.storePwd }
  if (-not $KeyPwd) { $KeyPwd = $cfg.keyPwd }
}
if (-not $StorePwd) { $StorePwd = $env:HOS_STORE_PWD }
if (-not $KeyPwd) { $KeyPwd = $env:HOS_KEY_PWD }

if (-not $InFile -or -not $OutFile -or -not $Keystore -or -not $KeyAlias -or -not $Cert -or -not $Profile -or -not $StorePwd -or -not $KeyPwd) {
  Write-Host '缺少参数。用法见文件头部注释（可用 -Config 指定本地配置文件）。' -ForegroundColor Yellow
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
