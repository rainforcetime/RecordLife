// MorePage 备份处理类：处理备份相关的业务逻辑
import { common, Want } from '@kit.AbilityKit'
import { picker, fileUri } from '@kit.CoreFileKit'
import { fileIo } from '@kit.CoreFileKit'
import { zlib } from '@kit.BasicServicesKit'
import { PromptAction } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'
import preferences from '@ohos.data.preferences'
import { BackupManager } from '../managers/BackupManager'
import { RefreshManager } from '../managers/RefreshManager'
import { MorePageHelper } from '../utils/MorePageHelper'
import { ConfigManager } from '../../config/ConfigManager'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import { LifeRecord } from '../types'
import { AppInfoManager } from '../../config/AppInfoConfig'

// 记录元数据接口
interface RecordsMetadata {
  appVersion: string
  timestamp: number
  recordCount: number
  records: LifeRecord[]
}

export class MorePageBackupHandler {
  /**
   * 重启应用
   * 使用 ApplicationContext.restartApp 方法重启应用
   */
  private static restartApp(context: common.UIAbilityContext): void {
    try {
      const applicationContext = context.getApplicationContext()
      const want: Want = {
        bundleName: 'com.rainforcetime.recordlife',
        abilityName: 'EntryAbility'
      }
      console.info('[MorePageBackupHandler] 准备重启应用')
      applicationContext.restartApp(want)
      console.info('[MorePageBackupHandler] 重启应用已触发')
    } catch (error) {
      console.error('[MorePageBackupHandler] 重启应用失败: ' + JSON.stringify(error))
    }
  }
  
