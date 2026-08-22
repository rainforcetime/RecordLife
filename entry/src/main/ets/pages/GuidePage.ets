// 引导页：pages/GuidePage.ets（更新计划四期）
// 首次安装启动展示，滑动介绍应用功能，看完标记后进入主页
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { GuideRepository } from '../repository/GuideRepository'
import { Logger } from '../common/utils/Logger'

// 引导项
interface GuideItem {
  icon: string
  title: ResourceStr
  desc: ResourceStr
}

@Entry
@Component
struct GuidePage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 当前滑动页索引
  @State currentIndex: number = 0

  // 引导内容（4 页）
  private guideItems: GuideItem[] = [
    {
      icon: '📝',
      title: $r('app.string.guide_title_1'),
      desc: $r('app.string.guide_desc_1')
    },
    {
      icon: '📅',
      title: $r('app.string.guide_title_2'),
      desc: $r('app.string.guide_desc_2')
    },
    {
      icon: '⏳',
      title: $r('app.string.guide_title_3'),
      desc: $r('app.string.guide_desc_3')
    },
    {
      icon: '🔒',
      title: $r('app.string.guide_title_4'),
      desc: $r('app.string.guide_desc_4')
    }
  ]

  build() {
    Column() {
      // 滑动内容区
      Swiper() {
        ForEach(this.guideItems, (item: GuideItem, index: number) => {
          Column() {
            Text(item.icon)
              .fontSize(80)
              .margin({ bottom: 24 })

            Text(item.title)
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor(this.themeColors.textPrimary)
              .textAlign(TextAlign.Center)

            Text(item.desc)
              .fontSize(15)
              .fontColor(this.themeColors.textSecondary)
              .textAlign(TextAlign.Center)
              .margin({ top: 12, left: 40, right: 40 })
          }
          .width('100%')
          .height('100%')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
        }, (item: GuideItem, index: number) => `guide-${index}`)
      }
      .index(this.currentIndex)
      .onChange((index: number) => {
        this.currentIndex = index
      })
      .indicator(false)
      .width('100%')
      .layoutWeight(1)

      // 圆点指示器
      Row() {
        ForEach(this.guideItems, (item: GuideItem, index: number) => {
          Column()
            .width(this.currentIndex === index ? 20 : 8)
            .height(8)
            .borderRadius(4)
            .backgroundColor(this.currentIndex === index ? this.themeColors.primary : this.themeColors.divider)
            .margin({ right: 6 })
        }, (item: GuideItem, index: number) => `dot-${index}`)
      }
      .width('100%')
      .justifyContent(FlexAlign.Center)
      .margin({ bottom: 24 })

      // 操作按钮（最后一页显示「开始使用」，其余显示「跳过」）
      if (this.currentIndex === this.guideItems.length - 1) {
        Button($r('app.string.guide_start'))
          .width('70%')
          .height(46)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.themeColors.primary)
          .borderRadius(23)
          .margin({ bottom: 40 })
          .onClick(() => {
            this.startUsing()
          })
      } else {
        Text($r('app.string.guide_skip'))
          .fontSize(15)
          .fontColor(this.themeColors.textSecondary)
          .padding({ left: 24, right: 24, top: 10, bottom: 10 })
          .margin({ bottom: 40 })
          .onClick(() => {
            this.startUsing()
          })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }

  // 标记已看过引导并进入主页（@Entry 页面不能用 router 跳转 @Entry 页面，改用 loadContent 切换）
  private async startUsing() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      await GuideRepository.markGuideSeen(context)
      Logger.info('[GuidePage] 引导完成，进入主页')
      // 通过 windowStage.loadContent 切换到主页（替换当前页面，不再返回引导页）
      const windowStage = context.getWindowStage()
      windowStage.loadContent('pages/Index', (err) => {
        if (err.code) {
          Logger.error('[GuidePage] loadContent 主页失败: ' + JSON.stringify(err))
        }
      })
    } catch (error) {
      Logger.error('[GuidePage] 进入主页异常: ' + JSON.stringify(error))
    }
  }
}
