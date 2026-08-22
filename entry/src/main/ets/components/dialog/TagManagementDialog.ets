// 标签管理对话框：components/dialog/TagManagementDialog.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { Tag } from '../../common/types'
import { TagService } from '../../service/TagService'
import { MoodService } from '../../service/MoodService'
import { MoodUtils } from '../../common/utils/MoodUtils'
import { Mood } from '../../model/RecordModel'
import { TemplateService } from '../../service/TemplateService'
import { RecordTemplate } from '../../model/UserConfigModel'
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

  // TagService
  private tagService: TagService | null = null

  // 自定义心情（更新计划二期）
  @State private customMoods: Mood[] = []
  @State private showMoodPicker: boolean = false
  private moodService: MoodService | null = null

  // 记录模板（更新计划三期）
  @State private templates: RecordTemplate[] = []
  @State private showTemplateForm: boolean = false
  @State private isNewTemplate: boolean = true
  @State private editingTemplate: RecordTemplate = { id: '', name: '', content: '' }
  @State private editTemplateName: string = ''
  @State private editTemplateContent: string = ''
  private templateService: TemplateService | null = null

  // 管理分页（0=标签 1=心情 2=模板，更新计划三期：拆分臃肿弹窗）
  @State private currentTab: number = 0

  async aboutToAppear() {
    Logger.info('[TagMgmtDialog] aboutToAppear 开始')
    this.tagService = await TagService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
    Logger.info('[TagMgmtDialog] tagService 初始化完成: ' + (this.tagService !== null))
    this.loadTags()
    Logger.info('[TagMgmtDialog] aboutToAppear 完成, customTags count: ' + this.customTags.length)
    // 加载自定义心情（更新计划二期）
    try {
      this.moodService = await MoodService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadMoods()
    } catch (error) {
      Logger.error('[TagMgmtDialog] 加载心情失败: ' + JSON.stringify(error))
    }
    // 加载记录模板（更新计划三期）
    try {
      this.templateService = await TemplateService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadTemplates()
    } catch (error) {
      Logger.error('[TagMgmtDialog] 加载模板失败: ' + JSON.stringify(error))
    }
  }

  private loadTags() {
    if (this.tagService) {
      this.customTags = [...this.tagService.getCustomTags()]
      Logger.info('[TagMgmtDialog] loadTags 完成, count: ' + this.customTags.length)
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
    Logger.info('[TagMgmtDialog] startAddTag 完成, isEditing: ' + this.isEditing + ', editTagName: "' + this.editTagName + '"')
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
    Logger.info('[TagMgmtDialog] cancelEdit 被调用')
    this.isEditing = false
    this.editingTag = { id: '', name: '', color: '#4A90D9', icon: '' }
    this.editTagName = ''
  }

  // 保存标签
  private async saveTag() {
    if (!this.tagService) {
      Logger.warn('[TagMgmtDialog] saveTag 失败: tagService 为 null')
      return
    }

    const name = this.editTagName.trim()
    Logger.info('[TagMgmtDialog] saveTag editTagName: "' + this.editTagName + '", trim后: "' + name + '", length: ' + name.length)
    if (name.length === 0) {
      Logger.warn('[TagMgmtDialog] saveTag 失败: name 为空')
      return
    }

    if (this.isNewTag) {
      Logger.info('[TagMgmtDialog] saveTag 新建标签, name: ' + name + ', color: ' + this.editingTag.color)
      const newTag: Tag = {
        id: this.generateId(),
        name: name,
        color: this.editingTag.color,
        icon: this.editingTag.icon || undefined
      }
      Logger.info('[TagMgmtDialog] 准备调用 tagService.addCustomTag, tagService 类型: ' + typeof this.tagService + ', 是否为null: ' + (this.tagService === null))
      try {
        const result = await this.tagService.addCustomTag(newTag)
        Logger.info('[TagMgmtDialog] addCustomTag 返回: ' + result)
      } catch (e) {
        Logger.error('[TagMgmtDialog] addCustomTag 异常: ' + String(e) + ', message: ' + (e as Error).message + ', stack: ' + (e as Error).stack)
      }
    } else {
      Logger.info('[TagMgmtDialog] saveTag 更新标签, name: ' + name)
      const updatedTag: Tag = {
        id: this.editingTag.id,
        name: name,
        color: this.editingTag.color,
        icon: this.editingTag.icon
      }
      try {
        const result = await this.tagService.updateCustomTag(updatedTag)
        Logger.info('[TagMgmtDialog] updateCustomTag 返回: ' + result)
      } catch (e) {
        Logger.error('[TagMgmtDialog] updateCustomTag 异常: ' + JSON.stringify(e))
      }
    }

    this.isEditing = false
    this.loadTags()
    RefreshManager.getInstance().refresh()
    Logger.info('[TagMgmtDialog] saveTag 完成, 返回列表')
  }

  // 删除标签
  private async deleteTag(tag: Tag) {
    Logger.info('[TagMgmtDialog] deleteTag 被调用, id: ' + tag.id)
    if (!this.tagService) {
      Logger.warn('[TagMgmtDialog] deleteTag 失败: tagService 为 null')
      return
    }
    await this.tagService.deleteCustomTag(tag.id)
    this.loadTags()
    RefreshManager.getInstance().refresh()
    Logger.info('[TagMgmtDialog] deleteTag 完成')
  }

  // ==================== 心情管理（更新计划二期） ====================

  private loadMoods() {
    if (this.moodService) {
      this.customMoods = [...this.moodService.getCustomMoods()]
    }
  }

  // 添加自定义心情
  private async addMood(emoji: string) {
    if (!this.moodService) {
      return
    }
    await this.moodService.addCustomMood(emoji)
    this.loadMoods()
    RefreshManager.getInstance().refresh()
  }

  // 删除自定义心情
  private async deleteMood(mood: Mood) {
    if (!this.moodService) {
      return
    }
    await this.moodService.deleteCustomMood(mood.id)
    this.loadMoods()
    RefreshManager.getInstance().refresh()
  }

  // ==================== 记录模板（更新计划三期） ====================

  private loadTemplates() {
    if (this.templateService) {
      this.templates = [...this.templateService.getTemplates()]
    }
  }

  // 开始添加新模板
  private startAddTemplate() {
    this.editingTemplate = { id: '', name: '', content: '' }
    this.editTemplateName = ''
    this.editTemplateContent = ''
    this.isNewTemplate = true
    this.showTemplateForm = true
  }

  // 开始编辑模板
  private startEditTemplate(template: RecordTemplate) {
    this.editingTemplate = {
      id: template.id,
      name: template.name,
      content: template.content
    }
    this.editTemplateName = template.name
    this.editTemplateContent = template.content
    this.isNewTemplate = false
    this.showTemplateForm = true
  }

  // 取消模板编辑
  private cancelTemplateEdit() {
    this.showTemplateForm = false
  }

  // 保存模板
  private async saveTemplate() {
    if (!this.templateService) {
      return
    }
    const name = this.editTemplateName.trim()
    const content = this.editTemplateContent.trim()
    if (name.length === 0) {
      return
    }
    if (this.isNewTemplate) {
      await this.templateService.addTemplate(name, content)
    } else {
      await this.templateService.updateTemplate({
        id: this.editingTemplate.id,
        name: name,
        content: content
      })
    }
    this.showTemplateForm = false
    this.loadTemplates()
    RefreshManager.getInstance().refresh()
  }

  // 删除模板
  private async deleteTemplate(template: RecordTemplate) {
    if (!this.templateService) {
      return
    }
    await this.templateService.deleteTemplate(template.id)
    this.loadTemplates()
    RefreshManager.getInstance().refresh()
  }

  build() {
    // CustomDialog 弹窗背景透明，需最外层容器自带背景（Tab 栏 + 内容整体不透明）
    Column() {
      // Scroll 只能有一个内容子节点，用 Column 包裹全部内容
      Scroll() {
        Column() {
          if (this.isEditing) {
            // 标签编辑视图全屏
            this.TagEditView()
          } else {
            // 管理分页 Tab（标签 / 心情 / 模板）
            this.TabBarRow()

            if (this.currentTab === 0) {
              this.TagListView()
            } else if (this.currentTab === 1) {
              this.MoodView()
            } else {
              this.TemplateView()
            }
          }
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .width('100%')
      .constraintSize({ maxHeight: '85%' })
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(15)
  }

  // 管理分页 Tab 栏
  @Builder
  TabBarRow() {
    Row() {
      this.TabItem($r('app.string.tag_tab'), 0)
      this.TabItem($r('app.string.mood_tab'), 1)
      this.TabItem($r('app.string.template_tab'), 2)
    }
    .width('100%')
    .padding({ left: 20, right: 20, top: 16, bottom: 8 })
  }

  @Builder
  TabItem(label: ResourceStr, tabIndex: number) {
    Column() {
      Text(label)
        .fontSize(15)
        .fontColor(this.currentTab === tabIndex ? this.themeColors.primary : this.themeColors.textSecondary)
        .fontWeight(this.currentTab === tabIndex ? FontWeight.Bold : FontWeight.Normal)
        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
        .backgroundColor(this.currentTab === tabIndex ? this.hexToRgba(this.themeColors.primary, 0.12) : 'transparent')
        .borderRadius(14)
        .onClick(() => {
          this.currentTab = tabIndex
        })
    }
    .layoutWeight(1)
    .alignItems(HorizontalAlign.Center)
  }

  // 标签列表视图
  @Builder
  TagListView() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.tag_tab'))
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
      Text($r('app.string.preset_tags_hint'))
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

              Text($r('app.string.add_custom_tag'))
                .fontSize(15)
                .fontColor(this.themeColors.primary)
                .margin({ left: 8 })
            }
            .width('100%')
            .height(48)
            .alignItems(VerticalAlign.Center)
            .onClick(() => {
              Logger.info('[TagMgmtDialog] "添加自定义标签" 按钮 onClick')
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

          Text($r('app.string.no_custom_tags'))
            .fontSize(15)
            .fontColor(this.themeColors.textSecondary)

          Button($r('app.string.add_first_tag'))
            .fontSize(14)
            .fontColor(this.themeColors.primary)
            .backgroundColor(this.hexToRgba(this.themeColors.primary, 0.1))
            .borderRadius(8)
            .onClick(() => {
              Logger.info('[TagMgmtDialog] "添加第一个标签" Button onClick')
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

  // 心情管理视图（更新计划二期，Tab 分页）
  @Builder
  MoodView() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.mood_tab'))
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
      .margin({ bottom: 12 })

      // 添加心情按钮
      Row() {
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(18)
          .fontColor([this.themeColors.primary])

        Text($r('app.string.mood_custom_hint'))
          .fontSize(13)
          .fontColor(this.themeColors.primary)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(44)
      .alignItems(VerticalAlign.Center)
      .margin({ bottom: 12 })
      .onClick(() => {
        this.showMoodPicker = !this.showMoodPicker
      })

      // 心情列表（预置 + 自定义）
      Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
        ForEach(MoodUtils.getAllMoods(this.customMoods), (mood: Mood) => {
          Stack({ alignContent: Alignment.TopEnd }) {
            Column() {
              Text(mood.emoji)
                .fontSize(24)
            }
            .width(44)
            .height(44)
            .borderRadius(22)
            .backgroundColor(this.themeColors.background)
            .border({ width: 1, color: this.themeColors.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)

            // 自定义心情可删除（预置不可删）
            if (mood.id.startsWith('mood_')) {
              Column() {
                Text('×')
                  .fontSize(12)
                  .fontColor('#FFFFFF')
              }
              .width(16)
              .height(16)
              .borderRadius(8)
              .backgroundColor(this.themeColors.error)
              .justifyContent(FlexAlign.Center)
              .alignItems(HorizontalAlign.Center)
              .onClick(() => {
                this.deleteMood(mood)
              })
            }
          }
          .width(48)
          .height(48)
          .margin({ right: 8, bottom: 8 })
        }, (mood: Mood) => mood.id)
      }
      .width('100%')

      // emoji 选择面板（添加自定义心情）
      if (this.showMoodPicker) {
        Text($r('app.string.mood_picker_hint'))
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
          .margin({ top: 4, bottom: 8 })

        Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
          ForEach(MoodUtils.PRESET_MOOD_EMOJIS, (emoji: string) => {
            Column() {
              Text(emoji)
                .fontSize(20)
            }
            .width(40)
            .height(40)
            .borderRadius(20)
            .backgroundColor(this.themeColors.background)
            .border({ width: 1, color: this.themeColors.border })
            .justifyContent(FlexAlign.Center)
            .alignItems(HorizontalAlign.Center)
            .margin({ right: 8, bottom: 8 })
            .onClick(() => {
              this.addMood(emoji)
            })
          }, (emoji: string) => emoji)
        }
        .width('100%')
        .margin({ bottom: 8 })
      }
    }
    .width('100%')
    .padding(20)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(15)
  }

  // 记录模板视图（更新计划三期，Tab 分页）
  @Builder
  TemplateView() {
    Column() {
      // 标题
      Row() {
        Text($r('app.string.template_tab'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)

        Blank()

        // 添加模板按钮
        SymbolGlyph($r('sys.symbol.plus'))
          .fontSize(20)
          .fontColor([this.themeColors.primary])
          .onClick(() => {
            this.startAddTemplate()
          })
      }
      .width('100%')
      .margin({ bottom: 12 })

      Text($r('app.string.template_hint'))
        .fontSize(12)
        .fontColor(this.themeColors.textSecondary)
        .width('100%')
        .margin({ bottom: 12 })

      // 模板编辑表单（添加/编辑）
      if (this.showTemplateForm) {
        Column() {
          TextInput({ text: $$this.editTemplateName, placeholder: $r('app.string.template_name_hint') })
            .width('100%')
            .height(40)
            .backgroundColor(this.themeColors.background)
            .borderRadius(8)
            .border({ width: 1, color: this.themeColors.border })
            .fontColor(this.themeColors.textPrimary)
            .placeholderColor(this.themeColors.textTertiary)
            .padding({ left: 12, right: 12 })
            .margin({ bottom: 8 })

          TextArea({ text: $$this.editTemplateContent, placeholder: $r('app.string.template_content_hint') })
            .width('100%')
            .height(70)
            .backgroundColor(this.themeColors.background)
            .borderRadius(8)
            .border({ width: 1, color: this.themeColors.border })
            .fontColor(this.themeColors.textPrimary)
            .placeholderColor(this.themeColors.textTertiary)
            .padding(10)

          Row() {
            Button($r('app.string.cancel'))
              .layoutWeight(1)
              .height(36)
              .fontSize(14)
              .fontColor(this.themeColors.textSecondary)
              .backgroundColor(this.themeColors.background)
              .borderRadius(8)
              .onClick(() => {
                this.cancelTemplateEdit()
              })

            Button($r('app.string.save'))
              .layoutWeight(1)
              .height(36)
              .fontSize(14)
              .fontColor('#FFFFFF')
              .backgroundColor(this.themeColors.primary)
              .borderRadius(8)
              .margin({ left: 10 })
              .onClick(() => {
                this.saveTemplate()
              })
          }
          .width('100%')
          .margin({ top: 10, bottom: 12 })
        }
        .width('100%')
      }

      // 模板列表
      if (this.templates.length > 0) {
        List() {
          ForEach(this.templates, (template: RecordTemplate) => {
            ListItem() {
              Row() {
                Column() {
                  Text(template.name)
                    .fontSize(15)
                    .fontColor(this.themeColors.textPrimary)
                    .fontWeight(FontWeight.Medium)
                    .width('100%')

                  if (template.content.length > 0) {
                    Text(template.content)
                      .fontSize(12)
                      .fontColor(this.themeColors.textSecondary)
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                      .width('100%')
                      .margin({ top: 2 })
                  }
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Start)

                SymbolGlyph($r('sys.symbol.square_and_pencil'))
                  .fontSize(18)
                  .fontColor([this.themeColors.iconColor])
                  .margin({ right: 12 })
                  .onClick(() => {
                    this.startEditTemplate(template)
                  })

                SymbolGlyph($r('sys.symbol.trash'))
                  .fontSize(18)
                  .fontColor([this.themeColors.error])
                  .onClick(() => {
                    this.deleteTemplate(template)
                  })
              }
              .width('100%')
              .height(48)
              .alignItems(VerticalAlign.Center)
            }
          }, (template: RecordTemplate) => template.id)
        }
        .width('100%')
        .scrollBar(BarState.Off)
        .constraintSize({ maxHeight: 180 })
        .divider({ strokeWidth: 0.5, color: this.themeColors.border, startMargin: 12, endMargin: 12 })
        .edgeEffect(EdgeEffect.None)
      } else if (!this.showTemplateForm) {
        // 空状态
        Column() {
          Text($r('app.string.template_empty'))
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
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
            Logger.info('[TagMgmtDialog] 返回按钮 onClick, 取消编辑')
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
            Logger.info('[TagMgmtDialog] 保存按钮 onClick, editTagName: "' + this.editTagName + '", trim.length: ' + this.editTagName.trim().length)
            if (this.editTagName.trim().length > 0) {
              this.saveTag()
            } else {
              Logger.warn('[TagMgmtDialog] 保存按钮: 名称为空，不执行保存')
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
        .onChange((value: string) => {
          Logger.info('[TagMgmtDialog] TextInput onChange: "' + value + '", editTagName: "' + this.editTagName + '"')
        })

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
    .padding(20)
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(15)
  }
}
