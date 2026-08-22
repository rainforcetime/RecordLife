// 心情选择器组件（更新计划二期：心情标记）
// 一排 emoji 圆钮单选，再点已选项取消（selectedMood = ''）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { MoodUtils } from '../../common/utils/MoodUtils'

@Component
export struct MoodSelector {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 选中心情（'' = 未选择）；双向绑定
  @Link selectedMood: string

  // 读取心情名称资源（国际化）
  private getMoodName(mood: string): string {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (!rm) {
      return ''
    }
    switch (mood) {
      case 'happy':
        return rm.getStringByNameSync('mood_happy')
      case 'calm':
        return rm.getStringByNameSync('mood_calm')
      case 'excited':
        return rm.getStringByNameSync('mood_excited')
      case 'sad':
        return rm.getStringByNameSync('mood_sad')
      case 'tired':
        return rm.getStringByNameSync('mood_tired')
      default:
        return ''
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

      // 心情选项行
      Row({ space: 10 }) {
        ForEach(MoodUtils.MOODS, (mood: string) => {
          Column() {
            Text(MoodUtils.getMoodEmoji(mood))
              .fontSize(24)
            Text(this.getMoodName(mood))
              .fontSize(11)
              .fontColor(this.selectedMood === mood ? this.themeColors.primary : this.themeColors.textSecondary)
              .margin({ top: 4 })
          }
          .width(56)
          .padding({ top: 10, bottom: 10 })
          .alignItems(HorizontalAlign.Center)
          .backgroundColor(this.selectedMood === mood ? this.themeColors.primaryLight : this.themeColors.background)
          .borderRadius(12)
          .border({
            width: this.selectedMood === mood ? 1.5 : 1,
            color: this.selectedMood === mood ? this.themeColors.primary : this.themeColors.border
          })
          .onClick(() => {
            // 再点已选项 → 取消
            this.selectedMood = this.selectedMood === mood ? '' : mood
          })
        }, (mood: string) => mood)
      }
      .width('100%')
      .justifyContent(FlexAlign.Start)
    }
    .width('100%')
  }
}
