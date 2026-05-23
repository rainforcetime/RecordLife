/**
 * 图片 Base64 工具类
 * 用于图片和 Base64 字符串之间的转换
 */
import { common } from '@kit.AbilityKit'
import { fileIo } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { util } from '@kit.ArkTS'

export class ImageBase64Utils {
  /**
   * 将图片文件转换为 Base64 字符串
   * @param imagePath 图片文件路径（沙箱路径）
   * @returns Base64 字符串，失败返回空字符串
   */
  static imageToBase64(imagePath: string): string {
    try {
      // 检查文件是否存在
      if (!fileIo.accessSync(imagePath)) {
        console.error('[ImageBase64Utils] 图片文件不存在: ' + imagePath)
        return ''
      }

      // 读取文件内容
      const file = fileIo.openSync(imagePath, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(imagePath)
      const fileSize = stat.size
      const buffer = new ArrayBuffer(fileSize)
      fileIo.readSync(file.fd, buffer)
      fileIo.closeSync(file)

      // 转换为 Base64
      const base64Helper = new util.Base64Helper()
      const uint8Array = new Uint8Array(buffer)
      const base64Str = base64Helper.encodeToStringSync(uint8Array)

      console.info('[ImageBase64Utils] 图片转Base64成功，大小: ' + fileSize + ' bytes')
      return base64Str
    } catch (error) {
      console.error('[ImageBase64Utils] 图片转Base64失败: ' + JSON.stringify(error))
      return ''
    }
  }

  /**
   * 将 Base64 字符串转换为图片文件
   * @param base64Str Base64 字符串
   * @param outputPath 输出图片文件路径（沙箱路径）
   * @returns 是否成功
   */
  static base64ToImage(base64Str: string, outputPath: string): boolean {
    try {
      if (!base64Str || base64Str.length === 0) {
        console.error('[ImageBase64Utils] Base64字符串为空')
        return false
      }

      // 解码 Base64
      const base64Helper = new util.Base64Helper()
      const uint8Array = base64Helper.decodeSync(base64Str)
      const buffer = uint8Array.buffer

      // 写入文件
      const file = fileIo.openSync(outputPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(file.fd, buffer)
      fileIo.closeSync(file)

      console.info('[ImageBase64Utils] Base64转图片成功，大小: ' + buffer.byteLength + ' bytes')
      return true
    } catch (error) {
      console.error('[ImageBase64Utils] Base64转图片失败: ' + JSON.stringify(error))
      return false
    }
  }

  /**
   * 将 URI �换为沙箱路径
   * @param uri 图片 URI
   * @param context 应用上下文
   * @returns 沙箱路径
   */
  static uriToSandboxPath(uri: string, context: common.UIAbilityContext): string {
    // 如果已经是沙箱路径，直接返回
    if (uri.startsWith('/data/')) {
      return uri
    }

    // 将 file://internal:// 格式的 URI 转换为沙箱路径
    // 例如: file://internal://cache/avatar.jpg -> /data/storage/el2/base/cache/avatar.jpg
    if (uri.startsWith('file://internal://')) {
      const relativePath = uri.replace('file://internal://', '')
      return `${context.filesDir}/../${relativePath}`
    }

    // 其他情况，假设是相对路径
    return uri
  }

  /**
   * 获取头像的保存路径
   * @param context 应用上下文
   * @returns 头像保存路径
   */
  static getAvatarSavePath(context: common.UIAbilityContext): string {
    return `${context.filesDir}/avatar.jpg`
  }
}
