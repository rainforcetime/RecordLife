// 统一筛选栏组件：components/record/FilterBar.ets
// 合并标签筛选 + 心情筛选（更新计划二期）：单行横向滚动，视觉统一
// 交互：心情单选（再点取消）、标签单选（再点取消）、"全部"清除所有筛选；心情与标签可叠加过滤
// 说明：chip 为独立组件 FilterChip（@Prop isSelected 响应式）——@Builder 按值传参不随状态刷新，故不用 @Builder
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag, DEFAULT_TAGS } from '../../common/types'
import { buildDisplayTags } from '../../common/utils/TagDisplayUtils'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { TagService } from '../../service/TagService'
import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { Logger } from '../../common/utils/Logger'

// 筛选 chip（独立组件：@Prop isSelected 随父状态响应式更新）
@Component
export struct FilterChip {
  label: ResourceStr = ''
  color: string = '#909399'
  @Prop isSelected: boolean = false
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  onClick?: () => void

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
        if (this.onClick) {
          this.onClick()
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

  // 可用标签（内部动态加载）
  @State availableTags: Tag[] = DEFAULT_TAGS

  // 标签版本号（由父组件传入，变化时重新加载）
  @Watch('onTagVersionChange')
  @Prop tagVersion: number = 0

  // TagService
  private tagService: TagService | null = null

  // 是否无任何筛选（"全部"选中态）
  private isNoFilter(): boolean {
    return this.selectedTagIds.length === 0 && this.filterMood.length === 0
  }

  async aboutToAppear() {
    try {
      this.tagService = await TagService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadTags()
    } catch (error) {
      Logger.error('[FilterBar] 初始化失败: ' + JSON.stringify(error))
    }
  }

  private onTagVersionChange() {
    Logger.info('[FilterBar] tagVersion 改变，重新加载标签')
    this.loadTags()
  }

  private loadTags() {
    if (this.tagService) {
      const customTags = this.tagService.getCustomTags()
      this.availableTags = buildDisplayTags(customTags, this.getUIContext().getHostContext()?.resourceManager ?? null)
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

    // 触发回调
    if (this.onChange) {
      this.onChange()
    }
  }

  // 切换心情（单选，再点取消；不影响标签筛选）
  private toggleMood(mood: string) {
    this.filterMood = this.filterMood === mood ? '' : mood
    if (this.onChange) {
      this.onChange()
    }
  }

  // 清除所有筛选（标签 + 心情）
  private clearAll() {
    if (this.selectedTagIds.length > 0 || this.filterMood.length > 0) {
      this.selectedTagIds = []
      this.filterMood = ''
      if (this.onChange) {
        this.onChange()
      }
    }
  }

  build() {
    Scroll() {
      Row({ space: 0 }) {
        // "全部" 按钮（清除标签 + 心情筛选）
        FilterChip({
          label: $r('app.string.all'),
          color: '#909399',
          isSelected: this.isNoFilter(),
          onClick: () => {
            this.clearAll()
          }
        })

        // 心情筛选（更新计划二期）
        ForEach(MoodUtils.MOODS, (mood: string) => {
          FilterChip({
            label: MoodUtils.getMoodEmoji(mood),
            color: this.themeColors.primary,
            isSelected: this.filterMood === mood,
            onClick: () => {
              this.toggleMood(mood)
            }
          })
        }, (mood: string) => `mood-${mood}`)

        // 心情与标签分隔线
        if (this.availableTags.length > 0) {
          Column()
            .width(1)
            .height(18)
            .backgroundColor(this.themeColors.divider)
            .margin({ right: 8 })
        }

        // 标签列表
        ForEach(this.availableTags, (tag: Tag) => {
          FilterChip({
            label: (tag.icon ? tag.icon + ' ' : '') + tag.name,
            color: tag.color,
            isSelected: this.isTagSelected(tag.id),
            onClick: () => {
              this.toggleTag(tag.id)
            }
          })
        }, (tag: Tag) => `filter-${tag.id}`)
      }
      .padding({ left: 4, right: 4 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }
}
