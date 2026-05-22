// 记录卡片组件：components/RecordCard.ets
import { LifeRecord } from '../common/types'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { NowViewModel } from '../viewmodel/NowViewModel'

// 记录卡片操作回调
export interface RecordCardCallbacks {
  onEdit: (record: LifeRecord) => void
  onDelete: (record: LifeRecord) => void
}

@Component
export struct RecordCard {
  @Prop record: LifeRecord = { id: '', timestamp: 0, content: '' }
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 回调函数
  onEdit?: (record: LifeRecord) => void
  onDelete?: (record: LifeRecord) => void
  
  // ViewModel
  private viewModel: NowViewModel | null = null
  
  async aboutToAppear() {
    this.viewModel = await NowViewModel.getInstance()
  }
  
  build() {
    Column() {
      // 图片（如果有）
      if (this.record.imagePath && this.viewModel) {
        Image(this.viewModel.getImageUri(this.record.imagePath))
          .width(120)
          .height('auto')
          .objectFit(ImageFit.Contain)
          .borderRadius(8)
          .constraintSize({ maxHeight: 200 })
      }
      
      // 时间戳
      Row() {
        Text('📅 ' + this.formatDateTime(this.record.timestamp))
          .fontSize(12)
          .fontColor(this.themeColors.textSecondary)
        
        Blank()
        
        // 操作按钮
        this.ActionButtons()
      }
      .width('100%')
      .margin({ top: this.record.imagePath ? 8 : 0 })
      
      // 文字内容（如果有）
      if (this.record.content && this.record.content.length > 0) {
        Text(this.record.content)
          .fontSize(14)
          .fontColor(this.themeColors.textPrimary)
          .margin({ top: 8 })
          .width('100%')
          .lineHeight(20)
      }
    }
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(12)
    .padding({ left: 12, right: 12, top: 12, bottom: 12 })
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
    .width('90%')
    .alignItems(HorizontalAlign.Start)
  }
  
  // 操作按钮
  @Builder
  ActionButtons() {
    Row() {
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
        .margin({ left: 12 })
        .onClick(() => {
          if (this.onDelete) {
            this.onDelete(this.record)
          }
        })
    }
  }
  
  // 格式化日期时间
  private formatDateTime(timestamp: number): string {
    const date = new Date(timestamp)
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${year}-${month}-${day} ${hours}:${minutes}`
  }
}
