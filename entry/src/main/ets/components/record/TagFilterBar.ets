// 标签筛选栏组件：components/record/TagFilterBar.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag, DEFAULT_TAGS } from '../../common/types'

@Component
export struct TagFilterBar {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 已选中的标签ID列表（双向绑定）
  @Link selectedTagIds: string[]

  // 筛选变化回调
  onChange?: () => void

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
    } else {
      // 否则替换为新选择的标签（单选）
      this.selectedTagIds = [tagId]
    }

    // 触发回调
    if (this.onChange) {
      this.onChange()
    }
  }

  // 清除所有筛选
  private clearAll() {
    if (this.selectedTagIds.length > 0) {
      this.selectedTagIds = []
      if (this.onChange) {
        this.onChange()
      }
    }
  }

  build() {
    Scroll() {
      Row({ space: 0 }) {
        // "全部" 按钮
        this.ChipItem(
          '全部',
          '#909399',
          this.selectedTagIds.length === 0,
          () => {
            this.clearAll()
          }
        )

        // 标签列表
        ForEach(DEFAULT_TAGS, (tag: Tag) => {
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
  ChipItem(label: string, color: string, isSelected: boolean, onClick: () => void) {
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
