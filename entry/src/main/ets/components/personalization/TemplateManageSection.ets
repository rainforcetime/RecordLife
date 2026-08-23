// 个性化管理 - 记录模板组件（页面化拆分，个性化管理 UI 优化）
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { TemplateService } from '../../service/TemplateService'
import { RecordTemplate } from '../../model/UserConfigModel'
import { common } from '@kit.AbilityKit'
import { RefreshManager } from '../../common/managers/RefreshManager'
import { Logger } from '../../common/utils/Logger'

@Component
export struct TemplateManageSection {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 记录模板
  @State private templates: RecordTemplate[] = []
  @State private showTemplateForm: boolean = false
  @State private isNewTemplate: boolean = true
  @State private editingTemplate: RecordTemplate = { id: '', name: '', content: '' }
  @State private editTemplateName: string = ''
  @State private editTemplateContent: string = ''
  private templateService: TemplateService | null = null

  aboutToAppear() {
    this.initService()
  }

  // 将十六进制颜色转换为 rgba 格式
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  private async initService() {
    try {
      this.templateService = await TemplateService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext)
      this.loadTemplates()
    } catch (error) {
      Logger.error('[TemplateManageSection] 初始化模板服务失败: ' + JSON.stringify(error))
    }
  }

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

  // 删除模板（二次确认）
  private confirmDeleteTemplate(template: RecordTemplate) {
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
          this.deleteTemplate(template)
        }
      }
    })
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
    Column() {
      // 标题行：记录模板 + 添加按钮（拆分时丢失，已补回）
      Row() {
        Text($r('app.string.template_tab'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .layoutWeight(1)

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
                    this.confirmDeleteTemplate(template)
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

          Button($r('app.string.add_first_tag'))
            .fontSize(14)
            .fontColor(this.themeColors.primary)
            .backgroundColor(this.hexToRgba(this.themeColors.primary, 0.1))
            .borderRadius(8)
            .margin({ top: 12 })
            .onClick(() => {
              this.startAddTemplate()
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })
      }
    }
    .width('100%')
    .transition(
      TransitionEffect.OPACITY
        .combine(TransitionEffect.scale({ x: 0.97, y: 0.97 }))
        .animation({ duration: 200, curve: Curve.EaseOut })
    )
  }
}
