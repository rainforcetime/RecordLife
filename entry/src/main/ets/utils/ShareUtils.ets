// 分享工具类：utils/ShareUtils.ets
// 提供组件截图和系统分享功能
import { image } from '@kit.ImageKit'
import { uniformTypeDescriptor as utd } from '@kit.ArkData'
import { systemShare } from '@kit.ShareKit'
import { common } from '@kit.AbilityKit'
import { fileUri } from '@kit.CoreFileKit'
import fs from '@ohos.file.fs'
import { BusinessError } from '@kit.BasicServicesKit'

export class ShareUtils {
  /**
   * 组件截图并分享
   * @param uiContext UI上下文
   * @param componentId 组件ID
   * @param context 应用上下文
   * @param title 分享标题（可选）
   * @param description 分享描述（可选）
   */
  static async shareComponent(
    uiContext: UIContext,
    componentId: string,
    context: common.UIAbilityContext,
    title?: string,
    description?: string
  ): Promise<boolean> {
    try {
      console.info('[ShareUtils] 开始截图分享，组件ID: ' + componentId)
      
      // 1. 获取组件截图
      const pixelMap = await uiContext.getComponentSnapshot().get(componentId, {
        scale: 1,
        waitUntilRenderFinished: true
      })
      
      if (!pixelMap) {
        console.error('[ShareUtils] 截图失败：PixelMap为空')
        return false
      }
      
      console.info('[ShareUtils] 截图成功')
      
      // 2. 将PixelMap转换为ArrayBuffer
      const imageBuffer = await ShareUtils.pixelMapToBuffer(pixelMap)
      
      // 3. 保存到沙箱目录
      const imagePath = await ShareUtils.saveImageToSandbox(imageBuffer, context)
      
      console.info('[ShareUtils] 图片已保存到: ' + imagePath)
      
      // 4. 执行系统分享
      await ShareUtils.doShare(imagePath, context, title, description)
      
      // 5. 释放PixelMap资源
      pixelMap.release()
      
      return true
    } catch (error) {
      console.error('[ShareUtils] 分享失败: ' + JSON.stringify(error))
      return false
    }
  }
  
  /**
   * 将PixelMap转换为ArrayBuffer
   */
  private static async pixelMapToBuffer(pixelMap: image.PixelMap): Promise<ArrayBuffer> {
    const packOpts: image.PackingOption = {
      format: 'image/jpeg',
      quality: 95
    }
    
    const imagePackerApi = image.createImagePacker()
    try {
      const buffer = await imagePackerApi.packToData(pixelMap, packOpts)
      return buffer
    } catch (err) {
      const error = err as BusinessError
      console.error('[ShareUtils] 图片打包失败: ' + JSON.stringify(error))
      throw error as Error
    }
  }
  
  /**
   * 将图片保存到沙箱目录
   */
  private static async saveImageToSandbox(
    imageBuffer: ArrayBuffer,
    context: common.UIAbilityContext
  ): Promise<string> {
    // 生成文件名（使用时间戳）
    const timestamp = Date.now()
    const fileName = `share_${timestamp}.jpg`
    const imagePath = context.cacheDir + '/' + fileName
    
    // 写入文件
    try {
      const file = fs.openSync(imagePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE)
      fs.writeSync(file.fd, imageBuffer)
      fs.closeSync(file)
    } catch (err) {
      console.error('[ShareUtils] 保存图片到沙箱失败: ' + JSON.stringify(err))
      throw err as Error
    }
    
    return imagePath
  }
  
  /**
   * 执行系统分享
   */
  private static async doShare(
    imagePath: string,
    context: common.UIAbilityContext,
    title?: string,
    description?: string
  ): Promise<void> {
    return new Promise((resolve, reject) => {
      try {
        // 获取统一数据类型
        const utdTypeId = utd.getUniformDataTypeByFilenameExtension('.jpg', utd.UniformDataType.IMAGE)
        
        // 构建分享数据
        const shareData: systemShare.SharedData = new systemShare.SharedData({
          utd: utdTypeId,
          uri: fileUri.getUriFromPath(imagePath),
          title: title || '记录分享',
          description: description || '来自 RecordLife 的记录分享'
        })
        
        // 创建分享控制器
        const controller: systemShare.ShareController = new systemShare.ShareController(shareData)
        
        // 显示分享面板
        controller.show(context, {
          selectionMode: systemShare.SelectionMode.SINGLE,
          previewMode: systemShare.SharePreviewMode.DETAIL
        })
          .then(() => {
            console.info('[ShareUtils] 分享面板显示成功')
            resolve()
          })
          .catch((error: BusinessError) => {
            console.error('[ShareUtils] 分享面板显示失败: ' + JSON.stringify(error))
            reject(error)
          })
      } catch (error) {
        console.error('[ShareUtils] 分享执行失败: ' + JSON.stringify(error))
        reject(error)
      }
    })
  }
  
  /**
   * 清理过期的分享图片（可选）
   * @param context 应用上下文
   * @param maxAge 最大保留时间（毫秒），默认24小时
   */
  static async cleanupOldShareImages(
    context: common.UIAbilityContext,
    maxAge: number = 24 * 60 * 60 * 1000
  ): Promise<void> {
    try {
      const now = Date.now()
      const files = fs.listFileSync(context.cacheDir)
      
      for (const fileName of files) {
        // 只清理分享图片
        if (fileName.startsWith('share_') && fileName.endsWith('.jpg')) {
          const filePath = context.cacheDir + '/' + fileName
          const stat = fs.statSync(filePath)
          
          // 如果文件超过最大保留时间，则删除
          if (now - stat.mtime * 1000 > maxAge) {
            fs.unlinkSync(filePath)
            console.info('[ShareUtils] 已清理过期分享图片: ' + fileName)
          }
        }
      }
    } catch (error) {
      console.error('[ShareUtils] 清理过期图片失败: ' + JSON.stringify(error))
    }
  }
}
