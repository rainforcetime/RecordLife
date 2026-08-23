// 图片预览组件：components/ImageViewer.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo as fs } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { Logger } from '../../common/utils/Logger'

@Component
export struct ImageViewer {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 图片列表
  @Prop imageUris: string[] = []
  
  // 当前显示的图片索引
  @Prop currentIndex: number = 0

  // 当前显示索引（Swiper 滑动同步）
  @State private displayIndex: number = 0

  // 缩放状态（捏合/双击，1~5 倍）
  @State private scaleValue: number = 1
  @State private baseScale: number = 1
  @State private isZoomed: boolean = false
  
  // 关闭回调
  onClose?: () => void

  aboutToAppear() {
    this.displayIndex = this.currentIndex
  }

  // 设置缩放（1~5 倍，>1 视为已放大并锁定 Swiper 滑动）
  private setScale(scale: number) {
    const clamped = scale < 1 ? 1 : (scale > 5 ? 5 : scale)
    this.scaleValue = clamped
    this.isZoomed = clamped > 1.01
  }

  // 双击放大/还原（1x ↔ 2.5x）
  private toggleZoom() {
    if (this.isZoomed) {
      this.setScale(1)
    } else {
      this.setScale(2.5)
    }
  }
  
  // 保存图片到图库（在SaveButton点击后调用）
  private async saveImageToGallery(): Promise<void> {
    if (this.imageUris.length === 0 || this.currentIndex >= this.imageUris.length) {
      return
    }
    
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const helper = photoAccessHelper.getPhotoAccessHelper(context)
      
      // 获取当前图片URI
      const imageUri = this.imageUris[this.currentIndex]
      Logger.info('[ImageViewer] 保存图片: ' + imageUri)
      
      // 1. 通过 createAsset 创建图片文件（SaveButton 授权后 10 秒内有效）
      const targetUri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg')
      Logger.info('[ImageViewer] 创建目标文件: ' + targetUri)
      
      // 2. 打开目标文件
      const targetFile = await fs.open(targetUri, fs.OpenMode.READ_WRITE)
      
      // 3. 打开源文件并读取内容
      const sourceFile = fs.openSync(imageUri, fs.OpenMode.READ_ONLY)
      const stat = fs.statSync(imageUri)
      const fileSize = stat.size
      
      // 4. 复制文件内容
      const buffer = new ArrayBuffer(fileSize)
      fs.readSync(sourceFile.fd, buffer)
      fs.closeSync(sourceFile)
      
      // 5. 写入目标文件
      await fs.write(targetFile.fd, buffer)
      await fs.close(targetFile.fd)
      
      Logger.info('[ImageViewer] 图片保存成功')
      this.getUIContext().getPromptAction().showToast({
        message: $r('app.string.saved_to_gallery'),
        duration: 2000
      })
    } catch (error) {
      Logger.error('[ImageViewer] 保存图片失败: ' + JSON.stringify(error))
      try {
        this.getUIContext().getPromptAction().showToast({
          message: $r('app.string.save_failed'),
          duration: 2000
        })
      } catch (e) {
        Logger.error('[ImageViewer] 显示Toast失败: ' + JSON.stringify(e))
      }
    }
  }
  
  // 关闭预览
  private closeViewer() {
    if (this.onClose) {
      this.onClose()
    }
  }
  
  build() {
    Stack() {
      // 1. 底层：半透明黑色背景（仅遮罩，不响应点击——避免误关闭）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#CC000000')
      
      // 2. 中层：图片展示区域（Swiper 滑动切换 + 外层捏合/双击缩放）
      if (this.imageUris.length > 0) {
        Swiper() {
          ForEach(this.imageUris, (uri: string) => {
            Image(uri)
              .width('100%')
              .height('100%')
              .objectFit(ImageFit.Contain)
              .draggable(false)
              .scale({ x: this.scaleValue, y: this.scaleValue })
          }, (uri: string) => uri)
        }
        .index(this.currentIndex)
        .indicator(false)
        .loop(false)
        // 不通过 enabled 禁用 Swiper（禁用后触摸穿透会导致误关闭预览）；双指捏合与单指滑动天然不冲突
        .gesture(
          PinchGesture()
            .onActionStart(() => {
              this.baseScale = this.scaleValue
            })
            .onActionUpdate((event: GestureEvent) => {
              this.setScale(this.baseScale * event.scale)
            })
        )
        .gesture(
          TapGesture({ count: 2 })
            .onAction(() => {
              this.toggleZoom()
            })
        )
        .onChange((index: number) => {
          this.displayIndex = index
          this.setScale(1)  // 切换图片时复位缩放
        })
        .width('100%')
        .height('100%')
        .hitTestBehavior(HitTestMode.Block)
      }
      
      // 3. 顶层：工具栏
      Column() {
        // 顶部工具栏（添加安全区域顶部避让）
        Row() {
          // 关闭按钮（圆形半透明深色底，与底部工具条呼应；系统返回键同样可关闭）
          Column() {
            Image($r('sys.media.ohos_ic_public_arrow_left'))
              .width(20)
              .height(20)
              .fillColor('#FFFFFF')
          }
          .width(40)
          .height(40)
          .borderRadius(20)
          .backgroundColor('rgba(0, 0, 0, 0.35)')
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            this.closeViewer()
          })
          
          Blank()
          
          // 图片计数（随滑动更新）
          if (this.imageUris.length > 1) {
            Text(`${this.displayIndex + 1} / ${this.imageUris.length}`)
              .fontSize(16)
              .fontColor('#FFFFFF')
          }
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
        .margin({ top: 48 })  // 添加顶部 margin 避让状态栏（典型状态栏高度约 48vp）
        
        Blank()
        
        // 底部工具栏（半透明深色圆角条 + 下载图标保存按钮）
        Column() {
          Row() {
            Blank()

            // 使用SaveButton安全控件保存图片（免权限；该 SDK 无 SaveIcon 枚举，纯文字）
            SaveButton({
              text: SaveDescription.SAVE_IMAGE,
              buttonType: ButtonType.Normal
            })
              .width(140)
              .height(44)
              .borderRadius(22)
              .backgroundColor('rgba(255, 255, 255, 0.16)')
              .fontSize(15)
              .onClick(async (event: ClickEvent, result: SaveButtonOnClickResult) => {
                if (result === SaveButtonOnClickResult.SUCCESS) {
                  await this.saveImageToGallery()
                } else {
                  this.getUIContext().getPromptAction().showToast({
                    message: $r('app.string.authorization_failed'),
                    duration: 2000
                  })
                }
              })

            Blank()
          }
          .width('100%')
        }
        .width('100%')
        .padding({ top: 12, bottom: 24 })
        .backgroundColor('rgba(0, 0, 0, 0.35)')
      }
      .width('100%')
      .height('100%')
      .hitTestBehavior(HitTestMode.Transparent)  // 让工具栏区域的空白点击穿透到下层
    }
    .width('100%')
    .height('100%')
    // 扩展安全区域，让背景延伸到状态栏和导航条区域
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
