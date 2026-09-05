// 图片预览组件：components/ImageViewer.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { fileIo as fs, fileUri } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { promptAction } from '@kit.ArkUI'
import { CosConfig } from '../../model/UserConfigModel'
import { CosService } from '../../service/CosService'
import { ConfigManager } from '../../config/ConfigManager'
import { Logger } from '../../common/utils/Logger'

@Component
export struct ImageViewer {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 图片列表
  @Prop imageUris: string[] = []
  
  // 云端原图 key 列表（可选，与 imageUris 一一对应；图片存储优化 M3）
  @Prop imageCloudKeys: string[] = []
  
  // 当前显示的图片索引
  @Prop currentIndex: number = 0

  // 当前显示索引（Swiper 滑动同步）
  @State private displayIndex: number = 0

  // 原图态（图片存储优化 M3：查看原图后当前页替换为原图显示）
  @State private showingOriginal: boolean = false
  @State private originalUri: string = ''
  @State private downloadingOriginal: boolean = false
  private cosConfig: CosConfig | null = null

  // 缩放状态（捏合/双击，1~5 倍）
  @State private scaleValue: number = 1
  @State private baseScale: number = 1
  @State private isZoomed: boolean = false

  // 平移状态（放大后单指拖动查看）
  @State private offsetX: number = 0
  @State private offsetY: number = 0
  @State private panActive: boolean = false
  @State private panStartX: number = 0
  @State private panStartY: number = 0
  
  // 关闭回调
  onClose?: () => void

