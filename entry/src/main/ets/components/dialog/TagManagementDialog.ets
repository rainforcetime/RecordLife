// 标签管理对话框：components/dialog/TagManagementDialog.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag } from '../../common/types'
import { ConfigManager } from '../../config/ConfigManager'
import { RefreshManager } from '../../common/managers/RefreshManager'

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

@CustomDialog
export struct TagManagementDialog {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  controller: CustomDialogController

  // 自定义标签列表
  @State private customTags: Tag[] = []

  // 编辑/新增状态
  @State private isEditing: boolean = false
  @State private editingTag: Tag = { id: '', name: '', color: '#4A90D9', icon: '' }
  @State private editTagName: string = ''
  @State private isNewTag: boolean = true

  // 颜色选择器展开
  @State private showColorPicker: boolean = false

  // 图标选择器展开
  @State private showIconPicker: boolean = false

  // ConfigManager
  private configManager: ConfigManager | null = null

  async aboutToAppear() {
    console.info('[TagMgmtDialog] aboutToAppear 开始')
    this.configManager = await ConfigManager.getInstance()
    console.info('[TagMgmtDialog] configManager 初始化完成: ' + (this.configManager !== null))
    this.loadTags()
    console.info('[TagMgmtDialog] aboutToAppear 完成, customTags count: ' + this.customTags.length)
  }

