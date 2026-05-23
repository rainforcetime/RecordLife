// 图片预览组件：components/ImageViewer.ets
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'

@Component
export struct ImageViewer {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 图片列表
  @Prop imageUris: string[] = []
  
  // 当前显示的图片索引
  @Prop currentIndex: number = 0
  
  // 关闭回调
  onClose?: () => void
  
  build() {
    Stack() {
      // 半透明黑色背景
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#CC000000')
        .onClick(() => {
          if (this.onClose) {
            this.onClose()
          }
        })
      
      // 图片内容
      Column() {
        // 顶部工具栏
        Row() {
          // 关闭按钮
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
            .onClick(() => {
              if (this.onClose) {
                this.onClose()
              }
            })
          
          Blank()
          
          // 图片计数
          if (this.imageUris.length > 1) {
            Text(`${this.currentIndex + 1} / ${this.imageUris.length}`)
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        
        // 图片展示区域
        if (this.imageUris.length > 0 && this.currentIndex < this.imageUris.length) {
          Image(this.imageUris[this.currentIndex])
            .width('100%')
            .height('100%')
            .objectFit(ImageFit.Contain)
            .layoutWeight(1)
        }
        
        // 底部占位（保持对称）
        Row()
          .width('100%')
          .height(56)
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
  }
}
