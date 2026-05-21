// 关于应用对话框组件
import { AppInfo } from '../config/UserConfig'
import { AppInfoManager } from '../config/AppInfoConfig'

@CustomDialog
export struct AboutAppDialog {
  controller: CustomDialogController
  @Prop appInfo: AppInfo = {
    appName: '活着',
    appVersion: '0.0.1',
    buildNumber: '20260521',
    developer: 'rainforcetime',
    website: 'https://github.com/rainforcetime/record-life',
    description: '记录生活，珍惜每一刻'
  }
  
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
          .margin({ bottom: 5 })

        Text(`版本 ${this.appInfo.appVersion}`)
          .fontSize(14)
          .fontColor('#666666')
          .margin({ bottom: 5 })

        Text(`Build ${this.appInfo.buildNumber}`)
          .fontSize(12)
          .fontColor('#999999')
      }
      .margin({ bottom: 20 })

      Divider().margin({ left: 20, right: 20 })

      // 应用信息列表
      Column() {
        // 应用描述
        this.InfoItem('应用描述', this.appInfo.description)

        Divider().margin({ left: 15 })

        // 开发者
        this.InfoItem('开发者', this.appInfo.developer)

        Divider().margin({ left: 15 })

        // 官网
        this.InfoItem('官方网站', this.appInfo.website)
      }
      .width('100%')
      .backgroundColor(Color.White)
      .borderRadius(10)
      .margin({ left: 20, right: 20, top: 15 })
      .padding({ top: 10, bottom: 10 })

      // 关闭按钮
      Button('关闭')
        .width('90%')
        .height(45)
        .fontSize(16)
        .backgroundColor('#007DFF')
        .fontColor(Color.White)
        .borderRadius(22)
        .margin({ top: 20, bottom: 20 })
        .onClick(() => {
          this.controller.close()
        })
    }
    .width('90%')
    .backgroundColor('#F5F5F5')
    .borderRadius(20)
  }

  @Builder
  InfoItem(label: string, value: string) {
    Row() {
      Text(label)
        .fontSize(14)
        .fontColor('#666666')
        .width(80)

      Text(value)
        .fontSize(14)
        .fontColor('#333333')
        .layoutWeight(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .maxLines(2)
    }
    .width('100%')
    .padding({ left: 15, right: 15, top: 12, bottom: 12 })
  }
}
