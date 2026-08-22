// 心情筛选栏组件（更新计划二期：心情标记筛选）
// 一排 chips：全部 + 5 个心情 emoji，单选
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { ColorUtils } from '../../common/ColorUtils'

@Component
export struct MoodFilterBar {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 选中的心情（'' = 全部）；双向绑定
  @Link filterMood: string

  build() {
    Scroll() {
      Row({ space: 8 }) {
        // 全部
        this.MoodChip('', $r('app.string.mood_filter_all'))
        // 各心情
        ForEach(MoodUtils.MOODS, (mood: string) => {
          this.MoodChip(mood, MoodUtils.getMoodEmoji(mood))
        }, (mood: string) => mood)
      }
      .padding({ left: 4, right: 4 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  MoodChip(value: string, label: ResourceStr) {
    Row() {
      Text(label)
        .fontSize(15)
        .fontColor(this.filterMood === value ? '#FFFFFF' : this.themeColors.textPrimary)
    }
    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
    .backgroundColor(this.filterMood === value ? this.themeColors.primary : ColorUtils.primaryExtraLight(this.themeColors.primary))
    .borderRadius(16)
    .onClick(() => {
      // 再点已选项 → 回到全部
      this.filterMood = this.filterMood === value ? '' : value
    })
  }
}
