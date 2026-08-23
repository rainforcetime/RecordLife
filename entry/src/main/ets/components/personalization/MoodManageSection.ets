// 个性化管理 - 心情管理组件（页面化拆分，个性化管理 UI 优化）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { MoodService } from '../../service/MoodService'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { Mood } from '../../model/RecordModel'
import { common } from '@kit.AbilityKit'
import { RefreshManager } from '../../common/managers/RefreshManager'
import { Logger } from '../../common/utils/Logger'

@Component
export struct MoodManageSection {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 自定义心情
  @State private customMoods: Mood[] = []
  @State private showMoodPicker: boolean = false
  private moodService: MoodService | null = null

  aboutToAppear() {
    this.initService()
  }

  private async initService() {
    try {
      this.moodService = await MoodService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadMoods()
    } catch (error) {
      Logger.error('[MoodManageSection] 初始化心情服务失败: ' + JSON.stringify(error))
    }
  }

  private loadMoods() {
    if (this.moodService) {
      this.customMoods = [...this.moodService.getCustomMoods()]
    }
  }

  // 添加自定义心情
  private async addMood(emoji: string) {
    if (!this.moodService) {
      return
    }
    await this.moodService.addCustomMood(emoji)
    this.loadMoods()
    RefreshManager.getInstance().refresh()
  }

  // 删除自定义心情（二次确认）
  private confirmDeleteMood(mood: Mood) {
    this.getUIContext().showAlertDialog({
      title: $r('app.string.confirm_delete'),
      message: $r('app.string.confirm_delete_message'),
      primaryButton: {
        value: $r('app.string.cancel'),
        action: () => {
        }
      },
      secondaryButton: {
        value: $r('app.string.delete'),
        fontColor: Color.Red,
        action: () => {
          this.deleteMood(mood)
        }
      }
    })
  }

  // 删除自定义心情
  private async deleteMood(mood: Mood) {
    if (!this.moodService) {
      return
    }
    await this.moodService.deleteCustomMood(mood.id)
    this.loadMoods()
    RefreshManager.getInstance().refresh()
  }

  build() {
    Column() {
      // 添加心情按钮
      Row() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(18)
          .fontColor([this.themeColors.primary])

        Text($r('app.string.mood_custom_hint'))
          .fontSize(13)
          .fontColor(this.themeColors.primary)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })
      .onClick(() => {
        this.showMoodPicker = !this.showMoodPicker
      })

      // 心情列表（预置 + 自定义）
      Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
        ForEach(MoodUtils.getAllMoods(this.customMoods), (mood: Mood) => {
          Stack({ alignContent: Alignment.TopEnd }) {
            Column() {
              Text(mood.emoji)
                .fontSize(24)
            }
            .width(44)
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.themeColors.background)
            .border({ width: 1, color: this.themeColors.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 自定义心情可删除（预置不可删）
            if (mood.id.startsWith('mood_')) {
              Column() {
                Text('×')
                  .fontSize(12)
                  .fontColor('#FFFFFF')
              }
              .width(16)
              .height(16)
              .borderRadius(8)
              .backgroundColor(this.themeColors.error)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.confirmDeleteMood(mood)
              })
            }
          }
          .width(48)
          .height(48)
          .margin({ right: 8, bottom: 8 })
        }, (mood: Mood) => mood.id)
      }
      .width('100%')

      // emoji 选择面板（添加自定义心情）
      if (this.showMoodPicker) {
        Text($r('app.string.mood_picker_hint'))
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
          .margin({ top: 4, bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
          ForEach(MoodUtils.PRESET_MOOD_EMOJIS, (emoji: string) => {
            Column() {
              Text(emoji)
                .fontSize(20)
            }
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor(this.themeColors.background)
            .border({ width: 1, color: this.themeColors.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.addMood(emoji)
            })
          }, (emoji: string) => emoji)
        }
        .width('100%')
        .margin({ bottom: 8 })
      }
    }
    .width('100%')
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.97, y: 0.97 }))
        .animation({ duration: 200, curve: Curve.EaseOut })
    )
  }
}
