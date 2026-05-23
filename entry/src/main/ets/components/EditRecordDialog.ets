// 编辑记录对话框组件：components/EditRecordDialog.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { LifeRecord, ImageInfo } from '../common/types'
import { ImagePickerUtils, ImagePickMode, ImagePickResult } from '../common/utils/ImagePickerUtils'
import { common } from '@kit.AbilityKit'
import { PromptAction } from '@kit.ArkUI'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { TagSelector } from './TagSelector'

@Component
export struct EditRecordDialog {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 编辑的记录
  @Prop record: LifeRecord | null = null
  
  // 编辑内容
  @Link editContent: string
  
  // 图片路径列表 - 使用 @Prop 接收初始值
  @Prop editImagePaths: string[] = []
  
  // 本地图片数组副本（用于 UI 渲染）
  @State private localImagePaths: string[] = []
  
  // 选中的标签
  @Link editTags: string[]
  
  // 图片路径更新回调
  onImagePathsChange: ((paths: string[]) => void) | null = null
  
  // 保存回调
  onSave: () => void = () => {}
  
  // 取消回调
  onCancel: () => void = () => {}
  
  // 保存图片到沙箱的回调（由父组件提供）
  saveImageToSandbox: ((uri: string) => Promise<string | null>) | null = null
  
  // PromptAction（用于显示 Toast）
  private promptAction: PromptAction | null = null
  
  // ViewModel
  private viewModel: NowViewModel | null = null
  
  // 最大图片数量
  private readonly MAX_IMAGE_COUNT: number = 9
  
  async aboutToAppear() {
    this.promptAction = this.getUIContext().getPromptAction()
    this.viewModel = await NowViewModel.getInstance()
    
    // 初始化本地数组副本
    this.localImagePaths = [...this.editImagePaths]
    console.info('[EditRecordDialog] aboutToAppear, 初始化本地数组: ' + JSON.stringify(this.localImagePaths))
  }
  
  // 监听 prop 变化，同步到本地数组
  aboutToReuse(params: Record<string, Object>) {
    this.localImagePaths = [...this.editImagePaths]
    console.info('[EditRecordDialog] aboutToReuse, 同步本地数组: ' + JSON.stringify(this.localImagePaths))
  }
  
  build() {
    Scroll() {
      Column() {
        Text('编辑记录')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .width('100%')
          .margin({ bottom: 16 })
        
        // 文字内容输入
        TextArea({ placeholder: '输入内容...', text: $$this.editContent })
          .width('100%')
          .height(100)
          .backgroundColor(this.themeColors.background)
          .borderRadius(12)
          .border({ width: 1, color: this.themeColors.border })
          .fontColor(this.themeColors.textPrimary)
          .padding(12)
        
        // 标签选择区域
        Column() {
          TagSelector({ selectedTagIds: $editTags })
        }
        .width('100%')
        .margin({ top: 16 })
        
        // 图片区域
        this.ImageGridBuilder()
        
        // 操作按钮
        Row() {
          Button('取消')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(this.themeColors.background)
            .fontColor(this.themeColors.textSecondary)
            .borderRadius(12)
            .onClick(() => {
              this.onCancel()
            })
          
          Button('保存')
            .layoutWeight(1)
            .height(44)
            .backgroundColor(this.themeColors.primary)
            .fontColor('#FFFFFF')
            .borderRadius(12)
            .margin({ left: 12 })
            .onClick(() => {
              this.onSave()
            })
        }
        .width('100%')
        .margin({ top: 16 })
      }
      .width('100%')
      .padding(20)
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }
  
  // 图片网格构建器
  @Builder
  ImageGridBuilder() {
    Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
      // 已选择的图片
      ForEach(this.localImagePaths, (path: string, index: number) => {
        Stack({ alignContent: Alignment.TopEnd }) {
          // 图片
          Image(this.viewModel ? this.viewModel.getImageUri(path) : path)
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
      }, (path: string) => path)  // 使用 path 作为唯一 key
      
      // 添加图片按钮（如果未达到最大数量）
      if (this.localImagePaths.length < this.MAX_IMAGE_COUNT) {
        Column() {
          Text('+')
            .fontSize(32)
            .fontColor(this.themeColors.textSecondary)
          Text('添加图片')
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
        .margin({ right: this.localImagePaths.length % 3 === 2 ? 0 : '2%', bottom: 8 })
        .onClick(() => {
          this.onPickImage()
        })
      }
    }
    .width('100%')
    .margin({ top: 16 })
  }
  
  // 选择图片
  private async onPickImage() {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const result: ImagePickResult = await ImagePickerUtils.pickImage(context, ImagePickMode.GALLERY)
      
      if (result.success && result.uri) {
        // 保存图片到沙箱目录
        if (this.saveImageToSandbox) {
          const savedUri = await this.saveImageToSandbox(result.uri)
          if (savedUri) {
            // 更新本地数组
            this.localImagePaths = [...this.localImagePaths, savedUri]
            
            // 通知父组件
            if (this.onImagePathsChange) {
              this.onImagePathsChange(this.localImagePaths)
            }
            console.info('[EditRecordDialog] 添加图片成功，当前图片数: ' + this.localImagePaths.length)
          }
        }
      } else if (result.errorMessage && this.promptAction) {
        ImagePickerUtils.showErrorToast(this.promptAction, result.errorMessage)
      }
    } catch (error) {
      console.error('[EditRecordDialog] 选择图片失败: ' + JSON.stringify(error))
      if (this.promptAction) {
        ImagePickerUtils.showErrorToast(this.promptAction, '选择图片失败，请重试')
      }
    }
  }
  
  // 移除图片
  private removeImage(index: number) {
    // 更新本地数组（创建新数组触发 @State 更新）
    const newPaths: string[] = []
    for (let i = 0; i < this.localImagePaths.length; i++) {
      if (i !== index) {
        newPaths.push(this.localImagePaths[i])
      }
    }
    
    // 更新本地数组
    this.localImagePaths = newPaths
    
    // 通知父组件
    if (this.onImagePathsChange) {
      this.onImagePathsChange(this.localImagePaths)
    }
  }
}
