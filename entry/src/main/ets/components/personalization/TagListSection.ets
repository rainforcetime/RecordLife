// 个性化管理 - 标签管理组件（页面化拆分，个性化管理 UI 优化）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag } from '../../common/types'
import { TagService } from '../../service/TagService'
import { common } from '@kit.AbilityKit'
import { RefreshManager } from '../../common/managers/RefreshManager'
import { Logger } from '../../common/utils/Logger'

// 预设可选颜色
const PRESET_COLORS: string[] = [
  '#4A90D9', '#67C23A', '#E6A23C', '#F56C6C', '#909399',
  '#9B59B6', '#FF69B4', '#00BCD4', '#FF9800', '#607D8B',
  '#E91E63', '#3F51B5', '#009688', '#795548', '#CDDC39',
  '#FF5722', '#8BC34A', '#673AB7', '#03A9F4', '#FFEB3B'
]

// 预设可选图标（emoji）
const PRESET_ICONS: string[] = [
  '💼', '🏠', '✈️', '🍜', '💪', '📚', '🎮', '👨‍👩‍👧‍👦',
  '🎵', '🎨', '🏃', '💡', '🌟', '❤️', '🔥', '🎯',
  '📷', '🐱', '🌸', '☕', '🎂', '🚗', '💻', '📱'
]

@Component
export struct TagListSection {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 自定义标签列表
  @State private customTags: Tag[] = []

  // 编辑/新增状态
  @State private isEditing: boolean = false
  @State private editingTag: Tag = { id: '', name: '', color: '#4A90D9', icon: '' }
  @State private editTagName: string = ''
  @State private isNewTag: boolean = true

  // 颜色/图标选择器展开
  @State private showColorPicker: boolean = false
  @State private showIconPicker: boolean = false

  private tagService: TagService | null = null

  aboutToAppear() {
    this.initService()
  }

  private async initService() {
    try {
      this.tagService = await TagService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadTags()
    } catch (error) {
      Logger.error('[TagListSection] 初始化标签服务失败: ' + JSON.stringify(error))
    }
  }

  private loadTags() {
    if (this.tagService) {
      this.customTags = [...this.tagService.getCustomTags()]
    }
  }

  // 将十六进制颜色转换为 rgba 格式
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  // 生成唯一ID
  private generateId(): string {
    return 'custom_' + Date.now().toString(36) + Math.random().toString(36).substring(2)
  }

  // 开始添加新标签
  private startAddTag() {
    this.editingTag = { id: '', name: '', color: '#4A90D9', icon: '' }
    this.editTagName = ''
    this.isNewTag = true
    this.isEditing = true
    this.showColorPicker = false
    this.showIconPicker = false
  }

  // 开始编辑标签
  private startEditTag(tag: Tag) {
    this.editingTag = {
      id: tag.id,
      name: tag.name,
      color: tag.color,
      icon: tag.icon
    }
    this.editTagName = tag.name
    this.isNewTag = false
    this.isEditing = true
    this.showColorPicker = false
    this.showIconPicker = false
  }

  // 取消编辑
  private cancelEdit() {
    this.isEditing = false
    this.editingTag = { id: '', name: '', color: '#4A90D9', icon: '' }
    this.editTagName = ''
  }

  // 保存标签
  private async saveTag() {
    if (!this.tagService) {
      return
    }
    const name = this.editTagName.trim()
    if (name.length === 0) {
      return
    }
    if (this.isNewTag) {
      const newTag: Tag = {
        id: this.generateId(),
        name: name,
        color: this.editingTag.color,
        icon: this.editingTag.icon || undefined
      }
      await this.tagService.addCustomTag(newTag)
    } else {
      await this.tagService.updateCustomTag({
        id: this.editingTag.id,
        name: name,
        color: this.editingTag.color,
        icon: this.editingTag.icon
      })
    }
    this.isEditing = false
    this.loadTags()
    RefreshManager.getInstance().refresh()
  }

