// 更多设置页面：pages/MorePage.ets
import { common } from '@kit.AbilityKit'
import { picker, fileUri } from '@kit.CoreFileKit'
import { fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'
import { zlib } from '@kit.BasicServicesKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItemWithAction } from '../components/SettingItemWithAction'
import { ConfigManager } from '../config/ConfigManager'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { BackupManager } from '../common/utils/BackupManager'
import { RefreshManager } from '../common/RefreshManager'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { LifeRecord } from '../common/types'
import preferences from '@ohos.data.preferences'

// 记录元数据接口
interface RecordsMetadata {
  version: string
  timestamp: number
  recordCount: number
  records: LifeRecord[]
}

@Entry
@Component
export struct MorePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private backupManager: BackupManager | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()
  
  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      console.info('MorePage: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      // 初始化配置管理器
      this.configManager = await ConfigManager.getInstance()
      console.info('MorePage: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
      
      // 初始化备份管理器
      this.backupManager = await BackupManager.getInstance()
      console.info('MorePage: backupManager 已初始化 - ' + (this.backupManager ? '成功' : '失败'))
    } catch (error) {
      console.error('MorePage 初始化失败: ' + JSON.stringify(error))
    }
  }
  
  build() {
    Column() {
      // 页面标题
      Row() {
        // 返回按钮
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor(this.themeColors.iconColor)
          .onClick(() => {
            this.goBack()
          })
        
        Text('更多')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 15 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 15, right: 15 })
      .backgroundColor(this.themeColors.cardBackground)
      
      Scroll() {
        Column() {
          // 功能列表
          this.FunctionsSection()
        }
        .width('100%')
        .margin({ top: 15 })
        .align(Alignment.Top)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }
  
  // 功能列表组件
  @Builder
  FunctionsSection() {
    Column() {
      // 导出配置
      SettingItemWithAction({
        label: '导出用户配置',
        summary: '导出应用配置文件',
        onAction: () => {
          this.onExportConfig()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 导入配置
      SettingItemWithAction({
        label: '导入用户配置',
        summary: '从文件导入配置',
        onAction: () => {
          this.onImportConfig()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 导出备份
      SettingItemWithAction({
        label: '导出此刻记录备份',
        summary: '导出所有此刻记录到 zip 文件',
        onAction: () => {
          this.onExportBackup()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 导入备份
      SettingItemWithAction({
        label: '导入此刻记录备份',
        summary: '从 zip 文件恢复此刻记录',
        onAction: () => {
          this.onImportBackup()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 导出所有
      SettingItemWithAction({
        label: '导出所有',
        summary: '导出用户配置和此刻记录到同一个 zip 文件',
        onAction: () => {
          this.onExportAll()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 导入所有
      SettingItemWithAction({
        label: '导入所有',
        summary: '从 zip 文件导入用户配置和此刻记录',
        onAction: () => {
          this.onImportAll()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 重置应用
      SettingItemWithAction({
        label: '重置应用',
        summary: '恢复默认设置',
        isDestructive: true,
        onAction: () => {
          this.onResetApp()
        }
      })
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(10)
    .margin({ left: 15, right: 15 })
  }
  
  // 返回处理
  private goBack() {
    // 获取UI上下文并执行路由返回
    this.getUIContext().getRouter().back()
  }
  
  // 导出配置处理
  private async onExportConfig() {
    console.info('[MorePage] 开始导出配置')
    
    if (!this.configManager) {
      promptAction.showToast({ message: '配置管理器未初始化' })
      return
    }
    
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化' })
      return
    }
    
    try {
      // 获取配置内容
      const configStr = await this.configManager.exportConfig()
      console.info('[MorePage] 配置内容长度: ' + configStr.length)
      
      // 生成文件名（带时间戳）
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19)
      const fileName = `RecordLife_config_${timestamp}.json`
      
      // 使用DocumentViewPicker保存文件
      const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
      console.info('[MorePage] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const saveUri: string = uriResult[0]
        
        // 打开文件并写入配置内容
        const file = fileIo.openSync(saveUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(file.fd, configStr)
        fileIo.closeSync(file)
        
        console.info('[MorePage] 配置导出成功: ' + saveUri)
        promptAction.showToast({ message: '配置导出成功' })
      } else {
        console.info('[MorePage] 用户取消导出')
      }
    } catch (error) {
      console.error('[MorePage] 导出配置失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
    }
  }
  
  // 导入配置处理
  private async onImportConfig() {
    console.info('[MorePage] 开始导入配置')
    
    if (!this.configManager) {
      promptAction.showToast({ message: '配置管理器未初始化' })
      return
    }
    
    try {
      // 使用DocumentViewPicker选择配置文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      console.info('[MorePage] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const selectUri: string = uriResult[0]
        
        // 打开文件并读取配置内容
        const file = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(file.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(file.fd, buffer)
        fileIo.closeSync(file)
        
        // 将ArrayBuffer转换为字符串
        const decoder: util.TextDecoder = new util.TextDecoder('utf-8')
        const configStr = decoder.decodeToString(new Uint8Array(buffer))
        console.info('[MorePage] 配置内容长度: ' + configStr.length)
        
        // 导入配置
        const success = await this.configManager.importConfig(configStr)
        
        if (success) {
          console.info('[MorePage] 配置导入成功')
          promptAction.showToast({ message: '配置导入成功，部分设置需重启生效' })
        } else {
          console.error('[MorePage] 配置导入失败：格式无效')
          promptAction.showToast({ message: '配置文件格式无效' })
        }
      } else {
        console.info('[MorePage] 用户取消导入')
      }
    } catch (error) {
      console.error('[MorePage] 导入配置失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
    }
  }
  
  // 重置应用处理
  private onResetApp() {
    this.getUIContext().showAlertDialog({
      title: '重置应用',
      message: '确定要重置应用吗？此操作将清除所有用户数据（包括此刻记录）并恢复默认设置，不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('[MorePage] 用户取消重置')
        }
      },
      secondaryButton: {
        value: '确定',
        action: async () => {
          console.info('[MorePage] 开始重置应用')
          
          if (!this.configManager) {
            promptAction.showToast({ message: '配置管理器未初始化' })
            return
          }
          
          if (!this.context) {
            promptAction.showToast({ message: '上下文未初始化' })
            return
          }
          
          try {
            // 1. 删除此刻记录数据
            const recordsDeleted = await this.deleteAllRecords()
            console.info(`[MorePage] 删除了 ${recordsDeleted} 条记录`)
            
            // 2. 重置配置
            const success = await this.configManager.resetToDefault()
            
            if (success) {
              console.info('[MorePage] 应用重置成功')
              promptAction.showToast({ message: '应用已重置，请重启应用生效' })
              
              // 触发全局刷新
              RefreshManager.getInstance().refresh()
            } else {
              console.error('[MorePage] 应用重置失败')
              promptAction.showToast({ message: '重置失败，请重试' })
            }
          } catch (error) {
            console.error('[MorePage] 重置应用异常: ' + JSON.stringify(error))
            promptAction.showToast({ message: '重置失败: ' + (error as Error).message })
          }
        }
      }
    })
  }
  
  // 删除所有此刻记录
  private async deleteAllRecords(): Promise<number> {
    if (!this.context) {
      return 0
    }
    
    try {
      // 1. 获取所有记录
      const viewModel = await NowViewModel.getInstance()
      const records = viewModel.getRecords()
      
      // 2. 删除所有图片文件
      const recordsDir = `${this.context.filesDir}/records`
      if (fileIo.accessSync(recordsDir)) {
        const files = fileIo.listFileSync(recordsDir)
        for (const fileName of files) {
          const filePath = `${recordsDir}/${fileName}`
          fileIo.unlinkSync(filePath)
        }
        console.info(`[MorePage] 删除了 ${files.length} 个图片文件`)
      }
      
      // 3. 清空 Preferences 中的记录数据
      const STORE_NAME = 'now_page_records'
      const RECORDS_KEY = 'life_records'
      const prefs = await preferences.getPreferences(this.context, STORE_NAME)
      await prefs.put(RECORDS_KEY, '[]')
      await prefs.flush()
      
      console.info('[MorePage] 记录数据已清空')
      
      return records.length
    } catch (error) {
      console.error('[MorePage] 删除记录失败: ' + JSON.stringify(error))
      return 0
    }
  }
  
  // 导出备份处理
  private async onExportBackup() {
    console.info('[MorePage] 开始导出备份')
    
    if (!this.backupManager) {
      promptAction.showToast({ message: '备份管理器未初始化' })
      return
    }
    
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化' })
      return
    }
    
    try {
      // 创建备份
      const zipPath = await this.backupManager.createBackup()
      
      if (!zipPath) {
        promptAction.showToast({ message: '创建备份失败' })
        return
      }
      
      console.info('[MorePage] 备份已创建: ' + zipPath)
      
      // 使用 DocumentViewPicker 保存文件
      const fileName = zipPath.split('/').pop() || 'backup.zip'
      const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
      console.info('[MorePage] 文件选择结果: ' + JSON.stringify(uriResult))
      
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
        
        console.info('[MorePage] 备份导出成功: ' + saveUri)
        promptAction.showToast({ message: '备份导出成功' })
      } else {
        // 用户取消，删除临时备份文件
        fileIo.unlinkSync(zipPath)
        console.info('[MorePage] 用户取消导出')
      }
    } catch (error) {
      console.error('[MorePage] 导出备份失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
    }
  }
  
  // 导入备份处理
  private async onImportBackup() {
    console.info('[MorePage] 开始导入备份')
    
    if (!this.backupManager) {
      promptAction.showToast({ message: '备份管理器未初始化' })
      return
    }
    
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化' })
      return
    }
    
    try {
      // 使用 DocumentViewPicker 选择备份文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      console.info('[MorePage] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const selectUri: string = uriResult[0]
        
        // 将文件复制到沙箱临时目录
        const tempZipPath = `${this.context.cacheDir}/temp_backup.zip`
        const srcFile = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(srcFile.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(srcFile.fd, buffer)
        fileIo.closeSync(srcFile)
        
        const destFile = fileIo.openSync(tempZipPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(destFile.fd, buffer)
        fileIo.closeSync(destFile)
        
        // 恢复备份
        const success = await this.backupManager.restoreBackup(tempZipPath)
        
        // 删除临时文件
        fileIo.unlinkSync(tempZipPath)
        
        if (success) {
          console.info('[MorePage] 备份导入成功')
          promptAction.showToast({ message: '备份导入成功' })
          
          // 触发全局刷新
          RefreshManager.getInstance().refresh()
        } else {
          console.error('[MorePage] 备份导入失败')
          promptAction.showToast({ message: '备份文件格式无效或已损坏' })
        }
      } else {
        console.info('[MorePage] 用户取消导入')
      }
    } catch (error) {
      console.error('[MorePage] 导入备份失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
    }
  }
  
  // 导出所有（用户配置 + 此刻记录）
  private async onExportAll() {
    console.info('[MorePage] 开始导出所有数据')
    
    if (!this.configManager || !this.backupManager || !this.context) {
      promptAction.showToast({ message: '管理器未初始化' })
      return
    }
    
    try {
      // 1. 创建临时目录
      const tempDir = `${this.context.cacheDir}/export_all_temp`
      if (fileIo.accessSync(tempDir)) {
        this.deleteDirectory(tempDir)
      }
      fileIo.mkdirSync(tempDir)
      
      // 2. 导出用户配置
      const configStr = await this.configManager.exportConfig()
      const configPath = `${tempDir}/config.json`
      const configFile = fileIo.openSync(configPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(configFile.fd, configStr)
      fileIo.closeSync(configFile)
      console.info('[MorePage] 用户配置已导出')
      
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
      console.info('[MorePage] 记录元数据已导出')
      
      // 4. 复制图片文件
      const recordsDir = `${tempDir}/records`
      fileIo.mkdirSync(recordsDir)
      
      let imageCount = 0
      for (const record of records) {
        if (record.imagePath) {
          // 将 URI 转换为沙箱路径
          const imagePath = this.uriToSandboxPath(record.imagePath)
          
          if (fileIo.accessSync(imagePath)) {
            const fileName = imagePath.split('/').pop() || `image_${record.id}.jpg`
            const destPath = `${recordsDir}/${fileName}`
            fileIo.copyFileSync(imagePath, destPath)
            imageCount++
          }
        }
      }
      console.info(`[MorePage] 复制了 ${imageCount} 个图片文件`)
      
      // 5. 复制头像文件
      let avatarExported = false
      const config = this.configManager.getConfig()
      console.info('[MorePage] 头像配置: ' + config.profile.avatar)
      
      if (config.profile.avatar && config.profile.avatar.length > 0) {
        // 从URI中提取路径
        const avatarPath = this.uriToSandboxPath(config.profile.avatar)
        
        console.info('[MorePage] 头像路径: ' + avatarPath)
        
        try {
          const fileExists = fileIo.accessSync(avatarPath)
          console.info('[MorePage] 头像文件是否存在: ' + fileExists)
          
          if (fileExists) {
            // 只有在文件存在时才创建avatar目录
            const avatarDir = `${tempDir}/avatar`
            fileIo.mkdirSync(avatarDir)
            console.info('[MorePage] 创建avatar目录: ' + avatarDir)
            
            const avatarFileName = avatarPath.split('/').pop() || 'avatar.jpg'
            const destAvatarPath = `${avatarDir}/${avatarFileName}`
            console.info('[MorePage] 目标路径: ' + destAvatarPath)
            
            fileIo.copyFileSync(avatarPath, destAvatarPath)
            
            // 验证复制是否成功
            const destExists = fileIo.accessSync(destAvatarPath)
            console.info('[MorePage] 目标文件是否存在: ' + destExists)
            
            avatarExported = true
            console.info('[MorePage] 头像文件已导出: ' + avatarFileName)
          } else {
            console.error('[MorePage] 头像文件不存在: ' + avatarPath)
          }
        } catch (avatarError) {
          console.error('[MorePage] 导出头像失败: ' + JSON.stringify(avatarError))
        }
      } else {
        console.info('[MorePage] 没有头像配置，跳过头像导出')
      }
      
      // 6. 压缩为 zip 文件
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19)
      const zipFileName = `RecordLife_all_${timestamp}.zip`
      const zipPath = `${this.context.cacheDir}/${zipFileName}`
      
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
        memLevel: zlib.MemLevel.MEM_LEVEL_DEFAULT,
        strategy: zlib.CompressStrategy.COMPRESS_STRATEGY_DEFAULT_STRATEGY
      }
      
      await zlib.compressFile(tempDir, zipPath, options)
      console.info(`[MorePage] 所有数据已打包: ${zipPath}`)
      
      // 6. 使用 DocumentViewPicker 保存文件
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
        
        console.info('[MorePage] 所有数据导出成功: ' + saveUri)
        promptAction.showToast({ message: '导出成功' })
      } else {
        console.info('[MorePage] 用户取消导出')
      }
      
      // 7. 清理临时文件
      this.deleteDirectory(tempDir)
      if (fileIo.accessSync(zipPath)) {
        fileIo.unlinkSync(zipPath)
      }
      
    } catch (error) {
      console.error('[MorePage] 导出所有数据失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
    }
  }
  
  // 导入所有（用户配置 + 此刻记录）
  private async onImportAll() {
    console.info('[MorePage] 开始导入所有数据')
    
    if (!this.configManager || !this.context) {
      promptAction.showToast({ message: '管理器未初始化' })
      return
    }
    
    try {
      // 1. 使用 DocumentViewPicker 选择文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      
      if (!uriResult || uriResult.length === 0) {
        console.info('[MorePage] 用户取消导入')
        return
      }
      
      const selectUri: string = uriResult[0]
      
      // 2. 将文件复制到沙箱临时目录
      const tempZipPath = `${this.context.cacheDir}/temp_import_all.zip`
      const srcFile = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(srcFile.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(srcFile.fd, buffer)
      fileIo.closeSync(srcFile)
      
      const destFile = fileIo.openSync(tempZipPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(destFile.fd, buffer)
      fileIo.closeSync(destFile)
      
      // 3. 解压 zip 文件
      const tempDir = `${this.context.cacheDir}/import_all_temp`
      if (fileIo.accessSync(tempDir)) {
        this.deleteDirectory(tempDir)
      }
      fileIo.mkdirSync(tempDir)
      
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION
      }
      
      await zlib.decompressFile(tempZipPath, tempDir, options)
      console.info('[MorePage] zip 文件已解压')
      
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
        
        configImported = await this.configManager.importConfig(configStr)
        console.info('[MorePage] 用户配置导入: ' + (configImported ? '成功' : '失败'))
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
        const destRecordsDir = `${this.context.filesDir}/records`
        
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
          console.info(`[MorePage] 恢复了 ${files.length} 个图片文件`)
        }
        
        // 恢复记录到 Preferences
        recordsImported = await this.restoreRecordsToPreferences(metadata.records)
        console.info('[MorePage] 记录导入: ' + (recordsImported ? '成功' : '失败'))
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
          const destAvatarPath = `${this.context.filesDir}/${avatarFileName}`
          fileIo.copyFileSync(srcAvatarPath, destAvatarPath)
          
          // 更新配置中的头像路径
          const avatarUri = fileUri.getUriFromPath(destAvatarPath)
          
          // 更新配置
          const currentConfig = this.configManager!.getConfig()
          await this.configManager!.updateProfile(
            currentConfig.profile.name,
            currentConfig.profile.birthDate,
            currentConfig.profile.gender,
            avatarUri
          )
          
          avatarImported = true
          console.info('[MorePage] 头像文件已恢复: ' + avatarFileName)
        }
      }
      
      // 7. 清理临时文件
      fileIo.unlinkSync(tempZipPath)
      this.deleteDirectory(tempDir)
      
      // 8. 显示结果
      if (configImported || recordsImported || avatarImported) {
        const messages: string[] = []
        if (configImported) messages.push('用户配置')
        if (recordsImported) messages.push('此刻记录')
        if (avatarImported) messages.push('头像')
        
        promptAction.showToast({ message: `导入成功: ${messages.join('、')}` })
        
        // 触发全局刷新
        RefreshManager.getInstance().refresh()
      } else {
        promptAction.showToast({ message: '未找到有效数据' })
      }
      
    } catch (error) {
      console.error('[MorePage] 导入所有数据失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
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
      
      const prefs = await preferences.getPreferences(this.context, STORE_NAME)
      const recordsStr = JSON.stringify(records)
      await prefs.put(RECORDS_KEY, recordsStr)
      await prefs.flush()
      
      console.info(`[MorePage] 已恢复 ${records.length} 条记录到 Preferences`)
      return true
    } catch (error) {
      console.error('[MorePage] 恢复记录到 Preferences 失败: ' + JSON.stringify(error))
      return false
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
      console.error('[MorePage] 删除目录失败: ' + JSON.stringify(error))
    }
  }
}
