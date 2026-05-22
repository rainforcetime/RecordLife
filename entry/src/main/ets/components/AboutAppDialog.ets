// 关于应用对话框组件
import { AppInfo } from '../config/UserConfig'
import { AppInfoManager } from '../config/AppInfoConfig'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'

@CustomDialog
export struct AboutAppDialog {
  controller: CustomDialogController
  @Prop appInfo: AppInfo = {
    appName: '活着',
    appVersion: '0.0.1',
    buildNumber: '20260521',
    developer: 'rainforcetime',
    website: 'https://github.com/rainforcetime/RecordLife',
    description: '记录生活，珍惜每一刻'
  }
  @Prop themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 应用信息管理器
  private appInfoManager: AppInfoManager | null = null
  
  async aboutToAppear() {
    try {
      this.appInfoManager = await AppInfoManager.getInstance()
      const config = this.appInfoManager.getAppInfo()
      this.appInfo = {
        appName: config.appName,
        appVersion: config.appVersion,
        buildNumber: config.buildNumber,
        developer: config.developer,
        website: config.website,
        description: config.description
      }
    } catch (error) {
      console.error('加载应用信息失败: ' + JSON.stringify(error))
    }
  }

  build() {
    Column() {
      // 标题
      Text('关于应用')
        .fontSize(22)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 20, bottom: 20 })

      // 应用图标和名称
      Column() {
        Image($r('app.media.startIcon'))
          .width(80)
          .height(80)
          .borderRadius(16)
          .margin({ bottom: 15 })

        Text(this.appInfo.appName)
          .fontSize(20)
          .fontWeight(FontWeight.Medium)
          .fontColor(this.themeColors.textPrimary)
          .margin({ bottom: 5 })

        Text(`版本 ${this.appInfo.appVersion}`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .margin({ bottom: 5 })

        Text(`Build ${this.appInfo.buildNumber}`)
          .fontSize(12)
          .fontColor(this.themeColors.textTertiary)
      }
      .margin({ bottom: 20 })

      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 20, right: 20 })

      // 应用信息列表
      Column() {
        // 应用描述
        this.InfoItem('应用描述', this.appInfo.description)

        Divider()
          .color(this.themeColors.divider)
          .margin({ left: 15 })

        // 开发者
        this.InfoItem('开发者', this.appInfo.developer)

        Divider()
          .color(this.themeColors.divider)
          .margin({ left: 15 })

        // 官网
        this.InfoItem('官方网站', this.appInfo.website, () => {
          let context = this.getUIContext().getHostContext() as common.UIAbilityContext
          context.openLink(this.appInfo.website, { appLinkingOnly: false })
            .catch((error: BusinessError) => {
              console.error('打开链接失败: ' + JSON.stringify(error))
            })
        })
      }
      .width('100%')
      .backgroundColor(this.themeColors.cardBackground)
      .borderRadius(10)
      .margin({ left: 20, right: 20, top: 15 })
      .padding({ top: 10, bottom: 10 })

      // 关闭按钮
      Button('关闭')
        .width('90%')
        .height(45)
        .fontSize(16)
        .backgroundColor(this.themeColors.primary)
        .fontColor(Color.White)
        .borderRadius(22)
        .margin({ top: 20, bottom: 20 })
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('90%')
    .backgroundColor(this.themeColors.background)
    .borderRadius(20)
  }

  @Builder
  InfoItem(label: string, value: string, onClick?: () => void) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor(onClick ? this.themeColors.primary : this.themeColors.textPrimary)
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
    .onClick(() => {
      if (onClick) {
        onClick()
      }
    })
  }
}