  // 删除标签（二次确认）
  private confirmDeleteTag(tag: Tag) {
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
          this.deleteTag(tag)
        }
      }
    })
  }

  // 删除标签
  private async deleteTag(tag: Tag) {
    if (!this.tagService) {
      return
    }
    await this.tagService.deleteCustomTag(tag.id)
    this.loadTags()
    RefreshManager.getInstance().refresh()
  }

  build() {
    Column() {
      if (this.isEditing) {
        // 标签编辑视图
        this.TagEditView()
      } else {
        // 标签列表视图
        this.TagListView()
      }
    }
    .width('100%')
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.97, y: 0.97 }))
        .animation({ duration: 200, curve: Curve.EaseOut })
    )
  }

  // 标签列表视图
  @Builder
  TagListView() {
    Column() {
      // 标题行：页签名 + 右侧添加按钮（与心情/模板页签统一）
      Row() {
        Text($r('app.string.tag_tab'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .layoutWeight(1)

        // 添加标签按钮（44×44 点击区）
        Column() {
          SymbolGlyph($r('sys.symbol.plus'))
            .fontSize(20)
            .fontColor([this.themeColors.primary])
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .onClick(() => {
          this.startAddTag()
        })
      }
      .width('100%')

      // 说明文字
      Text($r('app.string.preset_tags_hint'))
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ top: 4, bottom: 12 })

      // 自定义标签列表
      if (this.customTags.length > 0) {
        List() {
          ForEach(this.customTags, (tag: Tag) => {
            ListItem() {
              Row() {
                // 颜色圆点
                Circle({ width: 12, height: 12 })
                  .fill(tag.color)
                  .margin({ right: 10 })

                // 图标
                if (tag.icon) {
                  Text(tag.icon)
                    .fontSize(18)
                    .margin({ right: 8 })
                }

                // 名称
                Text(tag.name)
                  .fontSize(15)
                  .fontColor(this.themeColors.textPrimary)
                  .layoutWeight(1)

                // 编辑按钮
                SymbolGlyph($r('sys.symbol.square_and_pencil'))
                  .fontSize(18)
                  .fontColor([this.themeColors.iconColor])
                  .margin({ right: 12 })
                  .onClick(() => {
                    this.startEditTag(tag)
                  })

                // 删除按钮（二次确认）
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(18)
                  .fontColor([this.themeColors.error])
                  .onClick(() => {
                    this.confirmDeleteTag(tag)
                  })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)
            }
          }, (tag: Tag) => tag.id)
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 300 })
        .divider({ strokeWidth: 0.5, color: this.themeColors.border, startMargin: 12, endMargin: 12 })
        .edgeEffect(EdgeEffect.None)
      } else {
        // 空状态
        Column({ space: 16 }) {
          Text('🏷️')
            .fontSize(40)

          Text($r('app.string.no_custom_tags'))
            .fontSize(15)
            .fontColor(this.themeColors.textSecondary)

          Button($r('app.string.add_first_tag'))
            .fontSize(14)
            .fontColor(this.themeColors.primary)
            .backgroundColor(this.hexToRgba(this.themeColors.primary, 0.1))
            .borderRadius(8)
            .onClick(() => {
              this.startAddTag()
            })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      }
    }
    .width('100%')
  }

  // 标签编辑视图
  @Builder
  TagEditView() {
    Column() {
      // 标题
      Row() {
        SymbolGlyph($r('sys.symbol.chevron_left'))
          .fontSize(20)
          .fontColor([this.themeColors.iconColor])
          .onClick(() => {
            this.cancelEdit()
          })

        Text(this.isNewTag ? $r('app.string.new_tag') : $r('app.string.edit_tag'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 8 })
          .layoutWeight(1)

        // 保存按钮
        Text($r('app.string.save'))
          .fontSize(16)
          .fontColor(this.editTagName.trim().length > 0 ? this.themeColors.primary : this.themeColors.textTertiary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            if (this.editTagName.trim().length > 0) {
              this.saveTag()
            }
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 名称输入
      Text($r('app.string.tag_name'))
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      TextInput({ text: $$this.editTagName, placeholder: $r('app.string.input_tag_name') })
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.background)
        .borderRadius(8)
        .border({ width: 1, color: this.themeColors.border })
        .fontColor(this.themeColors.textPrimary)
        .placeholderColor(this.themeColors.textTertiary)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 16 })

      // 颜色选择
      Text($r('app.string.tag_color'))
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      // 当前颜色预览
      Row() {
        Circle({ width: 24, height: 24 })
          .fill(this.editingTag.color)

        Text(this.editingTag.color)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
          .margin({ left: 10 })
          .layoutWeight(1)

        SymbolGlyph(this.showColorPicker ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(16)
          .fontColor([this.themeColors.iconColor])
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.themeColors.background)
      .borderRadius(8)
      .border({ width: 1, color: this.themeColors.border })
      .padding({ left: 12, right: 12 })
      .onClick(() => {
        this.showColorPicker = !this.showColorPicker
      })
      .margin({ bottom: this.showColorPicker ? 8 : 16 })

      // 颜色选择面板
      if (this.showColorPicker) {
        Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
          ForEach(PRESET_COLORS, (color: string) => {
            Column() {
              Circle({ width: 28, height: 28 })
                .fill(color)
                .stroke(this.editingTag.color === color ? '#FFFFFF' : 'transparent')
                .strokeWidth(2)
            }
            .width(36)
            .height(36)
            .borderRadius(18)
            .backgroundColor(this.editingTag.color === color ? color : this.hexToRgba(color, 0.15))
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.editingTag.color = color
            })
          }, (color: string) => color)
        }
        .width('100%')
        .margin({ bottom: 16 })
      }

      // 图标选择
      Text($r('app.string.tag_icon_optional'))
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        if (this.editingTag.icon) {
          Text(this.editingTag.icon)
            .fontSize(20)
        }

        Text(this.editingTag.icon ? this.editingTag.icon : $r('app.string.no_icon'))
          .fontSize(14)
          .fontColor(this.editingTag.icon ? this.themeColors.textPrimary : this.themeColors.textTertiary)
          .margin({ left: 8 })
          .layoutWeight(1)

        SymbolGlyph(this.showIconPicker ? $r('sys.symbol.chevron_up') : $r('sys.symbol.chevron_down'))
          .fontSize(16)
          .fontColor([this.themeColors.iconColor])
      }
      .width('100%')
      .height(44)
      .backgroundColor(this.themeColors.background)
      .borderRadius(8)
      .border({ width: 1, color: this.themeColors.border })
      .padding({ left: 12, right: 12 })
      .onClick(() => {
        this.showIconPicker = !this.showIconPicker
      })
      .margin({ bottom: this.showIconPicker ? 8 : 16 })

      // 图标选择面板
      if (this.showIconPicker) {
        Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
          // 无图标选项
          Column() {
            Text('✕')
              .fontSize(14)
          }
          .width(36)
          .height(36)
          .borderRadius(8)
          .backgroundColor(this.editingTag.icon === '' ? this.hexToRgba(this.themeColors.primary, 0.15) : this.themeColors.background)
          .border({ width: 1, color: this.editingTag.icon === '' ? this.themeColors.primary : this.themeColors.border })
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ right: 8, bottom: 8 })
          .onClick(() => {
            this.editingTag.icon = ''
          })

          ForEach(PRESET_ICONS, (icon: string) => {
            Column() {
              Text(icon)
                .fontSize(18)
            }
            .width(36)
            .height(36)
            .borderRadius(8)
            .backgroundColor(this.editingTag.icon === icon ? this.hexToRgba(this.themeColors.primary, 0.15) : this.themeColors.background)
            .border({ width: 1, color: this.editingTag.icon === icon ? this.themeColors.primary : this.themeColors.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.editingTag.icon = icon
            })
          }, (icon: string) => icon)
        }
        .width('100%')
        .margin({ bottom: 16 })
      }

      // 预览
      Text($r('app.string.preview'))
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        if (this.editingTag.icon) {
          Text(this.editingTag.icon)
            .fontSize(14)
        }

        Text(this.editTagName ? this.editTagName : $r('app.string.tag_preview'))
          .fontSize(14)
          .fontColor(this.editTagName ? '#FFFFFF' : this.themeColors.textTertiary)
          .margin({ left: this.editingTag.icon ? 4 : 0 })
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.editingTag.color)
      .borderRadius(16)
    }
    .width('100%')
  }
}
