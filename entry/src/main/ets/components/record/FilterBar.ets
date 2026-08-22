// 统一筛选栏组件：components/record/FilterBar.ets
// 合并标签筛选 + 心情筛选（更新计划二期）：单行横向滚动，视觉统一
// 交互：心情单选（再点取消）、标签单选（再点取消）、"全部"清除所有筛选；心情与标签可叠加过滤
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag, DEFAULT_TAGS } from '../../common/types'
import { buildDisplayTags } from '../../common/utils/TagDisplayUtils'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { TagService } from '../../service/TagService'
import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { Logger } from '../../common/utils/Logger'

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

  // 获取标签背景色
  private getTagBackground(tagColor: string, isSelected: boolean): string {
    if (isSelected) {
      return tagColor
    }
    if (this.isDarkMode()) {
      return this.hexToRgba(tagColor, 0.2)
    }
    return this.hexToRgba(tagColor, 0.12)
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
        this.ChipItem(
          $r('app.string.all'),
          '#909399',
          this.isNoFilter(),
          () => {
            this.clearAll()
          }
        )

        // 心情筛选（更新计划二期）
        ForEach(MoodUtils.MOODS, (mood: string) => {
          this.ChipItem(
            MoodUtils.getMoodEmoji(mood),
            this.themeColors.primary,
            this.filterMood === mood,
            () => {
              this.toggleMood(mood)
            }
          )
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
          this.ChipItem(
            (tag.icon ? tag.icon + ' ' : '') + tag.name,
            tag.color,
            this.isTagSelected(tag.id),
            () => {
              this.toggleTag(tag.id)
            }
          )
        }, (tag: Tag) => `filter-${tag.id}`)
      }
      .padding({ left: 4, right: 4 })
    }
    .scrollable(ScrollDirection.Horizontal)
    .scrollBar(BarState.Off)
    .width('100%')
  }

  @Builder
  ChipItem(label: ResourceStr, color: string, isSelected: boolean, onClick: () => void) {
    Text(label)
      .fontSize(12)
      .fontColor(isSelected ? '#FFFFFF' : color)
      .fontWeight(isSelected ? FontWeight.Medium : FontWeight.Normal)
      .maxLines(1)
      .textOverflow({ overflow: TextOverflow.Ellipsis })
      .padding({ left: 10, right: 10, top: 5, bottom: 5 })
      .backgroundColor(isSelected ? color : this.getTagBackground(color, isSelected))
      .borderRadius(14)
      .margin({ right: 8 })
      .onClick(onClick)
  }
}
