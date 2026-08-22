// 统一筛选栏组件：components/record/FilterBar.ets
// 合并标签筛选 + 心情筛选（更新计划二期）：单行横向滚动，视觉统一
// 交互：心情单选（再点取消）、标签单选（再点取消）、"全部"清除所有筛选；心情与标签可叠加过滤
// 说明：chip 为独立组件 FilterChip（@Prop isSelected 响应式）——@Builder 按值传参不随状态刷新，故不用 @Builder
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag, DEFAULT_TAGS } from '../../common/types'
import { buildDisplayTags } from '../../common/utils/TagDisplayUtils'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { TagService } from '../../service/TagService'
import { MoodService } from '../../service/MoodService'
import { Mood } from '../../model/RecordModel'
import { common } from '@kit.AbilityKit'
import { promptAction, display } from '@kit.ArkUI'
import { ColorUtils } from '../../common/ColorUtils'
import { Logger } from '../../common/utils/Logger'

// 筛选 chip（独立组件：@Prop isSelected 随父状态响应式更新）
@Component
export struct FilterChip {
  label: ResourceStr = ''
  color: string = '#909399'
  @Prop isSelected: boolean = false
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  // 注意：不能命名为 onClick（与组件基类事件属性冲突，ArkTS 编译错误）
  onChipClick?: () => void

  // 判断是否深色模式
  private isDarkMode(): boolean {
    return this.themeColors.textPrimary === '#FFFFFF'
  }

  // 将十六进制颜色转换为 rgba 格式
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  // 获取未选中背景色
  private getUnselectedBackground(): string {
    if (this.isDarkMode()) {
      return this.hexToRgba(this.color, 0.2)
    }
    return this.hexToRgba(this.color, 0.12)
  }

  build() {
    Text(this.label)
      .fontSize(12)
      .fontColor(this.isSelected ? '#FFFFFF' : this.color)
      .fontWeight(this.isSelected ? FontWeight.Bold : FontWeight.Normal)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(this.isSelected ? this.color : this.getUnselectedBackground())
      .borderRadius(14)
      // 选中态：白色描边 + 阴影（emoji 无法通过 fontColor 变色，靠描边/背景明确选中）
      .border({
        width: 1.5,
        color: this.isSelected ? '#FFFFFF' : '#00000000'
      })
      .shadow({
        radius: 4,
        color: this.isSelected ? '#33000000' : '#00000000',
        offsetX: 0,
        offsetY: 2
      })
      .margin({ right: 8 })
      .onClick(() => {
        if (this.onChipClick) {
          this.onChipClick()
        }
      })
  }
}

@Component
export struct FilterBar {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 已选中的标签ID列表（双向绑定，单选）
  @Link selectedTagIds: string[]

  // 选中的心情（双向绑定，'' = 全部；更新计划二期）
  @Link filterMood: string

  // 筛选变化回调
  onChange?: () => void

  // 筛选气泡开关（更新计划五期：紧贴按钮向下弹出）
  @State private showFilterPopup: boolean = false

  // 可用标签（内部动态加载）
  @State availableTags: Tag[] = DEFAULT_TAGS

  // 全部心情（预置 + 自定义，更新计划二期）
  @State private moods: Mood[] = MoodUtils.getAllMoods()

  // 标签版本号（由父组件传入，变化时重新加载）
  @Watch('onTagVersionChange')
  @Prop tagVersion: number = 0

  // TagService
  private tagService: TagService | null = null

  // MoodService（更新计划二期）
  private moodService: MoodService | null = null

  // 是否无任何筛选（"全部"选中态）
  private isNoFilter(): boolean {
    return this.selectedTagIds.length === 0 && this.filterMood.length === 0
  }

  async aboutToAppear() {
    try {
      this.tagService = await TagService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadTags()
      // 加载自定义心情（更新计划二期）
      this.moodService = await MoodService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadMoods()
    } catch (error) {
      Logger.error('[FilterBar] 初始化失败: ' + JSON.stringify(error))
    }
  }

  private onTagVersionChange() {
    Logger.info('[FilterBar] tagVersion 改变，重新加载标签与心情')
    this.loadTags()
    this.loadMoods()
  }

  private loadTags() {
    if (this.tagService) {
      const customTags = this.tagService.getCustomTags()
      this.availableTags = buildDisplayTags(customTags, this.getUIContext().getHostContext()?.resourceManager ?? null)
    }
  }

  // 加载自定义心情（更新计划二期；随 tagVersion 变化重载，确保管理页增删后同步）
  private loadMoods() {
    if (this.moodService) {
      this.moods = MoodUtils.getAllMoods(this.moodService.getCustomMoods())
    }
  }

  // 判断标签是否选中
  private isTagSelected(tagId: string): boolean {
    return this.selectedTagIds.includes(tagId)
  }

  // 切换标签选中状态（单选模式：点击新标签替换旧选择，再次点击取消选择）
  private toggleTag(tagId: string) {
    // 如果点击的是当前已选中的标签，取消选择（回到"全部"状态）
    if (this.isTagSelected(tagId)) {
      this.selectedTagIds = []
      promptAction.showToast({ message: $r('app.string.filter_cancelled'), duration: 1500 })
    } else {
      // 否则替换为新选择的标签（单选）
      this.selectedTagIds = [tagId]
      const tag = this.availableTags.find(t => t.id === tagId)
      const tagName = tag ? tag.name : tagId
      promptAction.showToast({ message: $r('app.string.tag_selected', tagName), duration: 1500 })
    }

    // 触发回调（选择标签后关闭气泡）
    this.showFilterPopup = false
    if (this.onChange) {
      this.onChange()
    }
  }

