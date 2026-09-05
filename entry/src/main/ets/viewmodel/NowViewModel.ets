// NowPage 业务逻辑类：viewmodel/NowViewModel.ets
import { common } from '@kit.AbilityKit'
import { fileIo } from '@kit.CoreFileKit'
import { ResourceUtils } from '../common/utils/ResourceUtils'
import { LifeRecord, TimelineData, buildTimelineData } from '../common/types'
import { TimeUtils } from '../common/utils/TimeUtils'
import { ImageGenerator } from '../common/utils/ImageGenerator'
import { RecordRepository } from '../repository/RecordRepository'
import { ImageFileService } from '../service/ImageFileService'
import { CosService } from '../service/CosService'
import { ConfigManager } from '../config/ConfigManager'
import { ImagePathUtils } from '../common/utils/ImagePathUtils'
import { Logger } from '../common/utils/Logger'

// 待上传原图项（图片存储优化 M3）
interface PendingUpload {
  uri: string          // 压缩图 URI（用于匹配记录 imagePaths）
  pendingPath: string  // 原图待上传缓存路径
}

// 上传全部图片结果（图片存储优化）
interface UploadAllResult {
  uploaded: number     // 成功张数
  failed: number       // 失败张数
  skipped: number      // 去重跳过张数（云端已有）
}

// 生活记录数据管理类
export class NowViewModel {
  private static instance: NowViewModel | null = null
  private context: common.UIAbilityContext | null = null
  
  // 记录数据
  private records: LifeRecord[] = []

  // 待上传原图队列（图片存储优化 M3：本地压缩 + 云端原图）
  private pendingUploads: PendingUpload[] = []
  
  private constructor() {}
  
  // 获取单例实例（支持显式注入 context，A5；未传时回退 AppStorage）
  static async getInstance(context?: common.UIAbilityContext): Promise<NowViewModel> {
    if (!NowViewModel.instance) {
      NowViewModel.instance = new NowViewModel()
      await NowViewModel.instance.init(context)
    } else if (context && !NowViewModel.instance.context) {
      await NowViewModel.instance.init(context)
    }
    return NowViewModel.instance
  }
  
  // 初始化（context 显式注入优先，否则回退 AppStorage）
  private async init(context?: common.UIAbilityContext): Promise<void> {
    Logger.info('[NowViewModel] init 开始')
    
    // 最多重试3次，每次间隔100ms
    for (let retry = 0; retry < 3; retry++) {
      try {
        // 获取上下文（注入优先，A5）
        let uiContext = context
        if (!uiContext) {
          uiContext = AppStorage.get('uiContext') as common.UIAbilityContext
        }
        if (!uiContext) {
          uiContext = AppStorage.get('context') as common.UIAbilityContext
        }
        
        if (!uiContext) {
          Logger.warn(`[NowViewModel] uiContext 不存在，重试 ${retry + 1}/3`)
          if (retry < 2) {
            await new Promise<void>(resolve => setTimeout(resolve, 100))
            continue
          }
          Logger.error('[NowViewModel] uiContext 获取失败，初始化终止')
          return
        }
        
        this.context = uiContext
        
        // 加载记录
        await this.loadRecords()
        Logger.info('[NowViewModel] 记录加载完成，数量: ' + this.records.length)
        return // 初始化成功，退出
      } catch (error) {
        Logger.error('[NowViewModel] init 失败: ' + JSON.stringify(error))
        if (retry < 2) {
          await new Promise<void>(resolve => setTimeout(resolve, 100))
        }
      }
    }
  }
  
  // 加载记录
  private async loadRecords(): Promise<void> {
    if (!this.context) {
      this.records = []
      return
    }
    
    try {
      const records = await RecordRepository.getRecords(this.context)
      if (records.length > 0) {
        this.records = records
        // 按时间戳降序排序（最新的在前）
        this.records.sort((a, b) => b.timestamp - a.timestamp)
      } else {
        this.records = []
        // 仅「未初始化过示例」时生成示例（首次安装 / 重置后标记被清除）；
        // 用户手动删光记录后不再重复生成（标记已置位）
        const sampleInitialized = await RecordRepository.isSampleDataInitialized(this.context)
        if (!sampleInitialized) {
          await this.initSampleData()
          await RecordRepository.markSampleDataInitialized(this.context)
        }
      }
    } catch (error) {
      Logger.error('[NowViewModel] 加载记录失败: ' + JSON.stringify(error))
      this.records = []
    }
  }
  
