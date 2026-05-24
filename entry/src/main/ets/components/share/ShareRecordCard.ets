// 分享记录卡片组件：components/share/ShareRecordCard.ets
// 专门用于生成分享图片的组件，样式更简洁美观
import { LifeRecord, DEFAULT_TAGS } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { NowViewModel } from '../../viewmodel/NowViewModel'

@Component
export struct ShareRecordCard {
  @Prop record: LifeRecord = { id: '', timestamp: 0, content: '' }
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // ViewModel
  private viewModel: NowViewModel | null = null
  
  async aboutToAppear() {
    this.viewModel = await NowViewModel.getInstance()
  }
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        // App Logo 和名称
        Row({ space: 8 }) {
          Text('📝')
            .fontSize(20)
          
          Column() {
            Text('记录生活')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            
            Text(this.formatDateTime(this.record.timestamp))
              .fontSize(11)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
        }
        
        Blank()
        
        // 水印
        Text('RecordLife')
          .fontSize(10)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      
      // 分隔线
      Divider()
        .color('#EEEEEE')
        .margin({ left: 20, right: 20 })
      
      // 内容区域
      Column() {
        // 标签显示（如果有）
        if (this.record.tags && this.record.tags.length > 0) {
          Row({ space: 8 }) {
            ForEach(this.record.tags, (tagId: string) => {
              this.TagChip(tagId)
            }, (tagId: string) => tagId)
          }
          .width('100%')
          .margin({ bottom: 12 })
        }
        
        // 文字内容（如果有）
        if (this.record.content && this.record.content.length > 0) {
          Text(this.record.content)
            .fontSize(16)
            .fontColor('#333333')
            .lineHeight(24)
            .width('100%')
            .margin({ bottom: this.record.imagePaths && this.record.imagePaths.length > 0 ? 16 : 0 })
        }
        
        // 图片展示（如果有）
        if (this.record.imagePaths && this.record.imagePaths.length > 0 && this.viewModel) {
          // 单张图片：大图展示
          if (this.record.imagePaths.length === 1) {
            Image(this.viewModel.getImageUri(this.record.imagePaths[0]))
              .width('100%')
              .objectFit(ImageFit.Cover)
              .borderRadius(8)
              .constraintSize({ maxHeight: 400 })
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
              }, (path: string, index: number) => `img-${index}`)
            }
            .width('100%')
          }
        }
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
      
      // 底部水印
      Row() {
        Blank()
        
        Row({ space: 4 }) {
          Text('来自')
            .fontSize(10)
            .fontColor('#CCCCCC')
          
          Text('RecordLife')
            .fontSize(10)
            .fontColor('#007DFF')
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 16 })
    }
    .width(340)
    .backgroundColor('#FFFFFF')
    .borderRadius(4)
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
  }
  
  // 标签芯片
  @Builder
  TagChip(tagId: string) {
    Row({ space: 4 }) {
      if (this.getTagIcon(tagId)) {
        Text(this.getTagIcon(tagId)!)
          .fontSize(12)
      }
      
      Text(this.getTagName(tagId))
        .fontSize(12)
        .fontColor('#FFFFFF')
    }
    .padding({ left: 10, right: 10, top: 4, bottom: 4 })
    .backgroundColor(this.getTagColor(tagId))
    .borderRadius(12)
  }
  
  // 获取标签名称
  private getTagName(tagId: string): string {
    const tag = DEFAULT_TAGS.find(t => t.id === tagId)
    return tag ? tag.name : tagId
  }
  
  // 获取标签颜色
  private getTagColor(tagId: string): string {
    const tag = DEFAULT_TAGS.find(t => t.id === tagId)
    return tag ? tag.color : '#999999'
  }
  
  // 获取标签图标
  private getTagIcon(tagId: string): string | null {
    const tag = DEFAULT_TAGS.find(t => t.id === tagId)
    return tag && tag.icon ? tag.icon : null
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
