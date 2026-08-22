// 心情选择器组件（更新计划二期：心情标记 + 自定义心情）
// 一排 emoji 圆钮单选，再点已选项取消（selectedMood = ''）；含预置 + 自定义心情
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { MoodService } from '../../service/MoodService'
import { Mood } from '../../model/RecordModel'
import { common } from '@kit.AbilityKit'
import { Logger } from '../../common/utils/Logger'

@Component
export struct MoodSelector {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 选中心情（'' = 未选择）；双向绑定
  @Link selectedMood: string

  // 全部心情（预置 + 自定义）
  @State private moods: Mood[] = MoodUtils.getAllMoods()

  // MoodService
  private moodService: MoodService | null = null

  async aboutToAppear() {
    try {
      this.moodService = await MoodService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.moods = MoodUtils.getAllMoods(this.moodService.getCustomMoods())
    } catch (error) {
      Logger.error('[MoodSelector] 加载自定义心情失败: ' + JSON.stringify(error))
    }
  }

  build() {
    Column() {
      // 标题
      Text($r('app.string.mood_label'))
        .fontSize(14)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      // 心情选项行（emoji，可横向滚动）
      Scroll() {
        Row({ space: 10 }) {
          ForEach(this.moods, (mood: Mood) => {
            Column() {
              Text(mood.emoji)
                .fontSize(26)
            }
            .width(48)
            .height(48)
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .backgroundColor(this.selectedMood === mood.id ? this.themeColors.primaryLight : this.themeColors.background)
            .borderRadius(24)
            .border({
              width: this.selectedMood === mood.id ? 1.5 : 1,
              color: this.selectedMood === mood.id ? this.themeColors.primary : this.themeColors.border
            })
            .onClick(() => {
              // 再点已选项 → 取消
              this.selectedMood = this.selectedMood === mood.id ? '' : mood.id
            })
          }, (mood: Mood) => mood.id)
        }
        .padding({ right: 4 })
      }
      .scrollable(ScrollDirection.Horizontal)
      .scrollBar(BarState.Off)
      .width('100%')
    }
    .width('100%')
  }
}
