// 更多设置页面：pages/MorePage.ets
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItemWithAction } from '../components/setting/SettingItemWithAction'
import { ConfigManager } from '../config/ConfigManager'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { BackupManager } from '../common/managers/BackupManager'
import { MorePageBackupHandler } from '../common/handlers/MorePageBackupHandler'
import { MorePageConfigHandler } from '../common/handlers/MorePageConfigHandler'

@Entry
@Component
struct MorePage {
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
    this.getUIContext().getRouter().back()
  }
  
  // 导出配置处理
  private async onExportConfig() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageConfigHandler.exportConfig(this.context, this.configManager, this.promptAction)
  }
  
  // 导入配置处理
  private async onImportConfig() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '配置管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageConfigHandler.importConfig(this.context, this.configManager, this.promptAction)
  }
  
  // 导出备份处理
  private async onExportBackup() {
    if (!this.backupManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.exportBackup(this.context, this.backupManager, this.promptAction)
  }
  
  // 导入备份处理
  private async onImportBackup() {
    if (!this.backupManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.importBackup(this.context, this.backupManager, this.promptAction)
  }
  
  // 导出所有处理
  private async onExportAll() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.exportAll(this.context, this.configManager, this.promptAction)
  }
  
  // 导入所有处理
  private async onImportAll() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.importAll(this.context, this.configManager, this.promptAction)
  }
  
  // 重置应用处理
  private async onResetApp() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: '管理器未初始化' })
      } catch (error) {
        console.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageConfigHandler.resetApp(
      this.context,
      this.configManager,
      this.promptAction,
      this.getUIContext()
    )
  }
}