  // 初始化示例数据
  private async initSampleData(): Promise<void> {
    Logger.info('[NowViewModel] 初始化示例数据')
    
    if (!this.context) {
      Logger.error('[NowViewModel] context 未初始化，无法生成示例图片')
      return
    }
    
    const now = Date.now()
    const oneDayMs = 24 * 60 * 60 * 1000
    
    // 生成示例图片（纯色渐变）
    let sampleImagePath: string | null = null
    try {
      // 生成一张渐变色图片（蓝色到紫色渐变）
      sampleImagePath = await ImageGenerator.generateGradientImage(
        this.context,
        800,  // 宽度
        600,  // 高度
        0xFF4A90E2,  // 起始颜色：蓝色
        0xFF9B59B6,  // 结束颜色：紫色
        'sample_gradient.png'
      )
      
      if (sampleImagePath) {
        Logger.info('[NowViewModel] 示例图片生成成功: ' + sampleImagePath)
      } else {
        Logger.warn('[NowViewModel] 示例图片生成失败')
      }
    } catch (error) {
      Logger.error('[NowViewModel] 生成示例图片异常: ' + JSON.stringify(error))
    }
    
    const rm = this.context?.resourceManager
    const sampleRecords: LifeRecord[] = [
      {
        id: this.generateId(),
        timestamp: now,
        content: ResourceUtils.getString(rm, 'sample_record_1'),
        tags: ['life', 'entertainment']
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs,
        content: ResourceUtils.getString(rm, 'sample_record_2'),
        tags: ['life', 'study'],
        imagePaths: sampleImagePath ? [sampleImagePath] : undefined  // 添加示例图片
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 3,
        content: ResourceUtils.getString(rm, 'sample_record_3'),
        tags: ['travel', 'food'],
        imagePaths: sampleImagePath ? [sampleImagePath,sampleImagePath,sampleImagePath,sampleImagePath] : undefined  // 添加示例图片
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 35,
        content: ResourceUtils.getString(rm, 'sample_record_4'),
        tags: ['work', 'health']
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 365,
        content: ResourceUtils.getString(rm, 'sample_record_5'),
        tags: ['family']
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 365 * 2,
        content: ResourceUtils.getString(rm, 'sample_record_6'),
        tags: ['life']
      }
    ]
    
    this.records = sampleRecords
    await this.saveRecords()
    Logger.info('[NowViewModel] 示例数据初始化完成')
  }
  
  // 保存记录
  private async saveRecords(): Promise<boolean> {
    // 如果 prefs 未初始化，尝试重新初始化
    if (!this.context) {
      Logger.warn('[NowViewModel] context 未初始化，尝试重新初始化')
      await this.init()
    }
    
    if (!this.context) {
      Logger.error('[NowViewModel] context 仍然未初始化，保存失败')
      return false
    }
    
    try {
      const success = await RecordRepository.saveRecords(this.context, this.records)
      if (success) {
        Logger.info('[NowViewModel] 记录保存成功，数量: ' + this.records.length)
      }
      return success
    } catch (error) {
      Logger.error('[NowViewModel] 保存记录失败: ' + JSON.stringify(error))
      return false
    }
  }
  
  // 获取所有记录
  getRecords(): LifeRecord[] {
    return this.records
  }
  
  // 添加记录
  async addRecord(content: string, imagePaths?: string[], tags?: string[], mood?: string): Promise<LifeRecord | null> {
    const record: LifeRecord = {
      id: this.generateId(),
      timestamp: Date.now(),
      content: content,
      imagePaths: imagePaths,
      tags: tags,
      mood: mood
    }
    
    this.records.unshift(record) // 添加到开头
    const success = await this.saveRecords()

    if (success) {
      // 图片存储优化 M3：记录保存成功后上传原图到云端（未配置 COS 自动跳过）
      await this.uploadPendingImages()
      return record
    } else {
      // 保存失败，移除添加的记录
      this.records.shift()
      return null
    }
  }
  
