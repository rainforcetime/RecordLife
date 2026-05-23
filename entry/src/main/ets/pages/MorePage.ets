// 更多设置页面：pages/MorePage.ets
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItemWithAction } from '../components/setting/SettingItemWithAction'
import { ConfigManager } from '../config/ConfigManager'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { BackupManager } from '../common/managers/BackupManager'
import { MorePageBackupHandler } from '../common/handlers/MorePageBackupHandler'
import { MorePageConfigHandler } from '../common/handlers/MorePageConfigHandler'

// 导出选项弹窗
@CustomDialog
struct ExportOptionDialog {
  controller: CustomDialogController
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onExportConfig: () => void = () => {}
  onExportBackup: () => void = () => {}
  onExportAll: () => void = () => {}

  build() {
    Column() {
      Text('选择导出内容')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 20 })

      Button('用户配置')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .fontColor(this.themeColors.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
          this.onExportConfig()
        })

      Blank().height(12)

      Button('此刻记录备份')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .fontColor(this.themeColors.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
          this.onExportBackup()
        })

      Blank().height(12)

      Button('所有')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .fontColor(this.themeColors.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
          this.onExportAll()
        })

      Blank().height(12)

      Button('取消')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.divider)
        .fontColor(this.themeColors.textSecondary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('80%')
    .padding(24)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
  }
}

// 导入选项弹窗
@CustomDialog
struct ImportOptionDialog {
  controller: CustomDialogController
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onImportConfig: () => void = () => {}
  onImportBackup: () => void = () => {}
  onImportAll: () => void = () => {}

  build() {
    Column() {
      Text('选择导入内容')
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 20 })

      Button('用户配置')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .fontColor(this.themeColors.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
          this.onImportConfig()
        })

      Blank().height(12)

      Button('此刻记录备份')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .fontColor(this.themeColors.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
          this.onImportBackup()
        })

      Blank().height(12)

      Button('所有')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.cardBackground)
        .fontColor(this.themeColors.textPrimary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
          this.onImportAll()
        })

      Blank().height(12)

      Button('取消')
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.divider)
        .fontColor(this.themeColors.textSecondary)
        .borderRadius(8)
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('80%')
    .padding(24)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
  }
}

@Entry
@Component
struct MorePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private backupManager: BackupManager | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()
  
  // 导出弹窗控制器
  private exportDialogController: CustomDialogController = new CustomDialogController({
    builder: ExportOptionDialog({
      onExportConfig: () => {
        this.onExportConfig()
      },
      onExportBackup: () => {
        this.onExportBackup()
      },
      onExportAll: () => {
        this.onExportAll()
      }
    }),
    autoCancel: true,
    customStyle: true
  })
  
  // 导入弹窗控制器
  private importDialogController: CustomDialogController = new CustomDialogController({
    builder: ImportOptionDialog({
      onImportConfig: () => {
        this.onImportConfig()
      },
      onImportBackup: () => {
        this.onImportBackup()
      },
      onImportAll: () => {
        this.onImportAll()
      }
    }),
    autoCancel: true,
    customStyle: true
  })
  
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
      // 导出
      SettingItemWithAction({
        label: '导出',
        summary: '导出用户配置、此刻记录备份或所有数据',
        onAction: () => {
          this.showExportDialog()
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
      
      // 导入
      SettingItemWithAction({
        label: '导入',
        summary: '导入用户配置、此刻记录备份或所有数据',
        onAction: () => {
          this.showImportDialog()
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
  
  // 显示导出选择对话框
  private showExportDialog() {
    this.exportDialogController.open()
  }
  
  // 显示导入选择对话框
  private showImportDialog() {
    this.importDialogController.open()
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
