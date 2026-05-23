// 备份管理器：common/utils/BackupManager.ets
import { common } from '@kit.AbilityKit'
import { zlib } from '@kit.BasicServicesKit'
import { fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'
import { LifeRecord } from '../types'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import preferences from '@ohos.data.preferences'

// 备份元数据结构
interface BackupMetadata {
  version: string           // 备份版本号
  timestamp: number         // 备份时间戳
  recordCount: number       // 记录总数
  records: LifeRecord[]     // 所有记录
}

export class BackupManager {
  private static instance: BackupManager | null = null
  private context: common.UIAbilityContext | null = null
  
  private readonly BACKUP_VERSION = '1.0.0'
  private readonly METADATA_FILE = 'metadata.json'
  private readonly RECORDS_DIR = 'records'
  private readonly TEMP_DIR = 'backup_temp'
  
  private constructor() {}
  
  // 获取单例实例
  static async getInstance(): Promise<BackupManager> {
    if (!BackupManager.instance) {
      BackupManager.instance = new BackupManager()
      await BackupManager.instance.init()
    }
    return BackupManager.instance
  }
  
  // 初始化
  private async init(): Promise<void> {
    console.info('[BackupManager] init 开始')
    
    // 获取上下文
    let uiContext = AppStorage.get('uiContext') as common.UIAbilityContext
    if (!uiContext) {
      uiContext = AppStorage.get('context') as common.UIAbilityContext
    }
    
    if (!uiContext) {
      console.error('[BackupManager] uiContext 获取失败')
      return
    }
    
    this.context = uiContext
    console.info('[BackupManager] init 完成')
  }
  
  // 创建备份到沙箱临时目录
  async createBackup(): Promise<string | null> {
    if (!this.context) {
      console.error('[BackupManager] context 未初始化')
      return null
    }
    
    try {
      console.info('[BackupManager] 开始创建备份')
      
      // 1. 创建临时目录
      const tempDir = `${this.context.cacheDir}/${this.TEMP_DIR}`
      if (!fileIo.accessSync(tempDir)) {
        fileIo.mkdirSync(tempDir)
      }
      
      // 2. 获取所有记录
      const viewModel = await NowViewModel.getInstance()
      const records = viewModel.getRecords()
      
      console.info(`[BackupManager] 获取到 ${records.length} 条记录`)
      
      // 3. 创建备份元数据
      const metadata: BackupMetadata = {
        version: this.BACKUP_VERSION,
        timestamp: Date.now(),
        recordCount: records.length,
        records: records
      }
      
      // 4. 写入元数据文件
      const metadataPath = `${tempDir}/${this.METADATA_FILE}`
      const metadataStr = JSON.stringify(metadata, null, 2)
      const metadataFile = fileIo.openSync(metadataPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(metadataFile.fd, metadataStr)
      fileIo.closeSync(metadataFile)
      
      console.info('[BackupManager] 元数据文件已创建')
      
      // 5. 复制图片文件到临时目录
      const recordsDir = `${tempDir}/${this.RECORDS_DIR}`
      if (!fileIo.accessSync(recordsDir)) {
        fileIo.mkdirSync(recordsDir)
      }
      
      let imageCount = 0
      for (const record of records) {
        if (record.imagePaths && record.imagePaths.length > 0) {
          for (const imagePath of record.imagePaths) {
            // 将 URI 转换为沙箱路径
            const sandboxPath = this.uriToSandboxPath(imagePath)
            
            // 检查图片文件是否存在
            if (fileIo.accessSync(sandboxPath)) {
              // 获取文件名
              const fileName = sandboxPath.split('/').pop() || `image_${record.id}_${imageCount}.jpg`
              const destPath = `${recordsDir}/${fileName}`
              
              // 复制文件
              fileIo.copyFileSync(sandboxPath, destPath)
              imageCount++
            }
          }
        }
      }
      
      console.info(`[BackupManager] 复制了 ${imageCount} 个图片文件`)
      
      // 6. 压缩为 zip 文件
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19)
      const zipFileName = `RecordLife_backup_${timestamp}.zip`
      const zipPath = `${this.context.cacheDir}/${zipFileName}`
      
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
        memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
        strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
      }
      
      await zlib.compressFile(tempDir, zipPath, options)
      console.info(`[BackupManager] 备份文件已创建: ${zipPath}`)
      
      // 7. 清理临时目录
      this.deleteDirectory(tempDir)
      
      return zipPath
    } catch (error) {
      console.error('[BackupManager] 创建备份失败: ' + JSON.stringify(error))
      return null
    }
  }
  
  // 从 zip 文件恢复备份
  async restoreBackup(zipPath: string): Promise<boolean> {
    if (!this.context) {
      console.error('[BackupManager] context 未初始化')
      return false
    }
    
    try {
      console.info('[BackupManager] 开始恢复备份')
      
      // 1. 创建临时解压目录
      const tempDir = `${this.context.cacheDir}/${this.TEMP_DIR}_restore`
      if (!fileIo.accessSync(tempDir)) {
        fileIo.mkdirSync(tempDir)
      }
      
      // 2. 解压 zip 文件
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      }
      
      await zlib.decompressFile(zipPath, tempDir, options)
      console.info('[BackupManager] zip 文件已解压')
      
      // 3. 读取元数据
      const metadataPath = `${tempDir}/${this.METADATA_FILE}`
      if (!fileIo.accessSync(metadataPath)) {
        console.error('[BackupManager] 元数据文件不存在')
        this.deleteDirectory(tempDir)
        return false
      }
      
      const metadataFile = fileIo.openSync(metadataPath, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(metadataFile.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(metadataFile.fd, buffer)
      fileIo.closeSync(metadataFile)
      
      // 使用 TextDecoder 将 ArrayBuffer 转换为字符串
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
      const metadataStr = decoder.decodeToString(new Uint8Array(buffer))
      const metadata: BackupMetadata = JSON.parse(metadataStr)
      
      console.info(`[BackupManager] 读取到 ${metadata.recordCount} 条记录`)
      
      // 4. 恢复图片文件
      const recordsDir = `${tempDir}/${this.RECORDS_DIR}`
      const destRecordsDir = `${this.context.filesDir}/records`
      
      // 确保目标目录存在
      if (!fileIo.accessSync(destRecordsDir)) {
        fileIo.mkdirSync(destRecordsDir)
      }
      
      // 复制图片文件并更新记录中的路径
      const updatedRecords: LifeRecord[] = metadata.records.map(record => {
        const updatedRecord: LifeRecord = {
          id: record.id,
          timestamp: record.timestamp,
          content: record.content,
          imagePaths: undefined
        }
        
        if (record.imagePaths && record.imagePaths.length > 0) {
          const newImagePaths: string[] = []
          
          for (const oldImagePath of record.imagePaths) {
            // 从旧路径提取文件名
            const oldSandboxPath = this.uriToSandboxPath(oldImagePath)
            const fileName = oldSandboxPath.split('/').pop()
            
            if (fileName) {
              const srcPath = `${recordsDir}/${fileName}`
              const destPath = `${destRecordsDir}/${fileName}`
              
              // 如果备份中有这个图片文件，复制并更新路径
              if (fileIo.accessSync(srcPath)) {
                fileIo.copyFileSync(srcPath, destPath)
                // 转换为 URI 格式
                const newUri = this.sandboxPathToUri(destPath)
                newImagePaths.push(newUri)
              }
            }
          }
          
          if (newImagePaths.length > 0) {
            updatedRecord.imagePaths = newImagePaths
          }
        }
        
        return updatedRecord
      })
      
      console.info(`[BackupManager] 图片文件已恢复，记录路径已更新`)
      
      // 5. 恢复记录到 Preferences
      const viewModel = await NowViewModel.getInstance()
      const success = await this.restoreRecordsToPreferences(updatedRecords)
      
      if (success) {
        console.info('[BackupManager] 备份恢复成功')
      } else {
        console.error('[BackupManager] 恢复记录失败')
      }
      
      // 6. 清理临时目录
      this.deleteDirectory(tempDir)
      
      return success
    } catch (error) {
      console.error('[BackupManager] 恢复备份失败: ' + JSON.stringify(error))
      return false
    }
  }
  
  // 恢复记录到 Preferences
  private async restoreRecordsToPreferences(records: LifeRecord[]): Promise<boolean> {
    if (!this.context) {
      return false
    }
    
    try {
      const STORE_NAME = 'now_page_records'
      const RECORDS_KEY = 'life_records'
      
      // 获取 Preferences 实例
      const prefs = await preferences.getPreferences(this.context, STORE_NAME)
      
      // 保存记录
      const recordsStr = JSON.stringify(records)
      await prefs.put(RECORDS_KEY, recordsStr)
      await prefs.flush()
      
      console.info(`[BackupManager] 已恢复 ${records.length} 条记录到 Preferences`)
      return true
    } catch (error) {
      console.error('[BackupManager] 恢复记录到 Preferences 失败: ' + JSON.stringify(error))
      return false
    }
  }
  
  // 删除目录
  private deleteDirectory(dirPath: string): void {
    try {
      if (fileIo.accessSync(dirPath)) {
        const files = fileIo.listFileSync(dirPath)
        for (const fileName of files) {
          const filePath = `${dirPath}/${fileName}`
          const stat = fileIo.statSync(filePath)
          if (stat.isDirectory()) {
            this.deleteDirectory(filePath)
          } else {
            fileIo.unlinkSync(filePath)
          }
        }
        fileIo.rmdirSync(dirPath)
      }
    } catch (error) {
      console.error('[BackupManager] 删除目录失败: ' + JSON.stringify(error))
    }
  }
  
  // 将 URI 转换为沙箱路径（用于文件操作）
  private uriToSandboxPath(uri: string): string {
    if (uri.startsWith('file://')) {
      // URI 格式: file://<bundleName>/data/storage/... 或 file:///data/storage/...
      let path = uri.substring(7)  // 移除 'file://'
      
      // 找到第一个 '/' 的位置，从那里开始截取路径
      const slashIndex = path.indexOf('/')
      if (slashIndex !== -1) {
        path = path.substring(slashIndex)
      }
      
      return path
    }
    return uri  // 已经是沙箱路径格式
  }
  
  // 将沙箱路径转换为 URI 格式
  private sandboxPathToUri(path: string): string {
    if (path.startsWith('file://')) {
      return path  // 已经是 URI 格式
    }
    return `file://${path}`
  }
  
  // 获取上下文
  getContext(): common.UIAbilityContext | null {
    return this.context
  }
}
