# 「图片存储优化」设计方案（Image Storage Redesign）

> **状态**：方案评审中（2026-08-23），确认后实施
> **背景**：当前记录图片在 `filesDir/records/` **原样复制**（`ImageFileService.saveRecordImage` 直接 copyFileSync，无压缩），原图动辄数 MB，本地占用大；用户有腾讯云 COS，倾向**云端存原图 + 本地存压缩图 + 查看原图**。
> **配套**：`docs/technical-reference.md`（存储/备份机制）、`docs/refactoring-plan.md`（数据模型改动遵循 C1~C6：只加可选字段 + 默认值）
> **提交**：自动本地提交（3.0.x 递增），推送需明确要求

---

## 1. 目标

1. **本地只存压缩图**（体积降 70~90%），原图不再常驻本地。
2. **原图存云端**（腾讯云 COS 主推；华为云 OBS 同类备选），可随时恢复。
3. **「查看原图」功能**：点击后按需下载原图到缓存目录预览，可清理。
4. **数据兼容 C1~C6**：旧备份无损导入；新字段全部可选 + 默认值；无网/未配置云时功能降级不丢失。

## 2. 方案对比（已核实）

| 方案 | 本地空间 | 原图保留 | 无网可用 | 结论 |
| --- | --- | --- | --- | --- |
| **纯压缩**（本地只存压缩图，原图丢弃） | ✅ 省 | ❌ 不可逆丢失 | ✅ | 不可取（用户明确要保留原图） |
| **纯云存储**（本地不存，全部云端） | ✅ 最省 | ✅ | ❌ 离线全不可用 | 不可取（记录类 App 强依赖本地） |
| **本地压缩 + 云端原图**（推荐） | ✅ 省 | ✅ 可恢复 | ✅ 压缩图本地可用 | **采用** |
| **华为云空间**（消费者云空间） | — | — | — | ❌ **无第三方开发者 API**（仅系统相册/文件可同步，应用无法写入任意文件）；华为云 **OBS** 与腾讯 COS 同类，可作备选（接口风格近 S3，改动成本低） |

## 3. 现状与机制（已核实）

| 层 | 现状 |
| --- | --- |
| 图片保存 | `ImageFileService.saveRecordImage`：原样 `copyFileSync` 到 `filesDir/records/record_{ts}.jpg`，**无压缩**；返回 `file://` URI 存入 `LifeRecord.imagePaths` |
| 数据模型 | `LifeRecord.imagePaths?: string[]`（本地 URI，可选字段） |
| 备份 | `BackupManager`：`metadata.records` 完整 JSON 序列化（含 `imagePaths` URI）+ zip 打包图片文件；**恢复时显式构造记录（只复制 id/timestamp/content/imagePaths/tags/isPinned）**——新字段需在恢复逻辑中透传，否则丢字段 |
| 缓存清理 | `StorageService.cleanupCache`：清 `cacheDir/share_*.jpg` + `filesDir/records` 孤儿图片 |
| 网络权限 | `module.json5` **无 INTERNET 权限**——云存储必须新增 |
| 云配置雏形 | `CloudBackupConfig` 已有（provider: 'huawei' | 'custom'，未用）可扩展；`AppSettings` 可加可选字段 |
| 压缩能力 | HarmonyOS `@kit.ImageKit`（ImageSource/ImagePacker）可同步压缩，无需第三方库 |

## 4. 设计

### 4.1 存储布局（本地 + 云端）

```
本地 filesDir/
  records/record_{ts}.jpg          ← 压缩图（常规显示/备份/离线兜底）
  records/record_{ts}_thumb.jpg    ← 缩略图（可选，列表小图，进一步省 IO，M1 暂不做）
本地 cacheDir/
  original_{recordId}_{idx}.jpg    ← 原图缓存（查看原图时下载，可清理）
云端 COS bucket/
  records/{recordId}/{idx}.jpg     ← 原图（私有读写 + 签名 URL）
```

- **压缩策略**：`ImagePacker` 输出 JPEG quality 0.8 + 最长边限 2048px（显示足够、体积约 200~500KB）。
- **原图上传**：保存记录时原图先复制到 `cacheDir/pending_*`（待上传），随后**异步上传** COS（见 4.4），成功后删 pending、记录 key；失败保留 pending 下次重试。

### 4.2 数据模型（C1~C6 兼容）

```ts
// LifeRecord 新增（可选，缺省 = 无云端原图，行为与旧数据一致）
imageCloudKeys?: string[]   // 与 imagePaths 一一对应的 COS object key（如 'records/{id}/{idx}.jpg'）

// AppSettings 新增（可选；仅本机持久化，不进备份）
cosConfig?: {
  region: string;        // 如 ap-guangzhou
  bucket: string;        // 如 xxx-1250000000
  secretId: string;
  secretKey: string;     // ⚠️ 本地明文存储风险见 §7
  useHttps?: boolean;    // 默认 true
}
```

- 旧备份无这些字段 → 导入后 `undefined`，走纯本地（现有逻辑不变）。
- `CloudBackupConfig.provider` 扩展 `'cos' | 'obs'`（保留 'huawei' 语义兼容）。

### 4.3 云接入（腾讯云 COS）

**无官方 HarmonyOS SDK** → 使用 **COS XML API（REST）+ 自实现签名**（依赖 `@kit.NetworkKit` http 即可，无第三方依赖）：

