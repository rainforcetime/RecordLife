// 记录卡片组件：components/RecordCard.ets
import { LifeRecord } from '../common/types'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { NowViewModel } from '../viewmodel/NowViewModel'
import { ImageViewer } from './ImageViewer'

// 记录卡片操作回调
export interface RecordCardCallbacks {
  onEdit: (record: LifeRecord) => void
  onDelete: (record: LifeRecord) => void
}

@Component
export struct RecordCard {
  @Prop record: LifeRecord = { id: '', timestamp: 0, content: '' }
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 是否显示日期（默认显示）
  @Prop showDate: boolean = true
  
  // 回调函数
  onEdit?: (record: LifeRecord) => void
  onDelete?: (record: LifeRecord) => void
  
  // ViewModel
  private viewModel: NowViewModel | null = null
  
  // 图片预览状态
  @State private showImageViewer: boolean = false
  @State private viewerImageUris: string[] = []
  @State private viewerCurrentIndex: number = 0
  
  async aboutToAppear() {
    this.viewModel = await NowViewModel.getInstance()
  }
  
  build() {
    Column() {
      // 文字内容（如果有）
      if (this.record.content && this.record.content.length > 0) {
        Text(this.record.content)
          .fontSize(15)
          .fontColor(this.themeColors.textPrimary)
          .width('100%')
          .lineHeight(22)
      }
      
      // 图片网格（如果有）
      if (this.record.imagePaths && this.record.imagePaths.length > 0 && this.viewModel) {
        // 单张图片：大图展示
        if (this.record.imagePaths.length === 1) {
          Image(this.viewModel.getImageUri(this.record.imagePaths[0]))
            .width('100%')
            .height('auto')
            .objectFit(ImageFit.Cover)
            .borderRadius(8)
            .constraintSize({ maxHeight: 300 })
            .margin({ top: this.record.content ? 12 : 0 })
            .onClick(() => {
              this.openImageViewer([this.viewModel!.getImageUri(this.record.imagePaths![0])], 0)
            })
        } else {
          // 多张图片：网格布局（一行三张，正方形）
          Flex({ wrap: FlexWrap.Wrap, alignContent: FlexAlign.Start }) {
            ForEach(this.record.imagePaths, (path: string, index: number) => {
              Image(this.viewModel!.getImageUri(path))
                .width('32%')
                .aspectRatio(1)  // 正方形
                .objectFit(ImageFit.Cover)
                .borderRadius(4)
                .margin({ right: index % 3 === 2 ? 0 : '2%', bottom: index < this.record.imagePaths!.length - 3 ? 4 : 0 })
                .onClick(() => {
                  this.openImageViewerFromPath(index)
                })
            }, (path: string, index: number) => `image-${index}`)
          }
          .width('100%')
          .margin({ top: this.record.content ? 12 : 0 })
        }
      }
      
      // 底部信息栏：时间 + 操作按钮
      Row() {
        // 时间戳
        Text(this.formatTime(this.record.timestamp))
          .fontSize(13)
          .fontColor(this.themeColors.textSecondary)
        
        Blank()
        
        // 操作按钮
        this.ActionButtons()
      }
      .width('100%')
      .margin({ top: this.record.content || (this.record.imagePaths && this.record.imagePaths.length > 0) ? 12 : 0 })
    }
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .padding({ left: 16, right: 16, top: 16, bottom: 12 })
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
    .width('100%')
    .alignItems(HorizontalAlign.Start)
    .bindContentCover($$this.showImageViewer, this.ImageViewerBuilder(), {
      modalTransition: ModalTransition.DEFAULT
    })
  }
  
  // 打开图片预览（从路径数组）
  private openImageViewerFromPath(index: number) {
    if (!this.viewModel || !this.record.imagePaths) {
      return
    }
    
    const imageUris: string[] = []
    for (let i = 0; i < this.record.imagePaths.length; i++) {
      imageUris.push(this.viewModel.getImageUri(this.record.imagePaths[i]))
    }
    
    this.viewerImageUris = imageUris
    this.viewerCurrentIndex = index
    this.showImageViewer = true
  }
  
  // 打开图片预览
  private openImageViewer(uris: string[], index: number) {
    this.viewerImageUris = uris
    this.viewerCurrentIndex = index
    this.showImageViewer = true
  }
  
  // 图片预览构建器
  @Builder
  ImageViewerBuilder() {
    ImageViewer({
      imageUris: this.viewerImageUris,
      currentIndex: this.viewerCurrentIndex,
      onClose: () => {
        this.showImageViewer = false
      }
    })
  }
  
  // 操作按钮
  @Builder
  ActionButtons() {
    Row({ space: 16 }) {
      // 编辑按钮
      Image($r('sys.media.ohos_ic_public_edit'))
        .width(18)
        .height(18)
        .fillColor(this.themeColors.iconColor)
        .onClick(() => {
          if (this.onEdit) {
            this.onEdit(this.record)
          }
        })
      
      // 删除按钮
      Image($r('sys.media.ohos_ic_public_remove'))
        .width(18)
        .height(18)
        .fillColor(this.themeColors.error)
        .onClick(() => {
          if (this.onDelete) {
            this.onDelete(this.record)
          }
        })
    }
  }
  
  // 格式化时间（只显示时分）
  private formatTime(timestamp: number): string {
    const date = new Date(timestamp)
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    
    if (this.showDate) {
      // 显示完整日期时间
      const year = date.getFullYear()
      const month = (date.getMonth() + 1).toString().padStart(2, '0')
      const day = date.getDate().toString().padStart(2, '0')
      return `${year}-${month}-${day} ${hours}:${minutes}`
    } else {
      // 只显示时分
      return `${hours}:${minutes}`
    }
  }
}
