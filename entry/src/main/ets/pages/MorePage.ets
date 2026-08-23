// 更多设置页面：pages/MorePage.ets
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItemWithAction } from '../components/setting/SettingItemWithAction'
import { SettingItemWithSwitch } from '../components/setting/SettingItemWithSwitch'
import { SettingItem } from '../components/setting/SettingItem'
import { SettingsGroupCard } from '../components/setting/SettingsGroupCard'
import { ConfigManager } from '../config/ConfigManager'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { BackupManager } from '../service/BackupManager'
import { MorePageBackupHandler } from '../common/handlers/MorePageBackupHandler'
import { MorePageConfigHandler } from '../common/handlers/MorePageConfigHandler'
import { CosConfig } from '../model/UserConfigModel'
import { Logger } from '../common/utils/Logger'
import { ResourceUtils } from '../common/utils/ResourceUtils'

// 导出进度弹窗（AppStorage 驱动进度与消息）
@CustomDialog
struct ExportProgressDialog {
  controller: CustomDialogController
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  @StorageLink('exportProgress') progress: number = 0
  @StorageLink('exportProgressMsg') message: string = ''

  build() {
    Column() {
      Text(this.message)
        .fontSize(15)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: 12 })

      Progress({ value: this.progress, total: 100, type: ProgressType.Linear })
        .width('100%')
        .height(6)
        .color(this.themeColors.primary)
        .backgroundColor(this.themeColors.divider)
        .borderRadius(3)
    }
    .width('72%')
    .padding(20)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
  }
}

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
      Text($r('app.string.select_export_content'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 16 })

      // 选项列表卡片（导入导出弹窗 UI 优化）
      Column() {
        SettingItem({
          label: $r('app.string.user_config'),
          summary: $r('app.string.option_config_summary'),
          icon: '⚙️',
          iconBg: '#F5F5F5'
        })
        .onClick(() => {
          this.controller.close()
          this.onExportConfig()
        })

        Divider()
          .color(this.themeColors.divider)
          .margin({ left: 15 })
          .height(0.5)

        SettingItem({
          label: $r('app.string.now_record_backup'),
          summary: $r('app.string.option_backup_summary'),
          icon: '📦',
          iconBg: '#E3F2FD'
        })
        .onClick(() => {
          this.controller.close()
          this.onExportBackup()
        })

        Divider()
          .color(this.themeColors.divider)
          .margin({ left: 15 })
          .height(0.5)

        SettingItem({
          label: $r('app.string.all'),
          summary: $r('app.string.option_all_summary'),
          icon: '🗂️',
          iconBg: '#E8F5E9'
        })
        .onClick(() => {
          this.controller.close()
          this.onExportAll()
        })
      }
      .width('100%')
      .backgroundColor(this.themeColors.background)
      .borderRadius(14)
      .padding({ left: 8, right: 8 })

      // 取消
      Button($r('app.string.cancel'))
        .width('100%')
        .height(44)
        .margin({ top: 12 })
        .backgroundColor(this.themeColors.background)
        .fontColor(this.themeColors.textSecondary)
        .borderRadius(22)
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('82%')
    .padding(20)
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
      Text($r('app.string.select_import_content'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 16 })

      // 选项列表卡片（导入导出弹窗 UI 优化）
      Column() {
        SettingItem({
          label: $r('app.string.user_config'),
          summary: $r('app.string.option_config_summary'),
          icon: '⚙️',
          iconBg: '#F5F5F5'
        })
        .onClick(() => {
          this.controller.close()
          this.onImportConfig()
        })

        Divider()
          .color(this.themeColors.divider)
          .margin({ left: 15 })
          .height(0.5)

        SettingItem({
          label: $r('app.string.now_record_backup'),
          summary: $r('app.string.option_backup_summary'),
          icon: '📥',
          iconBg: '#E3F2FD'
        })
        .onClick(() => {
          this.controller.close()
          this.onImportBackup()
        })

        Divider()
          .color(this.themeColors.divider)
          .margin({ left: 15 })
          .height(0.5)

        SettingItem({
          label: $r('app.string.all'),
          summary: $r('app.string.option_all_summary'),
          icon: '🗂️',
          iconBg: '#E0F7FA'
        })
        .onClick(() => {
          this.controller.close()
          this.onImportAll()
        })
      }
      .width('100%')
      .backgroundColor(this.themeColors.background)
      .borderRadius(14)
      .padding({ left: 8, right: 8 })

      // 取消
      Button($r('app.string.cancel'))
        .width('100%')
        .height(44)
        .margin({ top: 12 })
        .backgroundColor(this.themeColors.background)
        .fontColor(this.themeColors.textSecondary)
        .borderRadius(22)
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('82%')
    .padding(20)
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

  // 当前云存储配置（初始化时读取；声明在弹窗控制器之前，避免字段初始化顺序问题）
  @State cosConfig: CosConfig | null = null

  // 云存储总开关状态（读取自 cosConfig.enabled，默认关闭展示）
  @State cloudEnabled: boolean = false

  // 导出进度弹窗控制器（导出全部时展示打包进度）
  private exportProgressDialogController: CustomDialogController = new CustomDialogController({
    builder: ExportProgressDialog({}),
    autoCancel: false,
    customStyle: true
  })

  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      Logger.info('MorePage: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      // 初始化配置管理器
      this.configManager = await ConfigManager.getInstance(this.context)
      Logger.info('MorePage: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
      
      // 初始化备份管理器
      this.backupManager = await BackupManager.getInstance(this.context)
      Logger.info('MorePage: backupManager 已初始化 - ' + (this.backupManager ? '成功' : '失败'))

      // 读取云存储配置（图片存储优化 M2）
      this.cosConfig = this.configManager.getCosConfig()
      this.cloudEnabled = this.cosConfig ? this.cosConfig.enabled !== false : false
      Logger.info('MorePage: cosConfig - ' + (this.cosConfig ? '已配置' : '未配置') +
        ' enabled=' + this.cloudEnabled)
    } catch (error) {
      Logger.error('MorePage 初始化失败: ' + JSON.stringify(error))
    }
  }
  
  build() {
    Column() {
      // 页面标题
      Row() {
        // 返回按钮
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(24)
          .fontColor([this.themeColors.iconColor])
          .onClick(() => {
            this.goBack()
          })
        
        Text($r('app.string.more'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 12 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      
      Scroll() {
        Column() {
          // 功能列表
          this.FunctionsSection()
        }
        .width('100%')
        .margin({ top: 12 })
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
  
  // 功能列表组件（分组 + 图标容器，更多页 UI 统一，与其他页面一致）
  @Builder
  FunctionsSection() {
    Column() {
      // 分组：数据管理
      this.GroupTitle($r('app.string.settings_group_data'))
      SettingsGroupCard() {
        // 导出
        SettingItemWithAction({
          label: $r('app.string.export'),
          summary: $r('app.string.export_summary'),
          icon: '📤',
          iconBg: '#E3F2FD',
          onAction: () => {
            this.showExportDialog()
          }
        })

        Divider()
          .color(this.themeColors.divider)
          .height(0.5)

        // 导入
        SettingItemWithAction({
          label: $r('app.string.import'),
          summary: $r('app.string.import_summary'),
          icon: '📥',
          iconBg: '#E8F5E9',
          onAction: () => {
            this.showImportDialog()
          }
        })

        Divider()
          .color(this.themeColors.divider)
          .height(0.5)

        // 云存储（图片存储优化 M2：本地压缩 + 云端原图；行右侧总开关，点击行打开配置）
        SettingItemWithSwitch({
          label: $r('app.string.cloud_storage'),
          summary: $r('app.string.cloud_storage_summary'),
          icon: '☁️',
          iconBg: '#E1F5FE',
          isOn: this.cloudEnabled,
          onChange: (isOn: boolean) => {
            this.onCloudSwitchChange(isOn)
          }
        })
        .onClick(() => {
          this.showCloudDialog()
        })
      }

      // 分组：危险操作
      this.GroupTitle($r('app.string.settings_group_danger'))
      SettingsGroupCard() {
        // 重置应用
        SettingItemWithAction({
          label: $r('app.string.reset_app'),
          summary: $r('app.string.reset_summary'),
          isDestructive: true,
          icon: '🗑️',
          iconBg: '#FFEBEE',
          onAction: () => {
            this.onResetApp()
          }
        })
      }
    }
    .width('100%')
  }

  // 设置分组标题（与 90% 卡片左缘对齐，与其他页面一致）
  @Builder
  GroupTitle(title: ResourceStr) {
    Text(title)
      .fontSize(13)
      .fontColor(this.themeColors.textSecondary)
      .width('90%')
      .alignSelf(ItemAlign.Center)
      .padding({ left: 12, top: 10, bottom: 4 })
  }
  
  // 显示导出选择对话框
  private showExportDialog() {
    this.exportDialogController.open()
  }
  
  // 显示导入选择对话框
  private showImportDialog() {
    this.importDialogController.open()
  }

  // 打开云存储设置页面（图片存储优化：弹窗改为独立可滚动页面）
  private showCloudDialog() {
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/CloudStoragePage'
      })
    } catch (error) {
      Logger.error('页面跳转失败: ' + JSON.stringify(error))
    }
  }

  // 云存储总开关切换（配置保留，仅启停）
  private async onCloudSwitchChange(isOn: boolean) {
    this.cloudEnabled = isOn
    if (!this.configManager) {
      return
    }
    const cur: CosConfig = this.cosConfig ? this.cosConfig :
      { region: '', bucket: '', secretId: '', secretKey: '' }
    cur.enabled = isOn
    this.cosConfig = cur
    await this.configManager.setCosConfig(cur)
  }

  // 返回处理
  private goBack() {
    this.getUIContext().getRouter().back()
  }
  
  // 导出配置处理
  private async onExportConfig() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageConfigHandler.exportConfig(this.context, this.configManager, this.promptAction)
  }
  
  // 导入配置处理
  private async onImportConfig() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.config_manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageConfigHandler.importConfig(this.context, this.configManager, this.promptAction)
  }
  
  // 导出备份处理
  private async onExportBackup() {
    if (!this.backupManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.exportBackup(this.context, this.backupManager, this.promptAction)
  }
  
  // 导入备份处理
  private async onImportBackup() {
    if (!this.backupManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.importBackup(this.context, this.backupManager, this.promptAction)
  }
  
  // 导出所有处理（带打包进度弹窗）
  private async onExportAll() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    // 显示导出进度弹窗
    AppStorage.setOrCreate('exportProgress', 5)
    AppStorage.setOrCreate('exportProgressMsg', ResourceUtils.getString(this.context.resourceManager, 'export_progress_config'))
    this.exportProgressDialogController.open()
    
    try {
      await MorePageBackupHandler.exportAll(
        this.context,
        this.configManager,
        this.promptAction,
        (percent: number, message: string) => {
          AppStorage.setOrCreate('exportProgress', percent)
          AppStorage.setOrCreate('exportProgressMsg', message)
        }
      )
    } finally {
      // 无论成功失败都关闭进度弹窗
      this.exportProgressDialogController.close()
      AppStorage.setOrCreate('exportProgress', 0)
      AppStorage.setOrCreate('exportProgressMsg', '')
    }
  }
  
  // 导入所有处理
  private async onImportAll() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
      }
      return
    }
    
    await MorePageBackupHandler.importAll(this.context, this.configManager, this.promptAction)
  }
  
  // 重置应用处理
  private async onResetApp() {
    if (!this.configManager || !this.context) {
      try {
        this.promptAction.showToast({ message: $r('app.string.manager_not_initialized') })
      } catch (error) {
        Logger.error('MorePage: showToast 失败: ' + JSON.stringify(error))
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
