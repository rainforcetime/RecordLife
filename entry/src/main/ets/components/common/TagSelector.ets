// 标签选择组件：components/TagSelector.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag, DEFAULT_TAGS, getAllTags } from '../../common/types'
import { ConfigManager } from '../../config/ConfigManager'

@Component
export struct TagSelector {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 已选中的标签ID列表（双向绑定）
  @Link selectedTagIds: string[]
  
  // 可用的标签列表（内部动态加载）
  @State availableTags: Tag[] = DEFAULT_TAGS
  
  // 是否为编辑模式（紧凑显示）
  @Prop isCompact: boolean = false

  // ConfigManager
  private configManager: ConfigManager | null = null

  async aboutToAppear() {
    try {
      this.configManager = await ConfigManager.getInstance()
      this.loadTags()
    } catch (error) {
      console.error('[TagSelector] 初始化失败: ' + JSON.stringify(error))
    }
  }

  private loadTags() {
    if (this.configManager) {
      const customTags = this.configManager.getCustomTags()
      this.availableTags = getAllTags(customTags)
    }
  }
  
  // 判断是否深色模式
  private isDarkMode(): boolean {
    return this.themeColors.textPrimary === '#FFFFFF'
  }
  
  build() {
    Column() {
      // 标题
      if (!this.isCompact) {
        Row() {
          Text('标签')
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
          
          Blank()
          
          if (this.selectedTagIds.length > 0) {
            Text(`已选 ${this.selectedTagIds.length} 个`)
              .fontSize(12)
              .fontColor(this.themeColors.textSecondary)
          }
        }
        .width('100%')
        .margin({ bottom: 10 })
      }
      
      // 标签列表
      Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
        ForEach(this.availableTags, (tag: Tag) => {
          this.TagItem(tag)
        }, (tag: Tag) => tag.id)
      }
      .width('100%')
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }
  
  // 将十六进制颜色转换为 rgba 格式
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }
  
  // 获取标签背景色（深色模式适配）
  private getTagBackground(tagColor: string, isSelected: boolean): string {
    if (isSelected) {
      return tagColor
    }
    if (this.isDarkMode()) {
      // 深色模式：使用更低的透明度，避免过于鲜艳
      return this.hexToRgba(tagColor, 0.25)
    } else {
      // 浅色模式：使用正常透明度
      return this.hexToRgba(tagColor, 0.15)
    }
  }
  
  // 单个标签项
  @Builder
  TagItem(tag: Tag) {
    Row() {
      // 图标
      if (tag.icon) {
        Text(tag.icon)
          .fontSize(this.isCompact ? 12 : 14)
      }
      
      // 名称
      Text(tag.name)
        .fontSize(this.isCompact ? 12 : 14)
        .fontColor(this.isTagSelected(tag.id) ? '#FFFFFF' : tag.color)
        .fontWeight(this.isTagSelected(tag.id) ? FontWeight.Medium : FontWeight.Normal)
        .margin({ left: tag.icon ? 4 : 0 })
    }
    .padding({ 
      left: this.isCompact ? 8 : 10, 
      right: this.isCompact ? 8 : 10, 
      top: this.isCompact ? 4 : 6, 
      bottom: this.isCompact ? 4 : 6 
    })
    .backgroundColor(this.getTagBackground(tag.color, this.isTagSelected(tag.id)))
    .borderRadius(this.isCompact ? 12 : 16)
    .margin({ right: 8, bottom: 8 })
    .onClick(() => {
      this.toggleTag(tag.id)
    })
  }
  
  // 判断标签是否选中
  private isTagSelected(tagId: string): boolean {
    return this.selectedTagIds.includes(tagId)
  }
  
  // 切换标签选中状态
  private toggleTag(tagId: string) {
    const index = this.selectedTagIds.indexOf(tagId)
    if (index === -1) {
      // 选中标签
      this.selectedTagIds = [...this.selectedTagIds, tagId]
    } else {
      // 取消选中
      const newTags = [...this.selectedTagIds]
      newTags.splice(index, 1)
      this.selectedTagIds = newTags
    }
  }
}

// 标签显示组件（只读，用于 RecordCard）
@Component
export struct TagDisplay {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 标签ID列表
  @Prop tagIds: string[] = []
  
  // 可用的标签列表（内部动态加载）
  @State availableTags: Tag[] = DEFAULT_TAGS

  // ConfigManager
  private configManager: ConfigManager | null = null

  async aboutToAppear() {
    try {
      this.configManager = await ConfigManager.getInstance()
      this.loadTags()
    } catch (error) {
      console.error('[TagDisplay] 初始化失败: ' + JSON.stringify(error))
    }
  }

  private loadTags() {
    if (this.configManager) {
      const customTags = this.configManager.getCustomTags()
      this.availableTags = getAllTags(customTags)
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
  
  // 获取标签背景色（深色模式适配）
  private getTagBackground(tagColor: string): string {
    if (this.isDarkMode()) {
      // 深色模式：使用更低的透明度，避免过于鲜艳
      return this.hexToRgba(tagColor, 0.25)
    } else {
      // 浅色模式：使用正常透明度
      return this.hexToRgba(tagColor, 0.15)
    }
  }
  
  build() {
    if (this.tagIds.length > 0) {
      Row() {
        ForEach(this.getTagsByIds(), (tag: Tag, index: number) => {
          Row() {
            if (tag.icon) {
              Text(tag.icon)
                .fontSize(11)
            }
            Text(tag.name)
              .fontSize(11)
              .fontColor(tag.color)
              .margin({ left: tag.icon ? 2 : 0 })
          }
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .backgroundColor(this.getTagBackground(tag.color))
          .borderRadius(10)
          .margin({ right: index < this.tagIds.length - 1 ? 6 : 0 })
        }, (tag: Tag) => tag.id)
      }
      .width('100%')
    }
  }
  
  // 根据ID获取标签对象
  private getTagsByIds(): Tag[] {
    const result: Tag[] = []
    for (const id of this.tagIds) {
      const tag = this.availableTags.find(t => t.id === id)
      if (tag !== undefined) {
        result.push(tag)
      }
    }
    return result
  }
}