  // 更新记录
  async updateRecord(id: string, content: string, imagePaths?: string[], tags?: string[], mood?: string): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === id)
    if (index === -1) {
      Logger.error('[NowViewModel] 未找到记录: ' + id)
      return false
    }
    
    const record = this.records[index]

    // 计算各字段是否有实际变化（复查 P2-2：避免无改动保存误标「已编辑」）
    const contentChanged = record.content !== content
    const moodChanged = mood !== undefined &&
      (mood.length > 0 ? mood : undefined) !== record.mood
    const tagsChanged = tags !== undefined && !this.sameStringArray(record.tags, tags)
    const imagesChanged = imagePaths !== undefined && !this.sameStringArray(record.imagePaths, imagePaths)

    // 记录最后修改时间：仅实际有修改时更新（需求2）
    if (contentChanged || moodChanged || tagsChanged || imagesChanged) {
      record.updatedAt = Date.now()
    }

    // 更新文字内容
    record.content = content
    
    // 更新心情（可选字段，更新计划二期；'' 表示清除）
    if (mood !== undefined) {
      record.mood = mood.length > 0 ? mood : undefined
    }
    
    // 更新标签
    if (tags !== undefined) {
      record.tags = tags.length > 0 ? tags : undefined
    }
    
    // 处理图片路径更新
    if (imagePaths !== undefined) {
      // 收集被移除图片的云端 key（供删除云端旧图，图片存储优化）
      const oldPaths = record.imagePaths ? record.imagePaths : []
      const oldKeys = record.imageCloudKeys ? record.imageCloudKeys : []
      const removedCloudKeys: string[] = []
      for (let i = 0; i < oldPaths.length; i++) {
        if (!imagePaths.includes(oldPaths[i]) && i < oldKeys.length && oldKeys[i]) {
          removedCloudKeys.push(oldKeys[i])
        }
      }

      // 删除不再使用的本地图片文件
      const pathsToDelete: string[] = oldPaths.filter(oldPath => !imagePaths.includes(oldPath))
      if (pathsToDelete.length > 0) {
        const ctx = this.context
        if (ctx) {
          ImageFileService.deleteImageFiles(ctx, pathsToDelete)
        }
      }
      
      // 同步云端 key：旧图沿用原 key，新图留空待上传
      const newKeys: string[] = []
      for (const newPath of imagePaths) {
        const oldIdx = oldPaths.indexOf(newPath)
        if (oldIdx >= 0 && oldIdx < oldKeys.length && oldKeys[oldIdx]) {
          newKeys.push(oldKeys[oldIdx])
        } else {
          newKeys.push('')
        }
      }
      
      // 更新图片路径列表
      if (imagePaths.length === 0) {
        record.imagePaths = undefined
        record.imageCloudKeys = undefined
      } else {
        record.imagePaths = imagePaths
        record.imageCloudKeys = newKeys
      }
      
      // 保存成功后删除云端旧图
      const success = await this.saveRecords()
      if (success) {
        await this.uploadPendingImages()
        if (removedCloudKeys.length > 0) {
          const ctx = this.context
          if (ctx) {
            await NowViewModel.deleteCloudImages(ctx, removedCloudKeys)
          }
        }
      }
      return success
    }
    
    const success = await this.saveRecords()
    if (success) {
      // 图片存储优化：修改记录后上传新图（原图入待上传队列）
      await this.uploadPendingImages()
    }
    return success
  }

  // 按 id 获取记录（供评论面板等同步最新数据）
  getRecordById(id: string): LifeRecord | null {
    const found = this.records.find(r => r.id === id)
    return found ? found : null
  }

  // 字符串数组是否相同（undefined 视为空数组；复查 P2-2 用）
  private sameStringArray(a: string[] | undefined, b: string[]): boolean {
    const x = a ? a : []
    return x.length === b.length && x.every((v, i) => v === b[i])
  }

  // 添加追加想法（评论，需求3；内容去空校验下沉，防 UI 外绕过）
  async addComment(recordId: string, content: string): Promise<boolean> {
    const trimmed = content.trim()
    if (!trimmed) {
      return false
    }
    const index = this.records.findIndex(r => r.id === recordId)
    if (index === -1) {
      Logger.error('[NowViewModel] addComment: 未找到记录: ' + recordId)
      return false
    }
    const record = this.records[index]
    if (!record.comments) {
      record.comments = []
    }
    record.comments.push({
      id: this.generateId(),
      content: trimmed,
      timestamp: Date.now()
    })
    const success = await this.saveRecords()
    if (success) {
      Logger.info('[NowViewModel] 追加想法成功，记录: ' + recordId)
    }
    return success
  }

  // 删除追加想法（评论，需求3）
  async deleteComment(recordId: string, commentId: string): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === recordId)
    if (index === -1) {
      Logger.error('[NowViewModel] deleteComment: 未找到记录: ' + recordId)
      return false
    }
    const record = this.records[index]
    if (!record.comments) {
      return false
    }
    const cIdx = record.comments.findIndex(c => c.id === commentId)
    if (cIdx === -1) {
      return false
    }
    record.comments.splice(cIdx, 1)
    if (record.comments.length === 0) {
      record.comments = undefined
    }
    return await this.saveRecords()
  }
  
  // 切换收藏/置顶状态
  async togglePin(id: string): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === id)
    if (index === -1) {
      Logger.error('[NowViewModel] 未找到记录: ' + id)
      return false
    }

    const record = this.records[index]
    record.isPinned = !record.isPinned
    Logger.info('[NowViewModel] 记录' + id + ' 收藏状态切换为: ' + record.isPinned)

    return await this.saveRecords()
  }

  // 获取所有收藏的记录
  getPinnedRecords(): LifeRecord[] {
    return this.records.filter(r => r.isPinned === true)
  }

  // ==================== 撤销删除（更新计划二期） ====================

  // 待撤销的已删除记录（内存暂存，不落盘；3 秒窗口内可撤销，超时清理图片）
  private pendingDeletedRecords: LifeRecord[] = []
  private pendingDeleteTimer: number = -1

  // 删除记录（立即持久化删除；3 秒内可撤销；图片文件延迟到撤销窗口结束后清理）
  async deleteRecord(id: string): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === id)
    if (index === -1) {
      Logger.error('[NowViewModel] 未找到记录: ' + id)
      return false
    }

    const record = this.records[index]
    this.records.splice(index, 1)
    this.pendingDeletedRecords.push(record)
    const success = await this.saveRecords()

    if (!success) {
      // 保存失败，回滚
      this.records.splice(index, 0, record)
      this.pendingDeletedRecords.pop()
      return false
    }

    // 重置 3 秒撤销窗口：到期后清理图片文件
    this.resetPendingDeleteTimer()
    return true
  }

  // 撤销删除（3 秒窗口内；恢复暂存记录并持久化）
  async undoDelete(): Promise<boolean> {
    if (this.pendingDeletedRecords.length === 0) {
      return false
    }
    // 取消图片清理计时
    if (this.pendingDeleteTimer !== -1) {
      clearTimeout(this.pendingDeleteTimer)
      this.pendingDeleteTimer = -1
    }
    const restored = this.pendingDeletedRecords
    this.pendingDeletedRecords = []
    this.records = [...this.records, ...restored]
    // 按时间戳降序排序（与加载逻辑一致）
    this.records.sort((a, b) => b.timestamp - a.timestamp)
    return await this.saveRecords()
  }

  // 是否有待撤销的删除（供 UI 判断）
  canUndoDelete(): boolean {
    return this.pendingDeletedRecords.length > 0
  }

  // 重置撤销窗口计时（3 秒后清理暂存记录的图片文件）
  private resetPendingDeleteTimer() {
    if (this.pendingDeleteTimer !== -1) {
      clearTimeout(this.pendingDeleteTimer)
    }
    this.pendingDeleteTimer = setTimeout(() => {
      this.pendingDeleteTimer = -1
      if (this.pendingDeletedRecords.length === 0) {
        return
      }
      const records = this.pendingDeletedRecords
      this.pendingDeletedRecords = []
      // 撤销窗口结束，真正清理图片文件 + 云端原图（图片存储优化）
      const ctx = this.context
      if (ctx) {
        const cloudKeys: string[] = []
        for (const r of records) {
          if (r.imagePaths && r.imagePaths.length > 0) {
            ImageFileService.deleteImageFiles(ctx, r.imagePaths)
          }
          if (r.imageCloudKeys) {
            for (const k of r.imageCloudKeys) {
              if (k) {
                cloudKeys.push(k)
              }
            }
          }
        }
        if (cloudKeys.length > 0) {
          NowViewModel.deleteCloudImages(ctx, cloudKeys)
        }
      }
      Logger.info('[NowViewModel] 撤销窗口结束，已清理 ' + records.length + ' 条记录的图片文件')
    }, 3000)
  }

  // 构建时间线数据（纯函数已下沉至 model/RecordModel.buildTimelineData，P4，可单测）
  buildTimeline(): TimelineData {
    return buildTimelineData(this.records, TimeUtils.now())
  }
  
  // 保存图片到沙箱目录（返回 URI 格式）
  // 图片 IO 已下沉至 service/ImageFileService（P3）；图片存储优化 M3：压缩图入本地 + 原图入待上传队列
  async saveImageToSandbox(sourceUri: string): Promise<string | null> {
    if (!this.context) {
      Logger.error('[NowViewModel] context 未初始化')
      return null
    }
    // 同一 timestamp 生成压缩图与原图，保证文件名对应（record_{ts}.jpg ↔ record_{ts}_orig.jpg）
    const ts = Date.now()
    // 压缩档位（云存储配置，未配置用默认均衡）
    const configManager = await ConfigManager.getInstance(this.context)
    const cos = configManager.getCosConfig()
    const compressMode = cos && cos.compressMode ? cos.compressMode : ImageFileService.COMPRESS_BALANCED
    const uri = await ImageFileService.saveRecordImage(this.context, sourceUri, ts, compressMode)
    if (uri) {
      const pendingPath = await ImageFileService.saveOriginalPending(this.context, sourceUri, ts)
      if (pendingPath) {
        this.pendingUploads.push({ uri: uri, pendingPath: pendingPath })
      }
    }
    return uri
  }

  // 删除云端对象（图片存储优化：修改记录/删除记录后清理云端旧图；未配置 COS 时跳过）
  private static async deleteCloudImages(context: common.UIAbilityContext, keys: string[]): Promise<void> {
    try {
      const configManager = await ConfigManager.getInstance(context)
      const cos = configManager.getCosConfig()
      // 未配置或总开关关闭：跳过云端删除
      if (!cos || cos.enabled === false) {
        return
      }
      for (const key of keys) {
        await CosService.deleteObject(cos, key)
      }
    } catch (error) {
      Logger.error('[NowViewModel] 删除云端图片失败: ' + JSON.stringify(error))
    }
  }

  // 生成可读云端 key：records/{YYYY-MM-DD}/{原名}_{idx}.jpg（原名如 record_1724420000000）
  private static buildCloudKey(record: LifeRecord, index: number): string {
    const date = TimeUtils.formatDate(new Date(record.timestamp))
    let base = `record_${record.timestamp}`
    if (record.imagePaths && record.imagePaths[index]) {
      const name = record.imagePaths[index].split('/').pop()
      if (name) {
        base = name.replace(/\.(jpg|jpeg|png)$/i, '')
      }
    }
    return `records/${date}/${base}_${index}.jpg`
  }

  // 上传待传原图（图片存储优化 M3；未配置 COS 时清理 pending，本地仅压缩图）
  private async uploadPendingImages(): Promise<void> {
    if (!this.context || this.pendingUploads.length === 0) {
      this.pendingUploads = []
      return
    }
    const configManager = await ConfigManager.getInstance(this.context)
    const cos = configManager.getCosConfig()
    const items = this.pendingUploads
    this.pendingUploads = []
    // 未配置或总开关关闭：清理 pending 原图，本地仅压缩图
    if (!cos || cos.enabled === false) {
      // 未配置云存储：清理 pending 原图
      for (const item of items) {
        NowViewModel.deletePendingFile(item.pendingPath)
      }
      return
    }
    let changed = false
    for (const item of items) {
      let matched = false
      for (const record of this.records) {
        if (!record.imagePaths) {
          continue
        }
        const idx = record.imagePaths.indexOf(item.uri)
        if (idx < 0) {
          continue
        }
        matched = true
        const key = NowViewModel.buildCloudKey(record, idx)
        const ok = await CosService.uploadFile(cos, key, item.pendingPath)
        if (ok) {
          // 上传成功：开关开启才删除 pending 原图（与「上传全部」一致；关闭则本地保留双保险）
          if (cos.deleteOriginalAfterUpload !== false) {
            NowViewModel.deletePendingFile(item.pendingPath)
          }
          if (!record.imageCloudKeys) {
            record.imageCloudKeys = []
          }
          while (record.imageCloudKeys.length <= idx) {
            record.imageCloudKeys.push('')
          }
          record.imageCloudKeys[idx] = key
          changed = true
        }
        // 上传失败：保留 pending 文件，供「上传全部图片」重试
        break
      }
      if (!matched) {
        // 记录已不存在（如删除后）：清理 pending 文件防堆积
        NowViewModel.deletePendingFile(item.pendingPath)
      }
    }
    if (changed) {
      await this.saveRecords()
    }
  }

  /**
   * 上传全部本地图片到云端（图片存储优化：历史图片补传 / 失败重试）
   * 逻辑：遍历所有记录图片（无论本地是否有云端 key）：
   *   1) 去重开启：一律 HEAD 检查云端——已存在则跳过（省流量）；不存在则上传（补回被删的云端对象）
   *   2) 去重关闭：本地已有云端 key 的直接跳过，无 key 的上传
   *   上传源：优先 cacheDir/pending 原图，无则兜底本地记录图片
   * @param onProgress 进度回调（已处理数 / 总数）
   * @returns 上传结果（成功数 / 失败数 / 跳过数）
   */
  static async uploadAllImages(context: common.UIAbilityContext,
    onProgress?: (current: number, total: number) => void): Promise<UploadAllResult> {
    const configManager = await ConfigManager.getInstance(context)
    const cos = configManager.getCosConfig()
    const result: UploadAllResult = { uploaded: 0, failed: 0, skipped: 0 }
    // 未配置或总开关关闭：不执行上传
    if (!cos || cos.enabled === false) {
      return result
    }
    // 去重开关（默认开：云端已有对象则不重复上传，省流量；云端被删时会补传）
    const dedupe = cos.dedupeUpload !== false
    const records = await RecordRepository.getRecords(context)
    // 预统计待处理总数（本地有文件源的图片，无论是否有云端 key）
    let total = 0
    for (const record of records) {
      if (!record.imagePaths) {
        continue
      }
      for (let i = 0; i < record.imagePaths.length; i++) {
        const name = record.imagePaths[i].split('/').pop()
        if (!name) {
          continue
        }
        const origPath = `${context.cacheDir}/pending/${name.replace(/\.(jpg|jpeg|png)$/i, '_orig.jpg')}`
        if (!fileIo.accessSync(origPath)) {
          const recordPath = ImagePathUtils.uriToSandboxPath(record.imagePaths[i])
          if (!fileIo.accessSync(recordPath)) {
            continue
          }
        }
        total++
      }
    }
    let current = 0
    for (const record of records) {
      if (!record.imagePaths) {
        continue
      }
      for (let i = 0; i < record.imagePaths.length; i++) {
        const name = record.imagePaths[i].split('/').pop()
        if (!name) {
          continue
        }
        // 本地已有云端 key（有则用原 key 检查/补传，保证云端被删也能恢复）
        const localKey = record.imageCloudKeys && record.imageCloudKeys[i] ? record.imageCloudKeys[i] : ''
        // 上传源：优先 pending 原图（record_{ts}_orig.jpg 与压缩图 record_{ts}.jpg 同 ts）
        const origName = name.replace(/\.(jpg|jpeg|png)$/i, '_orig.jpg')
        const origPath = `${context.cacheDir}/pending/${origName}`
        let uploadPath = origPath
        let isPendingFile = true
        if (!fileIo.accessSync(origPath)) {
          // 无 pending：兜底用本地记录图片
          const recordPath = ImagePathUtils.uriToSandboxPath(record.imagePaths[i])
          if (!fileIo.accessSync(recordPath)) {
            continue
          }
          uploadPath = recordPath
          isPendingFile = false
        }
        current++
        if (onProgress) {
          onProgress(current, total)
        }
        // key：本地已有则用原 key（云端被删时以同 key 覆盖补回），否则生成新 key
        const key = localKey.length > 0 ? localKey : NowViewModel.buildCloudKey(record, i)
        if (dedupe) {
          // 去重：一律查云端——已存在跳过；不存在（含云端被删）继续上传
          const already = await CosService.exists(cos, key)
          if (already) {
            if (!record.imageCloudKeys) {
              record.imageCloudKeys = []
            }
            while (record.imageCloudKeys.length <= i) {
              record.imageCloudKeys.push('')
            }
            record.imageCloudKeys[i] = key
            result.skipped++
            continue
          }
        } else if (localKey.length > 0) {
          // 去重关闭：信任本地 key，直接跳过
          continue
        }
        const ok = await CosService.uploadFile(cos, key, uploadPath)
        if (ok) {
          if (!record.imageCloudKeys) {
            record.imageCloudKeys = []
          }
          while (record.imageCloudKeys.length <= i) {
            record.imageCloudKeys.push('')
          }
          record.imageCloudKeys[i] = key
          result.uploaded++
          // 老图迁移（M1 前原样大图兜底上传）：上传成功后本地压缩并替换记录引用，删除本地大图
          // 仅当「上传后删除原图」开启时执行；压缩失败则保留原引用不删
          if (!isPendingFile && cos.deleteOriginalAfterUpload !== false) {
            const mode = cos.compressMode ? cos.compressMode : ImageFileService.COMPRESS_BALANCED
            const compressedUri = await ImageFileService.saveRecordImage(context, uploadPath, undefined, mode)
            if (compressedUri) {
              record.imagePaths[i] = compressedUri
              try {
                fileIo.unlinkSync(uploadPath)
              } catch (e) {
                Logger.error('[NowViewModel] 删除老图大图失败: ' + JSON.stringify(e))
              }
            }
          }
          // 上传后删除本地原图副本（开关默认开；关闭则本地保留 pending 原图，双保险）
          if (isPendingFile && cos.deleteOriginalAfterUpload !== false) {
            try {
              fileIo.unlinkSync(uploadPath)
            } catch (e) {
              Logger.error('[NowViewModel] 删除已上传原图失败: ' + JSON.stringify(e))
            }
          }
        } else {
          result.failed++
        }
      }
    }
    if (result.uploaded > 0 || result.skipped > 0) {
      await RecordRepository.saveRecords(context, records)
      // 刷新单例内存：uploadAllImages 是静态方法，改的是独立数组；
      // 不刷新的话 NowPage/记录卡片仍读旧内存（指向已删除的大图），图片会显示为空
      const vm = await NowViewModel.getInstance(context)
      await vm.reloadRecords()
    }
    return result
  }

  // 从持久化存储重载记录到内存（上传全部等外部修改后调用，保持单例内存与存储一致）
  async reloadRecords(): Promise<void> {
    if (!this.context) {
      return
    }
    try {
      this.records = await RecordRepository.getRecords(this.context)
    } catch (error) {
      Logger.error('[NowViewModel] 重载记录失败: ' + JSON.stringify(error))
    }
  }

  // 删除 pending 文件
  private static deletePendingFile(path: string): void {
    try {
      if (fileIo.accessSync(path)) {
        fileIo.unlinkSync(path)
      }
    } catch (error) {
      Logger.error('[NowViewModel] 删除 pending 文件失败: ' + JSON.stringify(error))
    }
  }
  
  // 获取图片 URI（用于显示）
  // 注：新记录已统一为 URI 格式，此方法保留用于兼容旧数据；实现已下沉至 service/ImageFileService（P3）
  getImageUri(path: string): string {
    return ImageFileService.getImageUri(path)
  }
  
  // 生成唯一ID
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2)
  }
  
  // 获取上下文
  getContext(): common.UIAbilityContext | null {
    return this.context
  }
}