  /**
   * 导出备份
   */
  static async exportBackup(
    context: common.UIAbilityContext,
    backupManager: BackupManager,
    promptAction: PromptAction
  ): Promise<void> {
    console.info('[MorePageBackupHandler] 开始导出备份')
    
    try {
      // 创建备份
      const zipPath = await backupManager.createBackup()
      
      if (!zipPath) {
        promptAction.showToast({ message: '创建备份失败' })
        return
      }
      
      console.info('[MorePageBackupHandler] 备份已创建: ' + zipPath)
      
      // 使用 DocumentViewPicker 保存文件
      const fileName = zipPath.split('/').pop() || 'backup.zip'
      const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
      console.info('[MorePageBackupHandler] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const saveUri: string = uriResult[0]
        
        // 打开文件并写入备份内容
        const zipFile = fileIo.openSync(zipPath, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(zipFile.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(zipFile.fd, buffer)
        fileIo.closeSync(zipFile)
        
        const destFile = fileIo.openSync(saveUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(destFile.fd, buffer)
        fileIo.closeSync(destFile)
        
        // 删除临时备份文件
        fileIo.unlinkSync(zipPath)
        
        console.info('[MorePageBackupHandler] 备份导出成功: ' + saveUri)
        promptAction.showToast({ message: '备份导出成功' })
      } else {
        // 用户取消，删除临时备份文件
        fileIo.unlinkSync(zipPath)
        console.info('[MorePageBackupHandler] 用户取消导出')
      }
    } catch (error) {
      console.error('[MorePageBackupHandler] 导出备份失败: ' + JSON.stringify(error))
      try {
        promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
      } catch (e) {
        console.error('[MorePageBackupHandler] showToast failed: ' + JSON.stringify(e))
      }
    }
  }
  
  /**
   * 导入备份
   */
  static async importBackup(
    context: common.UIAbilityContext,
    backupManager: BackupManager,
    promptAction: PromptAction
  ): Promise<void> {
    console.info('[MorePageBackupHandler] 开始导入备份')
    
    try {
      // 使用 DocumentViewPicker 选择备份文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      console.info('[MorePageBackupHandler] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const selectUri: string = uriResult[0]
        
        // 将文件复制到沙箱临时目录
        const tempZipPath = `${context.cacheDir}/temp_backup.zip`
        const srcFile = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(srcFile.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(srcFile.fd, buffer)
        fileIo.closeSync(srcFile)
        
        const destFile = fileIo.openSync(tempZipPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(destFile.fd, buffer)
        fileIo.closeSync(destFile)
        
        // 恢复备份
        const success = await backupManager.restoreBackup(tempZipPath)
        
        // 删除临时文件
        fileIo.unlinkSync(tempZipPath)
        
        if (success) {
          console.info('[MorePageBackupHandler] 备份导入成功')
          promptAction.showToast({ message: '备份导入成功，应用即将重启' })
          
          // 延迟1秒后重启应用，让用户看到提示
          setTimeout(() => {
            MorePageBackupHandler.restartApp(context)
          }, 1000)
        } else {
          console.error('[MorePageBackupHandler] 备份导入失败')
          promptAction.showToast({ message: '备份文件格式无效或已损坏' })
        }
      } else {
        console.info('[MorePageBackupHandler] 用户取消导入')
      }
    } catch (error) {
      console.error('[MorePageBackupHandler] 导入备份失败: ' + JSON.stringify(error))
      try {
        promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
      } catch (e) {
        console.error('[MorePageBackupHandler] showToast failed: ' + JSON.stringify(e))
      }
    }
  }
  
  /**
   * 导出所有数据（用户配置 + 此刻记录 + 头像）
   */
  static async exportAll(
    context: common.UIAbilityContext,
    configManager: ConfigManager,
    promptAction: PromptAction
  ): Promise<void> {
    console.info('[MorePageBackupHandler] 开始导出所有数据')
    
    try {
      // 1. 创建临时目录
      const tempDir = `${context.cacheDir}/export_all_temp`
      if (fileIo.accessSync(tempDir)) {
        MorePageHelper.deleteDirectory(tempDir)
      }
      fileIo.mkdirSync(tempDir)
      
      // 2. 导出用户配置
      const configStr = await configManager.exportConfig()
      const configPath = `${tempDir}/config.json`
      const configFile = fileIo.openSync(configPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(configFile.fd, configStr)
      fileIo.closeSync(configFile)
      console.info('[MorePageBackupHandler] 用户配置已导出')
      
      // 3. 导出此刻记录
      const viewModel = await NowViewModel.getInstance()
      const records = viewModel.getRecords()
      
      // 从AppInfoManager获取应用版本号
      let appVersion = '1.0.0'
      try {
        const appInfoManager = await AppInfoManager.getInstance()
        appVersion = appInfoManager.getAppVersion()
      } catch (error) {
        console.error('[MorePageBackupHandler] 获取应用版本失败: ' + JSON.stringify(error))
      }
      
      // 创建记录元数据
      const recordsMetadata: RecordsMetadata = {
        appVersion: appVersion,
        timestamp: Date.now(),
        recordCount: records.length,
        records: records
      }
      
      const metadataPath = `${tempDir}/records_metadata.json`
      const metadataStr = JSON.stringify(recordsMetadata, null, 2)
      const metadataFile = fileIo.openSync(metadataPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(metadataFile.fd, metadataStr)
      fileIo.closeSync(metadataFile)
      console.info('[MorePageBackupHandler] 记录元数据已导出')
      
      // 4. 复制图片文件
      const recordsDir = `${tempDir}/records`
      fileIo.mkdirSync(recordsDir)
      
      let imageCount = 0
      for (const record of records) {
        if (record.imagePaths && record.imagePaths.length > 0) {
          for (const imagePath of record.imagePaths) {
            // 将 URI 转换为沙箱路径
            const sandboxPath = MorePageHelper.uriToSandboxPath(imagePath)
            
            if (fileIo.accessSync(sandboxPath)) {
              const fileName = sandboxPath.split('/').pop() || `image_${record.id}_${imageCount}.jpg`
              const destPath = `${recordsDir}/${fileName}`
              fileIo.copyFileSync(sandboxPath, destPath)
              imageCount++
            }
          }
        }
      }
      console.info(`[MorePageBackupHandler] 复制了 ${imageCount} 个图片文件`)
      
      // 5. 压缩为 zip 文件
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19)
      const zipFileName = `RecordLife_all_${timestamp}.zip`
      const zipPath = `${context.cacheDir}/${zipFileName}`
      
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
        memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
        strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
      }
      
      await zlib.compressFile(tempDir, zipPath, options)
      console.info(`[MorePageBackupHandler] 所有数据已打包: ${zipPath}`)
      
      // 7. 使用 DocumentViewPicker 保存文件
      const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [zipFileName]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
      
      if (uriResult && uriResult.length > 0) {
        const saveUri: string = uriResult[0]
        
        // 读取并写入目标文件
        const zipFile = fileIo.openSync(zipPath, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(zipFile.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(zipFile.fd, buffer)
        fileIo.closeSync(zipFile)
        
        const destFile = fileIo.openSync(saveUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(destFile.fd, buffer)
        fileIo.closeSync(destFile)
        
        console.info('[MorePageBackupHandler] 所有数据导出成功: ' + saveUri)
        promptAction.showToast({ message: '导出成功' })
      } else {
        console.info('[MorePageBackupHandler] 用户取消导出')
      }
      
      // 8. 清理临时文件
      MorePageHelper.deleteDirectory(tempDir)
      if (fileIo.accessSync(zipPath)) {
        fileIo.unlinkSync(zipPath)
      }
      
    } catch (error) {
      console.error('[MorePageBackupHandler] 导出所有数据失败: ' + JSON.stringify(error))
      try {
        promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
      } catch (e) {
        console.error('[MorePageBackupHandler] showToast failed: ' + JSON.stringify(e))
      }
    }
  }
  
  /**
   * 导入所有数据（用户配置 + 此刻记录 + 头像）
   */
  static async importAll(
    context: common.UIAbilityContext,
    configManager: ConfigManager,
    promptAction: PromptAction
  ): Promise<void> {
    console.info('[MorePageBackupHandler] 开始导入所有数据')
    
    try {
      // 1. 使用 DocumentViewPicker 选择文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      
      if (!uriResult || uriResult.length === 0) {
        console.info('[MorePageBackupHandler] 用户取消导入')
        return
      }
      
      const selectUri: string = uriResult[0]
      
      // 2. 将文件复制到沙箱临时目录
      const tempZipPath = `${context.cacheDir}/temp_import_all.zip`
      const srcFile = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(srcFile.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(srcFile.fd, buffer)
      fileIo.closeSync(srcFile)
      
      const destFile = fileIo.openSync(tempZipPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(destFile.fd, buffer)
      fileIo.closeSync(destFile)
      
      // 3. 解压 zip 文件
      const tempDir = `${context.cacheDir}/import_all_temp`
      if (fileIo.accessSync(tempDir)) {
        MorePageHelper.deleteDirectory(tempDir)
      }
      fileIo.mkdirSync(tempDir)
      
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      }
      
      await zlib.decompressFile(tempZipPath, tempDir, options)
      console.info('[MorePageBackupHandler] zip 文件已解压')
      
      // 4. 导入用户配置
      const configPath = `${tempDir}/config.json`
      let configImported = false
      if (fileIo.accessSync(configPath)) {
        const configFile = fileIo.openSync(configPath, fileIo.OpenMode.READ_ONLY)
        const configStat = fileIo.statSync(configFile.fd)
        const configBuffer = new ArrayBuffer(configStat.size)
        fileIo.readSync(configFile.fd, configBuffer)
        fileIo.closeSync(configFile)
        
        const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
        const configStr = decoder.decodeToString(new Uint8Array(configBuffer))
        
        configImported = await configManager.importConfig(configStr)
        console.info('[MorePageBackupHandler] 用户配置导入: ' + (configImported ? '成功' : '失败'))
      }
      
      // 5. 导入此刻记录
      const metadataPath = `${tempDir}/records_metadata.json`
      let recordsImported = false
      if (fileIo.accessSync(metadataPath)) {
        const metadataFile = fileIo.openSync(metadataPath, fileIo.OpenMode.READ_ONLY)
        const metadataStat = fileIo.statSync(metadataFile.fd)
        const metadataBuffer = new ArrayBuffer(metadataStat.size)
        fileIo.readSync(metadataFile.fd, metadataBuffer)
        fileIo.closeSync(metadataFile)
        
        const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
        const metadataStr = decoder.decodeToString(new Uint8Array(metadataBuffer))
        const metadata: RecordsMetadata = JSON.parse(metadataStr)
        
        // 恢复图片文件
        const recordsDir = `${tempDir}/records`
        const destRecordsDir = `${context.filesDir}/records`
        
        if (!fileIo.accessSync(destRecordsDir)) {
          fileIo.mkdirSync(destRecordsDir)
        }
        
        // 复制图片文件并更新记录中的路径
        const updatedRecords: LifeRecord[] = metadata.records.map(record => {
          const updatedRecord: LifeRecord = {
            id: record.id,
            timestamp: record.timestamp,
            content: record.content,
            imagePaths: undefined,
            tags: record.tags,
            isPinned: record.isPinned
          }
          
          if (record.imagePaths && record.imagePaths.length > 0) {
            const newImagePaths: string[] = []
            
            for (const oldImagePath of record.imagePaths) {
              // 从旧路径提取文件名
              const oldSandboxPath = MorePageHelper.uriToSandboxPath(oldImagePath)
              const fileName = oldSandboxPath.split('/').pop()
              
              if (fileName) {
                const srcPath = `${recordsDir}/${fileName}`
                const destPath = `${destRecordsDir}/${fileName}`
                
                // 如果备份中有这个图片文件，复制并更新路径
                if (fileIo.accessSync(srcPath)) {
                  fileIo.copyFileSync(srcPath, destPath)
                  // 转换为 URI 格式
                  const newUri = `file://${destPath}`
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
        
        console.info(`[MorePageBackupHandler] 图片文件已恢复，记录路径已更新`)
        
        // 恢复记录到 Preferences
        recordsImported = await MorePageBackupHandler.restoreRecordsToPreferences(context, updatedRecords)
        console.info('[MorePageBackupHandler] 记录导入: ' + (recordsImported ? '成功' : '失败'))
      }
      
      // 6. 清理临时文件
      fileIo.unlinkSync(tempZipPath)
      MorePageHelper.deleteDirectory(tempDir)
      
      // 7. 显示结果
      if (configImported || recordsImported) {
        const messages: string[] = []
        if (configImported) messages.push('用户配置')
        if (recordsImported) messages.push('此刻记录')
        
        promptAction.showToast({ message: `导入成功: ${messages.join('、')}，应用即将重启` })
        
        // 延迟1秒后重启应用，让用户看到提示
        setTimeout(() => {
          MorePageBackupHandler.restartApp(context)
        }, 1000)
      } else {
        promptAction.showToast({ message: '未找到有效数据' })
      }
      
    } catch (error) {
      console.error('[MorePageBackupHandler] 导入所有数据失败: ' + JSON.stringify(error))
      try {
        promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
      } catch (e) {
        console.error('[MorePageBackupHandler] showToast failed: ' + JSON.stringify(e))
      }
    }
  }
  
  /**
   * 恢复记录到 Preferences
   */
  private static async restoreRecordsToPreferences(
    context: common.UIAbilityContext,
    records: LifeRecord[]
  ): Promise<boolean> {
    try {
      const STORE_NAME = 'now_page_records'
      const RECORDS_KEY = 'life_records'
      
      const prefs = await preferences.getPreferences(context, STORE_NAME)
      const recordsStr = JSON.stringify(records)
      await prefs.put(RECORDS_KEY, recordsStr)
      await prefs.flush()
      
      console.info(`[MorePageBackupHandler] 已恢复 ${records.length} 条记录到 Preferences`)
      return true
    } catch (error) {
      console.error('[MorePageBackupHandler] 恢复记录到 Preferences 失败: ' + JSON.stringify(error))
      return false
    }
  }
}
