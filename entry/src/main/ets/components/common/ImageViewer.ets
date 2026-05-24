// 图片预览组件：components/ImageViewer.ets
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'
import photoAccessHelper from '@ohos.file.photoAccessHelper'
import fs from '@ohos.file.fs'
import common from '@ohos.app.ability.common'
import promptAction from '@ohos.promptAction'

@Component
export struct ImageViewer {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 图片列表
  @Prop imageUris: string[] = []
  
  // 当前显示的图片索引
  @Prop currentIndex: number = 0
  
  // 关闭回调
  onClose?: () => void
  
  // 保存图片到图库（在SaveButton点击后调用）
  private async saveImageToGallery(): Promise<void> {
    if (this.imageUris.length === 0 || this.currentIndex >= this.imageUris.length) {
      return
    }
    
    try {
      const context = getContext(this) as common.UIAbilityContext
      const helper = photoAccessHelper.getPhotoAccessHelper(context)
      
      // 获取当前图片URI
      const imageUri = this.imageUris[this.currentIndex]
      console.info('[ImageViewer] 保存图片: ' + imageUri)
      
      // 1. 通过 createAsset 创建图片文件（SaveButton 授权后 10 秒内有效）
      const targetUri = await helper.createAsset(photoAccessHelper.PhotoType.IMAGE, 'jpg')
      console.info('[ImageViewer] 创建目标文件: ' + targetUri)
      
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
      
      console.info('[ImageViewer] 图片保存成功')
      promptAction.showToast({
        message: '已保存到图库',
        duration: 2000
      })
    } catch (error) {
      console.error('[ImageViewer] 保存图片失败: ' + JSON.stringify(error))
      promptAction.showToast({
        message: '保存失败',
        duration: 2000
      })
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
      // 1. 底层：半透明黑色背景（点击关闭）
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#CC000000')
        .onClick(() => {
          this.closeViewer()
        })
      
      // 2. 中层：图片展示区域（居中，点击不关闭）
      if (this.imageUris.length > 0 && this.currentIndex < this.imageUris.length) {
        Image(this.imageUris[this.currentIndex])
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .onClick(() => {
            // 点击图片不做任何操作，阻止事件冒泡
          })
      }
      
      // 3. 顶层：工具栏（使用绝对定位）
      Column() {
        // 顶部工具栏
        Row() {
          // 关闭按钮
          Image($r('sys.media.ohos_ic_public_arrow_left'))
            .width(24)
            .height(24)
            .fillColor('#FFFFFF')
            .onClick(() => {
              this.closeViewer()
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
        
        Blank()
        
        // 底部工具栏
        Row() {
          Blank()
          
          // 使用SaveButton安全控件保存图片
          SaveButton({ text: SaveDescription.SAVE_IMAGE, buttonType: ButtonType.Normal })
            .width(100)
            .height(36)
            .borderRadius(18)
            .backgroundColor('rgba(255, 255, 255, 0.2)')
            .onClick(async (event: ClickEvent, result: SaveButtonOnClickResult) => {
              if (result === SaveButtonOnClickResult.SUCCESS) {
                await this.saveImageToGallery()
              } else {
                promptAction.showToast({
                  message: '授权失败',
                  duration: 2000
                })
              }
            })
        }
        .width('100%')
        .height(56)
        .padding({ left: 16, right: 16 })
      }
      .width('100%')
      .height('100%')
      .onClick(() => {
        // 工具栏区域点击穿透到背景（关闭预览）
        this.closeViewer()
      })
    }
    .width('100%')
    .height('100%')
  }
}