  // 切换心情（单选，再点取消；不影响标签筛选；选择后关闭气泡）
  private toggleMood(moodId: string) {
    if (this.filterMood === moodId) {
      // 取消选择
      this.filterMood = ''
      promptAction.showToast({ message: $r('app.string.filter_cancelled'), duration: 1500 })
    } else {
      // 选中
      this.filterMood = moodId
      const emoji = MoodUtils.getMoodEmoji(moodId, this.moods)
      promptAction.showToast({ message: $r('app.string.mood_selected', emoji), duration: 1500 })
    }
    // 选择即关闭气泡
    this.showFilterPopup = false
    if (this.onChange) {
      this.onChange()
    }
  }

  // 清除所有筛选（标签 + 心情；关闭气泡）
  private clearAll() {
    if (this.selectedTagIds.length > 0 || this.filterMood.length > 0) {
      this.selectedTagIds = []
      this.filterMood = ''
      this.showFilterPopup = false
      if (this.onChange) {
        this.onChange()
      }
    }
  }

  build() {
    // 筛选入口胶囊按钮（此刻右侧；点击向下弹出筛选气泡）
    Row() {
      Text('☰')
        .fontSize(15)
        .fontColor(this.themeColors.primary)

      Text(this.getFilterSummary())
        .fontSize(14)
        .fontColor(this.themeColors.primary)
        .fontWeight(FontWeight.Medium)
        .margin({ left: 6 })

      // 筛选计数徽标（有筛选时显示）
      if (this.getFilterCount() > 0) {
        Text(this.getFilterCount().toString())
          .fontSize(11)
          .fontColor('#FFFFFF')
          .textAlign(TextAlign.Center)
          .width(18)
          .height(18)
          .borderRadius(9)
          .backgroundColor(this.themeColors.primary)
          .margin({ left: 4 })
      }
    }
    .padding({ left: 14, right: 14, top: 7, bottom: 7 })
    .backgroundColor(ColorUtils.primaryExtraLight(this.themeColors.primary))
    .borderRadius(16)
    .onClick(() => {
      // 手动 toggle 开关气泡
      this.showFilterPopup = !this.showFilterPopup
    })
    .bindPopup($$this.showFilterPopup, {
      builder: () => {
        this.FilterSheetBuilder()
      },
      placement: Placement.Bottom,
      offset: { x: 0, y: 6 },
      enableArrow: true,
      arrowPointPosition: ArrowPointPosition.START,
      // 透明遮罩：点击空白处关闭气泡
      mask: { color: '#00000000' },
      backgroundBlurStyle: BlurStyle.NONE,
      onStateChange: (e) => {
        // 任何方式关闭气泡（点空白/遮罩）都复位状态，保证下次可正常弹出
        if (e.isVisible === false) {
          this.showFilterPopup = false
        }
      }
    })
  }

  // 筛选入口摘要（无筛选显示「筛选」）
  private getFilterSummary(): string {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    const title = rm ? rm.getStringByNameSync('filter_title') : ''
    if (this.filterMood.length > 0) {
      return MoodUtils.getMoodEmoji(this.filterMood, this.moods) + ' ' + title
    }
    if (this.selectedTagIds.length > 0) {
      const tag = this.availableTags.find(t => t.id === this.selectedTagIds[0])
      return (tag ? tag.name : '') + ' · ' + title
    }
    return title
  }

  // 当前筛选项数量（心情 1 项 + 标签数量）
  private getFilterCount(): number {
    let count = this.selectedTagIds.length
    if (this.filterMood.length > 0) {
      count++
    }
    return count
  }

  // 筛选弹窗（心情单选 + 标签单选 + 清除全部；内容可滚动，高度调小）
  @Builder
  FilterSheetBuilder() {
    Column() {
      // 标题行（固定）
      Row() {
        Text($r('app.string.filter_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)

        Blank()

        // 清除全部
        Text($r('app.string.filter_clear'))
          .fontSize(14)
          .fontColor(this.themeColors.primary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            this.clearAll()
          })
      }
      .width('100%')
      .margin({ top: 8, bottom: 10 })

      // 可滚动内容区（心情 + 标签分组）
      Scroll() {
        Column() {
          // 心情分组
          Text($r('app.string.mood_tab'))
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
            .width('100%')
            .margin({ top: 2, bottom: 10 })

          Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
            ForEach(this.moods, (mood: Mood) => {
              FilterChip({
                label: mood.emoji,
                color: this.themeColors.primary,
                isSelected: this.filterMood === mood.id,
                onChipClick: () => {
                  this.toggleMood(mood.id)
                }
              })
            }, (mood: Mood) => `mood-${mood.id}`)
          }
          .width('100%')
          .margin({ bottom: 16 })

          // 标签分组
          Text($r('app.string.tag_tab'))
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
            .width('100%')
            .margin({ bottom: 10 })

          Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
            ForEach(this.availableTags, (tag: Tag) => {
              FilterChip({
                label: (tag.icon ? tag.icon + ' ' : '') + tag.name,
                color: tag.color,
                isSelected: this.isTagSelected(tag.id),
                onChipClick: () => {
                  this.toggleTag(tag.id)
                }
              })
            }, (tag: Tag) => `filter-${tag.id}`)
          }
          .width('100%')
          .padding({ bottom: 4 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .height(150)
    }
    .width(px2vp(display.getDefaultDisplaySync().width) - 8)  // 与搜索栏同宽（屏宽 - 左右 4vp×2）
    .constraintSize({ maxHeight: '35%' })
    .padding({ left: 14, right: 14, top: 6, bottom: 8 })
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(14)
  }
}