  aboutToAppear() {
    this.displayIndex = this.currentIndex
    // 图片存储优化 M3：读取云存储配置（用于查看原图）
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      ConfigManager.getInstance(context).then((cm: ConfigManager) => {
        this.cosConfig = cm.getCosConfig()
      }).catch((e: Error) => {
        Logger.error('[ImageViewer] 获取云存储配置失败: ' + JSON.stringify(e))
      })
    } catch (error) {
      Logger.error('[ImageViewer] 获取上下文失败: ' + JSON.stringify(error))
    }
  }

  // 当前页是否有云端原图（云存储未配置或总开关关闭时不显示查看原图）
  private hasCloudOriginal(): boolean {
    if (!this.cosConfig || this.cosConfig.enabled === false) {
      return false
    }
    if (this.displayIndex < 0 || this.displayIndex >= this.imageCloudKeys.length) {
      return false
    }
    const key = this.imageCloudKeys[this.displayIndex]
    return key !== undefined && key !== null && key.length > 0
  }

  // 获取当前页显示 URI（原图态下替换为下载的原图）
  private getDisplayUri(uri: string): string {
    if (this.showingOriginal && this.originalUri.length > 0 &&
      this.displayIndex >= 0 && this.displayIndex < this.imageUris.length &&
      uri === this.imageUris[this.displayIndex]) {
      return this.originalUri
    }
    return uri
  }

  // 查看原图：下载云端原图到缓存并替换当前页显示
  private async downloadOriginal(): Promise<void> {
    if (!this.cosConfig || !this.hasCloudOriginal() || this.downloadingOriginal) {
      return
    }
    const key = this.imageCloudKeys[this.displayIndex]
    if (!key) {
      return
    }
    this.downloadingOriginal = true
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const destPath = `${context.cacheDir}/original_${this.displayIndex}_${Date.now()}.jpg`
      const ok = await CosService.downloadFile(this.cosConfig, key, destPath)
      if (ok) {
        this.originalUri = fileUri.getUriFromPath(destPath)
        this.showingOriginal = true
      } else {
        this.getUIContext().getPromptAction().showToast({
          message: $r('app.string.cloud_test_failed'),
          duration: 2000
        })
      }
    } catch (error) {
      Logger.error('[ImageViewer] 下载原图失败: ' + JSON.stringify(error))
      try {
        this.getUIContext().getPromptAction().showToast({
          message: $r('app.string.cloud_test_failed'),
          duration: 2000
        })
      } catch (toastError) {
        Logger.warn('[ImageViewer] showToast 失败: ' + JSON.stringify(toastError))
      }
    } finally {
      this.downloadingOriginal = false
    }
  }

  // 复位原图态
  private resetOriginalState() {
    this.showingOriginal = false
    this.originalUri = ''
  }

  // 设置缩放（1~5 倍，>1 视为已放大并锁定 Swiper 滑动）
  private setScale(scale: number) {
    const clamped = scale < 1 ? 1 : (scale > 5 ? 5 : scale)
    this.scaleValue = clamped
    this.isZoomed = clamped > 1.01
    if (!this.isZoomed) {
      // 还原到 1x 时复位平移
      this.offsetX = 0
      this.offsetY = 0
    }
  }

  // 平移边界限制（随缩放比例，近似容器尺寸）
  private clampOffset() {
    const maxX = (this.scaleValue - 1) * 100
    const maxY = (this.scaleValue - 1) * 150
    if (this.offsetX > maxX) {
      this.offsetX = maxX
    }
    if (this.offsetX < -maxX) {
      this.offsetX = -maxX
    }
    if (this.offsetY > maxY) {
      this.offsetY = maxY
    }
    if (this.offsetY < -maxY) {
      this.offsetY = -maxY
    }
  }

  // 双击放大/还原（1x ↔ 2.5x）
  private toggleZoom() {
    if (this.isZoomed) {
      this.setScale(1)
    } else {
      this.setScale(2.5)
    }
  }
  
  // 保存图片到图库（在SaveButton点击后调用；原图态保存原图，普通态保存压缩图）
  private async saveImageToGallery(): Promise<void> {
    if (this.imageUris.length === 0 || this.displayIndex >= this.imageUris.length) {
      return
    }
    
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext
      const helper = photoAccessHelper.getPhotoAccessHelper(context)
      
      // 获取当前图片URI（原图态优先原图）
      const imageUri = this.showingOriginal && this.originalUri.length > 0 ?
        this.originalUri : this.imageUris[this.displayIndex]
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
      
      // 2. 中层：图片展示区域（Swiper 滑动切换；缩放/平移手势在外部 Stack，免受 Swiper 禁用影响）
      if (this.imageUris.length > 0) {
        Stack() {
          Swiper() {
            ForEach(this.imageUris, (uri: string) => {
              Image(this.getDisplayUri(uri))
                .width('100%')
                .height('100%')
                .objectFit(ImageFit.Contain)
                .draggable(false)
                .scale({ x: this.scaleValue, y: this.scaleValue })
                .translate({ x: this.offsetX, y: this.offsetY })
            }, (uri: string) => uri)
          }
          .index(this.currentIndex)
          .indicator(false)
          .loop(false)
          // 放大时锁定 Swiper 滑动（背景已不响应点击，不会误关闭）
          .enabled(!this.isZoomed)
          .onChange((index: number) => {
            this.displayIndex = index
            this.setScale(1)  // 切换图片时复位缩放
            this.resetOriginalState()  // 切换图片时复位原图态
          })
          .width('100%')
          .height('100%')
        }
        .width('100%')
        .height('100%')
        // 手势在 Swiper 外层：Swiper 禁用不影响；双指捏合/双击/parallel 平移不抢单指滑动
        .gesture(
          PinchGesture({ fingers: 2 })
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
        // 平移挂 Stack 层 parallel（3.0.24 已验证滑动/缩放/平移共存；不覆盖 Pinch/Tap）
        .parallelGesture(
          PanGesture({ fingers: 1 })
            .onActionStart(() => {
              this.panActive = this.isZoomed
              this.panStartX = this.offsetX
              this.panStartY = this.offsetY
            })
            .onActionUpdate((event: GestureEvent) => {
              if (this.panActive) {
                this.offsetX = this.panStartX + event.offsetX
                this.offsetY = this.panStartY + event.offsetY
                this.clampOffset()
              }
            })
        )
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
        
        // 底部工具栏（半透明深色圆角条；查看原图 / 保存图片）
        Column() {
          Row() {
            Blank()

            // 有云端原图且未显示原图：显示「查看原图」（图片存储优化 M3）
            if (this.hasCloudOriginal() && !this.showingOriginal) {
              Button($r('app.string.view_original'))
                .width(140)
                .height(44)
                .borderRadius(22)
                .backgroundColor('rgba(255, 255, 255, 0.16)')
                .fontSize(15)
                .fontColor('#FFFFFF')
                .enabled(!this.downloadingOriginal)
                .onClick(() => {
                  this.downloadOriginal()
                })
            } else {
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
            }

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
