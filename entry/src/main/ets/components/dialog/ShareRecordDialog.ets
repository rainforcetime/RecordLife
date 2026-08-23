import { common } from '@kit.AbilityKit'
import { LifeRecord } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { ShareRecordCard } from '../share/ShareRecordCard'
import { ShareUtils } from '../../common/utils/ShareUtils'
import { ResourceUtils } from '../../common/utils/ResourceUtils'
import { Logger } from '../../common/utils/Logger'

/**
 * 记录分享弹窗（更新计划五期：两处分享统一为 CustomDialog，居中缩放淡入动画）
 * 供截图组件 ShareRecordCard 展示 + 系统分享
 */
@CustomDialog
export struct ShareRecordDialog {
  controller: CustomDialogController

  // 分享的记录（由调用方传入；CustomDialog 输入属性需默认值）
  record: LifeRecord = { id: '', timestamp: 0, content: '' }

  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  @State isSharing: boolean = false

  build() {
    Column() {
      // 分享卡片预览区域（可滚动）
      Scroll() {
        Column() {
          ShareRecordCard({ record: this.record })
            .id(`share_card_${this.record.id}`)
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
          .backgroundColor(this.isSharing ? this.themeColors.textTertiary : this.themeColors.primary)
          .borderRadius(22)
          .enabled(!this.isSharing)
          .onClick(() => {
            this.doShare()
          })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 16 })
    }
    .width(360)
    .backgroundColor(this.themeColors.background)
    .borderRadius(4)
  }

  // 执行分享
  private async doShare() {
    if (this.isSharing) {
      return
    }
    this.isSharing = true
    Logger.info('[ShareRecordDialog] 开始分享，记录ID: ' + this.record.id)

    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const success = await ShareUtils.shareComponent(
        this.getUIContext(),
        `share_card_${this.record.id}`,
        context,
        ResourceUtils.getString(context.resourceManager, 'share_record_title'),
        ResourceUtils.getString(context.resourceManager, 'share_description_default')
      )

      if (success) {
        Logger.info('[ShareRecordDialog] 分享成功')
        // 延迟关闭弹窗，让用户看到分享成功
        setTimeout(() => {
          this.controller.close()
          this.isSharing = false
        }, 500)
      } else {
        Logger.error('[ShareRecordDialog] 分享失败')
        this.isSharing = false
      }
    } catch (error) {
      Logger.error('[ShareRecordDialog] 分享异常: ' + JSON.stringify(error))
      this.isSharing = false
    }
  }
}
