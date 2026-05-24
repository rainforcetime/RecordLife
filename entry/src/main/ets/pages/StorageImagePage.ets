// 存储图片页面：pages/StorageImagePage.ets
import { common } from '@kit.AbilityKit'
import { fileIo as fs, fileUri, storageStatistics } from '@kit.CoreFileKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { RefreshManager } from '../common/managers/RefreshManager'

// 图片信息接口
interface ImageInfo {
  name: string           // 文件名
  uri: string            // 图片URI
  size: string           // 文件大小（格式化后）
  sizeBytes: number      // 文件大小（字节）
  path: string           // 文件路径
}

@Entry
@Component
struct StorageImagePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 图片列表
  @State imageList: ImageInfo[] = []
  
  // 加载状态
  @State isLoading: boolean = true
  
  // 图片总大小（字节）
  @State totalImageSize: number = 0
  
  // 设备可用存储空间（字节）
  @State freeStorageSize: number = 0
  
  // 应用上下文
  private context: common.UIAbilityContext | null = null
  
  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      
      // 注册全局刷新回调
      RefreshManager.getInstance().register('StorageImagePage', () => {
        console.info('[StorageImagePage] 收到全局刷新通知')
        this.loadSandboxImages()
      })
      
      // 加载沙箱目录中的图片
      await this.loadSandboxImages()
    } catch (error) {
      console.error('[StorageImagePage] 初始化失败: ' + JSON.stringify(error))
      this.isLoading = false
    }
  }
  
  // 页面销毁时注销回调
  aboutToDisappear() {
    console.info('[StorageImagePage] aboutToDisappear')
    // 注销刷新回调
    RefreshManager.getInstance().unregister('StorageImagePage')
  }
  
  // 页面显示时刷新数据
  async onPageShow() {
    console.info('[StorageImagePage] onPageShow')
    // 重新加载图片列表
    await this.loadSandboxImages()
  }
  
  // 加载沙箱目录中的图片
  private async loadSandboxImages() {
    try {
      this.isLoading = true
      this.imageList = []
      this.totalImageSize = 0
      
      if (!this.context) {
        console.error('[StorageImagePage] context为空')
        this.isLoading = false
        return
      }
      
      // 获取记录图片目录路径（与 NowViewModel 保存路径一致）
      const recordsPath = `${this.context.filesDir}/records`
      console.info('[StorageImagePage] 记录图片目录路径: ' + recordsPath)
      
      // 检查目录是否存在
      if (!fs.accessSync(recordsPath)) {
        console.info('[StorageImagePage] 记录图片目录不存在')
        this.isLoading = false
        // 仍然获取设备可用存储空间
        await this.loadFreeStorageSize()
        return
      }
      
      // 获取目录下的所有文件
      const filenames = fs.listFileSync(recordsPath)
      console.info('[StorageImagePage] 找到文件数量: ' + filenames.length)
      
      // 过滤出图片文件（支持常见图片格式）
      const imageExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp', '.svg']
      const imageFiles = filenames.filter(filename => {
        const lowerName = filename.toLowerCase()
        return imageExtensions.some(ext => lowerName.endsWith(ext))
      })
      
      console.info('[StorageImagePage] 图片文件数量: ' + imageFiles.length)
      
      // 处理每个图片文件
      for (const filename of imageFiles) {
        try {
          const fullPath = recordsPath + '/' + filename
          
          // 获取文件信息
          const stat = fs.statSync(fullPath)
          
          // 转换为URI
          const uri = fileUri.getUriFromPath(fullPath)
          
          // 格式化文件大小
          const sizeStr = this.formatFileSize(stat.size)
          
          // 添加到列表
          this.imageList.push({
            name: filename,
            uri: uri,
            size: sizeStr,
            sizeBytes: stat.size,
            path: fullPath
          })
          
          // 累加图片总大小
          this.totalImageSize += stat.size
        } catch (error) {
          console.error('[StorageImagePage] 处理文件失败: ' + filename + ', 错误: ' + JSON.stringify(error))
        }
      }
      
      // 按文件大小降序排序
      this.imageList.sort((a, b) => b.sizeBytes - a.sizeBytes)
      
      // 获取设备可用存储空间
      await this.loadFreeStorageSize()
      
      this.isLoading = false
    } catch (error) {
      console.error('[StorageImagePage] 加载图片失败: ' + JSON.stringify(error))
      this.isLoading = false
    }
  }
  
  // 获取设备可用存储空间
  private async loadFreeStorageSize() {
    try {
      const freeSize = await storageStatistics.getFreeSize()
      this.freeStorageSize = freeSize
    } catch (error) {
      console.error('[StorageImagePage] 获取可用存储空间失败: ' + JSON.stringify(error))
      this.freeStorageSize = 0
    }
  }
  
  // 格式化文件大小
  private formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 B'
    
    const units = ['B', 'KB', 'MB', 'GB']
    const k = 1024
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    const size = bytes / Math.pow(k, i)
    
    // 保留两位小数
    return size.toFixed(2) + ' ' + units[i]
  }
  
  build() {
    Column() {
      // 页面标题区域
      Row() {
        SymbolGlyph($r('sys.symbol.folder_fill'))
          .fontSize(24)
          .fontColor([this.themeColors.primary])
          .margin({ right: 12 })
        
        Text('存储图片')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
        
        Blank()
        
        // 图片数量标签
        if (!this.isLoading && this.imageList.length > 0) {
          Text(`${this.imageList.length} 张`)
            .fontSize(14)
            .fontColor(this.themeColors.textSecondary)
            .backgroundColor(this.themeColors.cardBackground)
            .padding({ left: 8, right: 8, top: 4, bottom: 4 })
            .borderRadius(12)
        }
      }
      .width('95%')
      .margin({ top: 20, bottom: 16 })
      .justifyContent(FlexAlign.Start)
      
      // 内容区域
      if (this.isLoading) {
        // 加载中状态
        Column() {
          LoadingProgress()
            .width(48)
            .height(48)
            .color(this.themeColors.primary)
          
          Text('加载中...')
            .fontSize(16)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 16 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else if (this.imageList.length === 0) {
        // 空状态
        Column() {
          SymbolGlyph($r('sys.symbol.folder'))
            .fontSize(64)
            .fontColor([this.themeColors.textSecondary])
          
          Text('暂无图片')
            .fontSize(18)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 16 })
          
          Text('记录图片目录中没有找到图片文件')
            .fontSize(14)
            .fontColor(this.themeColors.textTertiary)
            .margin({ top: 8 })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
      } else {
        // 图片网格
        Scroll() {
          Grid() {
            ForEach(this.imageList, (item: ImageInfo) => {
              GridItem() {
                this.ImageCard(item)
              }
            }, (item: ImageInfo) => item.path)
          }
          .columnsTemplate('1fr 1fr 1fr')
          .rowsGap(12)
          .columnsGap(12)
          .width('95%')
          .padding({ bottom: 20 })
        }
        .width('100%')
        .layoutWeight(1)
        .scrollBar(BarState.Auto)
        .edgeEffect(EdgeEffect.Spring)
        .align(Alignment.Top)
      }
      
      // 底部存储空间统计
      if (!this.isLoading && this.freeStorageSize > 0) {
        Row() {
          Text(`已使用 ${this.formatFileSize(this.totalImageSize)} / 可用 ${this.formatFileSize(this.freeStorageSize)}`)
            .fontSize(13)
            .fontColor(this.themeColors.textSecondary)
        }
        .width('100%')
        .justifyContent(FlexAlign.Center)
        .padding({ top: 12, bottom: 16 })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }
  
  // 图片卡片组件
  @Builder
  ImageCard(item: ImageInfo) {
    Column() {
      // 图片显示区域（正方形）
      Stack() {
        Image(item.uri)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .borderRadius({
            topLeft: 8,
            topRight: 8,
            bottomLeft: 0,
            bottomRight: 0
          })
          .onError(() => {
            console.error('[StorageImagePage] 图片加载失败: ' + item.name)
          })
      }
      .width('100%')
      .aspectRatio(1)
      .backgroundColor(this.themeColors.cardBackground)
      .align(Alignment.TopStart)
      
      // 图片信息区域
      Column() {
        // 文件名（单行显示，超出省略）
        Text(item.name)
          .fontSize(12)
          .fontColor(this.themeColors.textPrimary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .width('100%')
        
        // 文件大小
        Text(item.size)
          .fontSize(11)
          .fontColor(this.themeColors.textSecondary)
          .width('100%')
      }
      .width('100%')
      .padding({ left: 8, right: 8, top: 8, bottom: 8 })
      .alignItems(HorizontalAlign.Start)
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(8)
    .shadow({
      radius: 8,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 2
    })
  }
}
