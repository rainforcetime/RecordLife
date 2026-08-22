// 新增记录区域组件：components/AddRecordSection.ets
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import { LifeRecord, ImageInfo } from '../../common/types'
import { RefreshManager } from '../../common/managers/RefreshManager'
import { PromptAction } from '@kit.ArkUI'
import { ImagePickerUtils, ImagePickMode } from '../../common/utils/ImagePickerUtils'
import { TagSelector } from '../common/TagSelector'
import { MoodSelector } from './MoodSelector'
import { TemplateService } from '../../service/TemplateService'
import { RecordTemplate } from '../../model/UserConfigModel'
import { Logger } from '../../common/utils/Logger'

@Component
export struct AddRecordSection {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 文字内容
  @State private textContent: string = ''
  
  // 图片列表（最多9张）
  @State private images: ImageInfo[] = []
  
  // 选中的标签
  @State private selectedTags: string[] = []
  
  // 选中的心情（更新计划二期；'' = 未选择）
  @State private selectedMood: string = ''
  
  // 记录模板（更新计划三期：一键填充）
  @State private templates: RecordTemplate[] = []
  @State private showTemplatePicker: boolean = false
  
  // 是否正在保存
  @State private isSaving: boolean = false
  
  // 最大图片数量
  private readonly MAX_IMAGE_COUNT: number = 9
  
  // ViewModel（直接获取单例实例）
  private viewModel: NowViewModel | null = null
  
  // PromptAction（用于显示 Toast）
  private promptAction: PromptAction | null = null
  
  // 保存成功回调
  onSaveSuccess?: () => void
  