  private loadTags() {
    if (this.configManager) {
      this.customTags = [...this.configManager.getCustomTags()]
      console.info('[TagMgmtDialog] loadTags 完成, count: ' + this.customTags.length)
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
    console.info('[TagMgmtDialog] >>> startAddTag 被调用 <<<')
    this.editingTag = { id: '', name: '', color: '#4A90D9', icon: '' }
    this.editTagName = ''
    this.isNewTag = true
    this.isEditing = true
    this.showColorPicker = false
    this.showIconPicker = false
    console.info('[TagMgmtDialog] startAddTag 完成, isEditing: ' + this.isEditing + ', editTagName: "' + this.editTagName + '"')
  }

  // 开始编辑标签
  private startEditTag(tag: Tag) {
    console.info('[TagMgmtDialog] >>> startEditTag 被调用, tagName: ' + tag.name + ' <<<')
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
    console.info('[TagMgmtDialog] cancelEdit 被调用')
    this.isEditing = false
    this.editingTag = { id: '', name: '', color: '#4A90D9', icon: '' }
    this.editTagName = ''
  }

  // 保存标签
  private async saveTag() {
    console.info('[TagMgmtDialog] >>> saveTag 被调用 <<<')
    if (!this.configManager) {
      console.warn('[TagMgmtDialog] saveTag 失败: configManager 为 null')
      return
    }

    const name = this.editTagName.trim()
    console.info('[TagMgmtDialog] saveTag editTagName: "' + this.editTagName + '", trim后: "' + name + '", length: ' + name.length)
    if (name.length === 0) {
      console.warn('[TagMgmtDialog] saveTag 失败: name 为空')
      return
    }

    if (this.isNewTag) {
      console.info('[TagMgmtDialog] saveTag 新建标签, name: ' + name + ', color: ' + this.editingTag.color)
      const newTag: Tag = {
        id: this.generateId(),
        name: name,
        color: this.editingTag.color,
        icon: this.editingTag.icon || undefined
      }
      console.info('[TagMgmtDialog] 准备调用 configManager.addCustomTag, configManager 类型: ' + typeof this.configManager + ', 是否为null: ' + (this.configManager === null))
      try {
        const result = await this.configManager.addCustomTag(newTag)
        console.info('[TagMgmtDialog] addCustomTag 返回: ' + result)
      } catch (e) {
        console.error('[TagMgmtDialog] addCustomTag 异常: ' + String(e) + ', message: ' + (e as Error).message + ', stack: ' + (e as Error).stack)
      }
    } else {
      console.info('[TagMgmtDialog] saveTag 更新标签, name: ' + name)
      const updatedTag: Tag = {
        id: this.editingTag.id,
        name: name,
        color: this.editingTag.color,
        icon: this.editingTag.icon
      }
      try {
        const result = await this.configManager.updateCustomTag(updatedTag)
        console.info('[TagMgmtDialog] updateCustomTag 返回: ' + result)
      } catch (e) {
        console.error('[TagMgmtDialog] updateCustomTag 异常: ' + JSON.stringify(e))
      }
    }

    this.isEditing = false
    this.loadTags()
    RefreshManager.getInstance().refresh()
    console.info('[TagMgmtDialog] saveTag 完成, 返回列表')
  }

  // 删除标签
  private async deleteTag(tag: Tag) {
    console.info('[TagMgmtDialog] deleteTag 被调用, id: ' + tag.id)
    if (!this.configManager) {
      console.warn('[TagMgmtDialog] deleteTag 失败: configManager 为 null')
      return
    }
    await this.configManager.deleteCustomTag(tag.id)
    this.loadTags()
    RefreshManager.getInstance().refresh()
    console.info('[TagMgmtDialog] deleteTag 完成')
  }

  build() {
    if (this.isEditing) {
      this.TagEditView()
    } else {
      this.TagListView()
    }
  }

  // 标签列表视图
  @Builder
  TagListView() {
    Column() {
      // 标题
      Row() {
        Text('标签管理')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)

        Blank()

        // 关闭按钮
        SymbolGlyph($r('sys.symbol.xmark'))
          .fontSize(20)
          .fontColor([this.themeColors.iconColor])
          .onClick(() => {
            this.controller.close()
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 说明文字
      Text('预设标签不可修改，以下为您自定义的标签')
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 16 })

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

                // 删除按钮
                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(18)
                  .fontColor([this.themeColors.error])
                  .onClick(() => {
                    this.deleteTag(tag)
                  })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)
            }
          }, (tag: Tag) => tag.id)

          ListItem() {
            // 添加按钮
            Row() {
              SymbolGlyph($r('sys.symbol.plus'))
                .fontSize(18)
                .fontColor([this.themeColors.primary])

              Text('添加自定义标签')
                .fontSize(15)
                .fontColor(this.themeColors.primary)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              console.info('[TagMgmtDialog] "添加自定义标签" 按钮 onClick')
              this.startAddTag()
            })
          }
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

          Text('暂无自定义标签')
            .fontSize(15)
            .fontColor(this.themeColors.textSecondary)

          Button('添加第一个标签')
            .fontSize(14)
            .fontColor(this.themeColors.primary)
            .backgroundColor(this.hexToRgba(this.themeColors.primary, 0.1))
            .borderRadius(8)
            .onClick(() => {
              console.info('[TagMgmtDialog] "添加第一个标签" Button onClick')
              this.startAddTag()
            })
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(15)
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
            console.info('[TagMgmtDialog] 返回按钮 onClick, 取消编辑')
            this.cancelEdit()
          })

        Text(this.isNewTag ? '新建标签' : '编辑标签')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 8 })
          .layoutWeight(1)

        // 保存按钮
        Text('保存')
          .fontSize(16)
          .fontColor(this.editTagName.trim().length > 0 ? this.themeColors.primary : this.themeColors.textTertiary)
          .fontWeight(FontWeight.Medium)
          .onClick(() => {
            console.info('[TagMgmtDialog] 保存按钮 onClick, editTagName: "' + this.editTagName + '", trim.length: ' + this.editTagName.trim().length)
            if (this.editTagName.trim().length > 0) {
              this.saveTag()
            } else {
              console.warn('[TagMgmtDialog] 保存按钮: 名称为空，不执行保存')
            }
          })
      }
      .width('100%')
      .margin({ bottom: 16 })

      // 名称输入
      Text('标签名称')
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      TextInput({ text: $$this.editTagName, placeholder: '输入标签名称' })
        .width('100%')
        .height(44)
        .backgroundColor(this.themeColors.background)
        .borderRadius(8)
        .border({ width: 1, color: this.themeColors.border })
        .fontColor(this.themeColors.textPrimary)
        .placeholderColor(this.themeColors.textTertiary)
        .padding({ left: 12, right: 12 })
        .margin({ bottom: 16 })
        .onChange((value: string) => {
          console.info('[TagMgmtDialog] TextInput onChange: "' + value + '", editTagName: "' + this.editTagName + '"')
        })

      // 颜色选择
      Text('标签颜色')
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
      Text('标签图标（可选）')
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        if (this.editingTag.icon) {
          Text(this.editingTag.icon)
            .fontSize(20)
        }

        Text(this.editingTag.icon ? this.editingTag.icon : '无图标')
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
              .fontColor(this.themeColors.textSecondary)
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
      Text('预览')
        .fontSize(13)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 8 })

      Row() {
        if (this.editingTag.icon) {
          Text(this.editingTag.icon)
            .fontSize(14)
        }

        Text(this.editTagName || '标签预览')
          .fontSize(14)
          .fontColor(this.editTagName ? '#FFFFFF' : this.themeColors.textTertiary)
          .margin({ left: this.editingTag.icon ? 4 : 0 })
      }
      .padding({ left: 12, right: 12, top: 6, bottom: 6 })
      .backgroundColor(this.editingTag.color)
      .borderRadius(16)
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(15)
  }
}
