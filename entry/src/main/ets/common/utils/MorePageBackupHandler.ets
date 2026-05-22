// MorePage 备份处理类：处理备份相关的业务逻辑
import { common, Want } from '@kit.AbilityKit'
import { picker, fileUri } from '@kit.CoreFileKit'
import { fileIo } from '@kit.CoreFileKit'
import { zlib } from '@kit.BasicServicesKit'
import { PromptAction } from '@kit.ArkUI'
import { util } from '@kit.ArkTS'
import preferences from '@ohos.data.preferences'
import { BackupManager } from './BackupManager'
import { RefreshManager } from '../RefreshManager'
import { MorePageHelper } from './MorePageHelper'
import { ConfigManager } from '../../config/ConfigManager'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import { LifeRecord } from '../types'

// 记录元数据接口
interface RecordsMetadata {
  version: string
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
      promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
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
      promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
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
      
      // 创建记录元数据
      const recordsMetadata: RecordsMetadata = {
        version: '1.0.0',
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
        if (record.imagePath) {
          // 将 URI 转换为沙箱路径
          const imagePath = MorePageHelper.uriToSandboxPath(record.imagePath)
          
          if (fileIo.accessSync(imagePath)) {
            const fileName = imagePath.split('/').pop() || `image_${record.id}.jpg`
            const destPath = `${recordsDir}/${fileName}`
            fileIo.copyFileSync(imagePath, destPath)
            imageCount++
          }
        }
      }
      console.info(`[MorePageBackupHandler] 复制了 ${imageCount} 个图片文件`)
      
      // 5. 复制头像文件
      let avatarExported = false
      const config = configManager.getConfig()
      console.info('[MorePageBackupHandler] 头像配置: ' + config.profile.avatar)
      
      if (config.profile.avatar && config.profile.avatar.length > 0) {
        // 从URI中提取路径
        const avatarPath = MorePageHelper.uriToSandboxPath(config.profile.avatar)
        
        console.info('[MorePageBackupHandler] 头像路径: ' + avatarPath)
        
        try {
          const fileExists = fileIo.accessSync(avatarPath)
          console.info('[MorePageBackupHandler] 头像文件是否存在: ' + fileExists)
          
          if (fileExists) {
            // 只有在文件存在时才创建avatar目录
            const avatarDir = `${tempDir}/avatar`
            fileIo.mkdirSync(avatarDir)
            console.info('[MorePageBackupHandler] 创建avatar目录: ' + avatarDir)
            
            const avatarFileName = avatarPath.split('/').pop() || 'avatar.jpg'
            const destAvatarPath = `${avatarDir}/${avatarFileName}`
            console.info('[MorePageBackupHandler] 目标路径: ' + destAvatarPath)
            
            fileIo.copyFileSync(avatarPath, destAvatarPath)
            
            // 验证复制是否成功
            const destExists = fileIo.accessSync(destAvatarPath)
            console.info('[MorePageBackupHandler] 目标文件是否存在: ' + destExists)
            
            avatarExported = true
            console.info('[MorePageBackupHandler] 头像文件已导出: ' + avatarFileName)
          } else {
            console.error('[MorePageBackupHandler] 头像文件不存在: ' + avatarPath)
          }
        } catch (avatarError) {
          console.error('[MorePageBackupHandler] 导出头像失败: ' + JSON.stringify(avatarError))
        }
      } else {
        console.info('[MorePageBackupHandler] 没有头像配置，跳过头像导出')
      }
      
      // 6. 压缩为 zip 文件
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
      promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
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
        
        if (fileIo.accessSync(recordsDir)) {
          const files = fileIo.listFileSync(recordsDir)
          for (const fileName of files) {
            const srcPath = `${recordsDir}/${fileName}`
            const destPath = `${destRecordsDir}/${fileName}`
            fileIo.copyFileSync(srcPath, destPath)
          }
          console.info(`[MorePageBackupHandler] 恢复了 ${files.length} 个图片文件`)
        }
        
        // 恢复记录到 Preferences
        recordsImported = await MorePageBackupHandler.restoreRecordsToPreferences(context, metadata.records)
        console.info('[MorePageBackupHandler] 记录导入: ' + (recordsImported ? '成功' : '失败'))
      }
      
      // 6. 恢复头像文件
      const avatarDir = `${tempDir}/avatar`
      let avatarImported = false
      if (fileIo.accessSync(avatarDir)) {
        const avatarFiles = fileIo.listFileSync(avatarDir)
        if (avatarFiles.length > 0) {
          // 恢复头像文件到 filesDir
          const avatarFileName = avatarFiles[0]
          const srcAvatarPath = `${avatarDir}/${avatarFileName}`
          const destAvatarPath = `${context.filesDir}/${avatarFileName}`
          fileIo.copyFileSync(srcAvatarPath, destAvatarPath)
          
          // 更新配置中的头像路径
          const avatarUri = fileUri.getUriFromPath(destAvatarPath)
          
          // 更新配置
          const currentConfig = configManager.getConfig()
          await configManager.updateProfile(
            currentConfig.profile.name,
            currentConfig.profile.birthDate,
            currentConfig.profile.gender,
            avatarUri
          )
          
          avatarImported = true
          console.info('[MorePageBackupHandler] 头像文件已恢复: ' + avatarFileName)
        }
      }
      
      // 7. 清理临时文件
      fileIo.unlinkSync(tempZipPath)
      MorePageHelper.deleteDirectory(tempDir)
      
      // 8. 显示结果
      if (configImported || recordsImported || avatarImported) {
        const messages: string[] = []
        if (configImported) messages.push('用户配置')
        if (recordsImported) messages.push('此刻记录')
        if (avatarImported) messages.push('头像')
        
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
      promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
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