  // 组件初始化时获取 ViewModel
  aboutToAppear() {
    // 获取 PromptAction
    this.promptAction = this.getUIContext().getPromptAction()
    // 同步获取已初始化的 ViewModel 实例
    NowViewModel.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext).then((vm) => {
      this.viewModel = vm
      Logger.info('[AddRecordSection] ViewModel 获取成功')
    })
    // 加载记录模板（更新计划三期）
    TemplateService.getInstance(this.getUIContext().getHostContext() as common.UIAbilityContext).then((ts) => {
      this.templates = ts.getTemplates()
    }).catch((error: BusinessError) => {
      Logger.error('[AddRecordSection] 加载模板失败: ' + JSON.stringify(error))
    })
  }
  
  build() {
    Scroll() {
      Column() {
        // 标题行（含模板按钮，更新计划三期）
        Row() {
          Text($r('app.string.record_now'))
            .fontSize(18)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.themeColors.textPrimary)
            .layoutWeight(1)

          // 模板快捷按钮
          Text($r('app.string.template_use'))
            .fontSize(14)
            .fontColor(this.templates.length > 0 ? this.themeColors.primary : this.themeColors.textTertiary)
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              if (this.templates.length > 0) {
                this.showTemplatePicker = true
              }
            })
        }
        .width('100%')
        .margin({ bottom: 16 })
        .bindSheet($$this.showTemplatePicker, this.TemplatePickerBuilder(), {
          height: '45%',
          backgroundColor: this.themeColors.cardBackground,
          dragBar: true
        })
        
        // 文字输入区域
        TextArea({ placeholder: $r('app.string.record_now_placeholder'), text: $$this.textContent })
          .width('100%')
          .height(120)
          .backgroundColor(this.themeColors.cardBackground)
          .borderRadius(12)
          .border({ width: 1, color: this.themeColors.border })
          .fontColor(this.themeColors.textPrimary)
          .placeholderColor(this.themeColors.textTertiary)
          .padding(12)
        
        // 标签选择区域
        Column() {
          TagSelector({ selectedTagIds: $selectedTags })
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 心情选择区域（更新计划二期）
        Column() {
          MoodSelector({ selectedMood: $selectedMood })
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 图片区域
        Column() {
          // 图片网格
          this.ImageGridBuilder()
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 保存按钮
        Button(this.isSaving ? $r('app.string.saving_in_progress') : $r('app.string.save_record'))
          .width('100%')
          .height(44)
          .backgroundColor(this.themeColors.primary)
          .fontColor('#FFFFFF')
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .borderRadius(12)
          .margin({ top: 16 })
          .enabled(!this.isSaving && this.canSave())
          .onClick(() => {
            this.onSave()
          })
      }
      .width('100%')
      .padding(16)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }
  
  // 模板选择弹层（更新计划三期：一键填充）
  @Builder
  TemplatePickerBuilder() {
    Column() {
      Text($r('app.string.template_use'))
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.themeColors.textPrimary)
        .width('100%')
        .margin({ top: 16, bottom: 12 })

      if (this.templates.length === 0) {
        Column() {
          Text($r('app.string.template_empty'))
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
        }
        .width('100%')
        .padding({ top: 24, bottom: 24 })
      } else {
        List() {
          ForEach(this.templates, (template: RecordTemplate) => {
            ListItem() {
              Column() {
                Text(template.name)
                  .fontSize(15)
                  .fontColor(this.themeColors.textPrimary)
                  .fontWeight(FontWeight.Medium)
                  .width('100%')

                if (template.content.length > 0) {
                  Text(template.content)
                    .fontSize(13)
                    .fontColor(this.themeColors.textSecondary)
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                    .width('100%')
                    .margin({ top: 4 })
                }
              }
              .width('100%')
              .padding({ top: 12, bottom: 12, left: 16, right: 16 })
              .backgroundColor(this.themeColors.background)
              .borderRadius(10)
              .onClick(() => {
                // 一键填充内容
                this.textContent = template.content
                this.showTemplatePicker = false
              })
            }
          }, (template: RecordTemplate) => template.id)
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Off)
        .divider({ strokeWidth: 0.5, color: this.themeColors.border })
        .edgeEffect(EdgeEffect.Spring)
      }
    }
    .width('100%')
    .height('100%')
    .padding({ left: 16, right: 16 })
    .backgroundColor(this.themeColors.cardBackground)
  }

  // 图片网格构建器
  @Builder
  ImageGridBuilder() {
    Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
      // 已选择的图片
      ForEach(this.images, (image: ImageInfo, index: number) => {
        Stack({ alignContent: Alignment.TopEnd }) {
          // 图片
          Image(image.uri)
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
          
          // 删除按钮
          Column() {
            Text('×')
              .fontSize(16)
              .fontColor('#FFFFFF')
              .fontWeight(FontWeight.Bold)
          }
          .width(24)
          .height(24)
          .borderRadius(12)
          .backgroundColor('#80000000')
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 4, right: 4 })
          .onClick(() => {
            this.removeImage(index)
          })
        }
        .width('32%')
        .aspectRatio(1)  // 正方形
        .margin({ right: index % 3 === 2 ? 0 : '2%', bottom: 8 })
      }, (image: ImageInfo) => image.path)  // 使用 path 作为唯一 key
      
      // 添加图片按钮（如果未达到最大数量）
      if (this.images.length < this.MAX_IMAGE_COUNT) {
        Column() {
          Text('+')
            .fontSize(32)
            .fontColor(this.themeColors.textSecondary)
          Text($r('app.string.add_image'))
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 4 })
        }
        .width('32%')
        .aspectRatio(1)  // 正方形
        .backgroundColor(this.themeColors.background)
        .borderRadius(8)
        .border({ width: 1, color: this.themeColors.border, style: BorderStyle.Dashed })
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
        .margin({ right: this.images.length % 3 === 2 ? 0 : '2%', bottom: 8 })
        .onClick(() => {
          this.onPickImage()
        })
      }
    }
    .width('100%')
  }
  
  // 判断是否可以保存（至少有文字或图片）
  private canSave(): boolean {
    return this.textContent.trim().length > 0 || this.images.length > 0
  }
  
  // 选择图片
  private async onPickImage() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const result = await ImagePickerUtils.pickImage(context, ImagePickMode.GALLERY)
      
      if (result.success && result.uri) {
        // 保存图片到沙箱目录（返回 URI 格式）
        if (this.viewModel) {
          const savedUri = await this.viewModel.saveImageToSandbox(result.uri)
          if (savedUri) {
            // 添加到图片列表
            this.images.push({
              path: savedUri,
              uri: savedUri
            })
            Logger.info('[AddRecordSection] 添加图片成功，当前图片数: ' + this.images.length)
          }
        }
      } else if (result.errorMessage && this.promptAction) {
        ImagePickerUtils.showErrorToast(this.promptAction, result.errorMessage)
      }
    } catch (error) {
      Logger.error('[AddRecordSection] 选择图片失败: ' + JSON.stringify(error))
      if (this.promptAction) {
        ImagePickerUtils.showErrorToast(this.promptAction, $r('app.string.pick_image_failed_retry'))
      }
    }
  }
  
  // 移除图片
  private removeImage(index: number) {
    this.images.splice(index, 1)
    Logger.info('[AddRecordSection] 移除图片，当前图片数: ' + this.images.length)
  }
  
  // 保存记录
  private async onSave() {
    if (!this.viewModel || !this.promptAction) {
      if (this.promptAction) {
        try {
          this.promptAction.showToast({ message: $r('app.string.data_manager_not_initialized') })
        } catch (error) {
          Logger.error('[AddRecordSection] showToast failed: ' + JSON.stringify(error))
        }
      }
      return
    }
    
    this.isSaving = true
    
    try {
      // 提取图片路径数组
      const imagePaths = this.images.length > 0 ? this.images.map(img => img.path) : undefined
      
      // 提取标签数组
      const tags = this.selectedTags.length > 0 ? this.selectedTags : undefined
      
      // 提取心情（可选，更新计划二期）
      const mood = this.selectedMood.length > 0 ? this.selectedMood : undefined
      
      // 统一保存记录
      const record = await this.viewModel.addRecord(
        this.textContent.trim(),
        imagePaths,
        tags,
        mood
      )
      
      if (record) {
        try {
          this.promptAction.showToast({ message: $r('app.string.record_save_success') })
        } catch (error) {
          Logger.error('[AddRecordSection] showToast failed: ' + JSON.stringify(error))
        }
        
        // 清空输入
        this.textContent = ''
        this.images = []
        this.selectedTags = []
        this.selectedMood = ''
        
        // 触发全局刷新
        Logger.info('[AddRecordSection] 触发全局刷新')
        RefreshManager.getInstance().refresh()
        
        // 回调
        if (this.onSaveSuccess) {
          this.onSaveSuccess()
        }
      } else {
        try {
          this.promptAction.showToast({ message: $r('app.string.save_failed_retry') })
        } catch (error) {
          Logger.error('[AddRecordSection] showToast failed: ' + JSON.stringify(error))
        }
      }
    } catch (error) {
      Logger.error('[AddRecordSection] 保存失败: ' + JSON.stringify(error))
      try {
        this.promptAction.showToast({ message: (this.getUIContext().getHostContext() as common.UIAbilityContext).resourceManager.getStringByNameSync('save_failed_prefix') + (error as Error).message })
      } catch (e) {
        Logger.error('[AddRecordSection] showToast failed: ' + JSON.stringify(e))
      }
    } finally {
      this.isSaving = false
    }
  }
}
