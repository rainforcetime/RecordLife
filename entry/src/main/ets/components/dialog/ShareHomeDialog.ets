import { common } from '@kit.AbilityKit'
import { TimeData } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { ShareHomeCard } from '../share/ShareHomeCard'
import { ShareUtils } from '../../common/utils/ShareUtils'
import { ResourceUtils } from '../../common/utils/ResourceUtils'
import { Logger } from '../../common/utils/Logger'

/**
 * 首页分享弹窗（更新计划五期：两处分享统一为 CustomDialog，居中缩放淡入动画）
 * 供截图组件 ShareHomeCard 展示 + 系统分享
 */
@CustomDialog
export struct ShareHomeDialog {
  controller: CustomDialogController

  // 分享数据（由调用方传入；CustomDialog 输入属性需默认值）
  birthDate: Date = new Date()
  targetAge: number = 80
  timeData: TimeData = { years: 0, months: 0, days: 0, hours: 0, minutes: 0, seconds: 0 }
  isRemainingMode: boolean = false
  isAccumulatedMode: boolean = false

  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  @State isSharing: boolean = false

  build() {
    Column() {
      // 分享卡片预览区域（可滚动）
      Scroll() {
        Column() {
          ShareHomeCard({
            birthDate: this.birthDate,
            targetAge: this.targetAge,
            timeData: this.timeData,
            isRemainingMode: this.isRemainingMode,
            isAccumulatedMode: this.isAccumulatedMode
          })
            .id('share-home-card')
        }
        .width('100%')
        .alignItems(HorizontalAlign.Center)
        .padding({ top: 16, bottom: 16 })
      }
      .width('100%')
      .scrollBar(BarState.Off)
      .constraintSize({ maxHeight: '60%' })

      // 操作按钮
      Row({ space: 12 }) {
        Button($r('app.string.cancel'))
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor(this.themeColors.textSecondary)
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(22)
          .enabled(!this.isSharing)
          .onClick(() => {
            this.controller.close()
          })

        Button(this.isSharing ? $r('app.string.sharing_in_progress') : $r('app.string.share'))
          .layoutWeight(1)
          .height(44)
          .fontSize(16)
          .fontColor('#FFFFFF')
          .backgroundColor(this.isSharing ? this.themeColors.textSecondary : this.themeColors.error)
          .borderRadius(22)
          .enabled(!this.isSharing)
          .onClick(() => {
            this.doShare()
          })
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 20 })
    }
    .width('90%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(4)
  }

  // 执行分享
  private async doShare() {
    if (this.isSharing) {
      return
    }
    this.isSharing = true
    Logger.info('[ShareHomeDialog] 开始分享')

    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext

      // 执行分享
      const success = await ShareUtils.shareComponent(
        this.getUIContext(),
        'share-home-card',
        context,
        ResourceUtils.getString(context.resourceManager, 'share_title'),
        ResourceUtils.getString(context.resourceManager, 'share_description')
      )

      if (success) {
        Logger.info('[ShareHomeDialog] 分享成功')
        setTimeout(() => {
          this.controller.close()
          this.isSharing = false
        }, 500)
      } else {
        Logger.error('[ShareHomeDialog] 分享失败')
        this.isSharing = false
      }
    } catch (error) {
      Logger.error('[ShareHomeDialog] 分享异常: ' + JSON.stringify(error))
      this.isSharing = false
    }
  }
}