- 上传：`PUT /{bucket}.cos.{region}.myqcloud.com/records/{id}/{idx}.jpg`（Authorization 签名头，body 为文件 ArrayBuffer）。
- 下载：`GET` 同路径 + 签名参数（或返回**临时签名 URL** 交给 Image 组件加载）。
- 签名算法：COS 签名（SecretId/SecretKey + 时间戳 + keyTime/signKey），纯字符串计算，可单测。
- **密钥方案**：
  - **MVP**：用户在设置页填 SecretId/SecretKey（本地持久化），提示风险。
  - **进阶**：自建服务签发 STS 临时密钥（客户端只存临时密钥 + 定期换），列入后续迭代。

### 4.4 上传流程（含失败重试）

```
保存记录
  ├─ 压缩图 → filesDir/records（立即，本地可用 ✅）
  ├─ 原图 → cacheDir/pending_*
  └─ 若已配置 COS：
       ├─ 上传成功 → 删 pending，LifeRecord.imageCloudKeys 更新（持久化）
       └─ 失败 → pending 保留；下次启动/设置页「重试上传」触发重试
       （无网时静默跳过，不阻塞记录保存）
```

### 4.5 查看原图（UI）

- **ImageViewer 底部工具条**增加「查看原图」按钮（原图未下载时显示；已下载/无云端时隐藏）。
- 点击 → 下载原图到 `cacheDir/original_*` → 用**原图 URI 替换当前页展示**（或全屏独立预览），下载中显示进度 Toast。
- 失败 → Toast 提示并保持压缩图。
- 「清理缓存」新增清理项：`cacheDir/original_*` + `cacheDir/pending_*`。

### 4.6 备份/恢复兼容（关键改动点）

- **导出**：zip 内仍含**压缩图**（imagePaths 本地 URI 照旧），`metadata.records` 序列化时**包含新字段**（imageCloudKeys/cosConfig 之外的全部记录字段——恢复后仍可「查看原图」）。
- **恢复**：`BackupManager.restoreBackup` 的记录构造需**透传** `imageCloudKeys` 等新字段（现显式构造会丢字段——顺手修复 mood 同样问题）。
- 旧备份（无云字段）导入：一切照旧，仅本地压缩图。

## 5. 里程碑拆分

| 里程碑 | 内容 | 依赖 |
| --- | --- | --- |
| **M1 本地压缩** | `ImageFileService.saveRecordImage` 加压缩（ImagePacker）；删除旧原图语义 | 无 |
| **M2 云服务** | `CosService`（签名/上传/下载/删除）+ module.json5 INTERNET 权限 + 设置页 COS 配置（表单 + 连通性测试） | M1 |
| **M3 查看原图** | ImageViewer「查看原图」按钮 + 下载缓存 + 清理缓存扩展 | M1、M2 |
| **M4 健壮性** | 上传队列/重试入口、备份字段透传修复、离线降级回归、单测（签名/压缩/字段兼容） | 全部 |

## 6. 资源（新增 ~8 key，426 → ~434）

- `cloud_storage`（云存储 / Cloud storage）、`cos_region`、`cos_bucket`、`cos_secret_id`、`cos_secret_key`、`cloud_test`（测试连接 / Test connection）、`cloud_test_success`、`cloud_test_failed`、`view_original`（查看原图 / View original）、`original_downloading`（原图下载中… / Downloading…）

## 7. 可行性自评与风险

| 项 | 评估 | 风险/缓解 |
| --- | --- | --- |
| 压缩 | `@kit.ImageKit` 同步压缩，成熟 | 低 |
| COS 接入 | REST + 自实现签名（无官方 SDK） | 中：签名需按 COS 规范实现并单测；华为 OBS 备选（接口近 S3，改动量小） |
| 密钥安全 | SecretKey 本地明文 | **中高**：MVP 接受 + 设置页风险提示；迭代升级 STS 临时密钥（服务端签发） |
| 费用 | COS 存储 ~0.099 元/GB/月；**查看原图走外网下行流量 ~0.5 元/GB** | 中：原图建议低频存储；提示用户流量成本 |
| 后台上传 | HarmonyOS 后台任务受限，上传在前台/短时任务内做，失败进 pending 队列 | 低 |
| 数据兼容 | 全部新字段可选 + 恢复透传 | 低：需回归旧备份导入（§8） |
| 隐私 | 图片为敏感数据，bucket **私有读写** + 签名 URL | 低 |

## 8. 验证清单

- [ ] 旧备份 `RecordLife_all_*.zip` 导入无损（无云字段，纯本地路径全通）
- [ ] 新记录：本地只出现压缩图（体积显著下降）；原图仅云端
- [ ] 未配置 COS / 无网：保存记录正常（压缩图本地），上传静默跳过不阻塞
- [ ] 上传失败：pending 保留，重试入口生效
- [ ] 查看原图：分辨率=原图；下载失败降级压缩图
- [ ] 清理缓存：original_*/pending_* 被清理
- [ ] 备份导出含 imageCloudKeys；导入后「查看原图」仍可用（key 透传）
- [ ] 中英文资源齐全；权限弹窗文案合规
- [ ] 单测：COS 签名（固定输入黄金向量）、压缩尺寸/体积断言、字段兼容（无云字段记录往返）

---

## 9. 待确认事项（评审）

1. **首选厂商**：腾讯云 COS（已有账号）还是华为云 OBS（生态一致）？（COS 优先，方案按 COS 写，OBS 备选）
2. **密钥方案**：接受 MVP 本地明文（设置页填写），还是先做自建 STS 服务？（建议先 MVP）
3. **压缩参数**：2048px + quality 0.8 是否接受（或按 1080px 更省）？
4. **查看原图形态**：ImageViewer 内替换显示 vs 独立全屏页？（建议前者，改动小）
