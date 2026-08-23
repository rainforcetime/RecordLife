/**
 * 图片文件服务（service 层）
 * 封装记录图片与头像的沙箱 IO 操作，供 ViewModel / 组件复用
 * 职责来源：NowViewModel.saveImageToSandbox / getImageUri / 删除逻辑、AccountViewModel.copyImageToSandbox（P3 重构下沉）
 */
import { common } from '@kit.AbilityKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { image } from '@kit.ImageKit'
import { ImagePathUtils } from '../common/utils/ImagePathUtils'
import { Logger } from '../common/utils/Logger'

export class ImageFileService {
  /**
   * 保存图片到沙箱目录（返回 URI 格式）
   * 图片存储优化 M1：优先压缩保存（保留原分辨率，JPEG quality 0.92，尽量不损画质）；
   * 压缩失败（非解码格式等）兜底原样复制
   * @param context 应用上下文
   * @param sourceUri 源图片 URI
   * @returns file:// URI；失败返回 null
   */
  static async saveRecordImage(context: common.UIAbilityContext, sourceUri: string): Promise<string | null> {
    let sourceFile: fileIo.File | null = null
    try {
      // 打开源图片
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)

      // 生成文件名
      const timestamp = Date.now()
      const fileName = `record_${timestamp}.jpg`
      const sandboxPath = `${context.filesDir}/records/${fileName}`

      // 确保目录存在
      const dirPath = `${context.filesDir}/records`
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath)
      }

      // 优先压缩保存；失败兜底原样复制
      const compressed = await ImageFileService.compressToFile(sourceFile.fd, sandboxPath)
      if (!compressed) {
        fileIo.copyFileSync(sourceFile.fd, sandboxPath)
      }

      // 返回 URI 格式（统一路径格式）
      return fileUri.getUriFromPath(sandboxPath)
    } catch (error) {
      Logger.error('[ImageFileService] 保存图片失败: ' + JSON.stringify(error))
      return null
    } finally {
      if (sourceFile) {
        try {
          fileIo.closeSync(sourceFile)
        } catch (error) {
          Logger.error('[ImageFileService] 关闭文件失败: ' + JSON.stringify(error))
        }
      }
    }
  }

  /**
   * 压缩图片到目标路径（保留原分辨率，JPEG quality 0.92）
   * @param sourceFd 源图片文件描述符
   * @param destPath 目标沙箱路径
   * @returns 是否成功（失败时调用方兜底原样复制）
   */
  private static async compressToFile(sourceFd: number, destPath: string): Promise<boolean> {
    let imageSource: image.ImageSource | null = null
    let packer: image.ImagePacker | null = null
    try {
      imageSource = image.createImageSource(sourceFd)
      packer = image.createImagePacker()
      const option: image.PackingOption = {
        format: 'image/jpeg',
        quality: 92
      }
      const data: ArrayBuffer = await packer.packToData(imageSource, option)
      const destFile = fileIo.openSync(destPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
      fileIo.writeSync(destFile.fd, data)
      fileIo.closeSync(destFile)
      return true
    } catch (error) {
      Logger.error('[ImageFileService] 压缩图片失败: ' + JSON.stringify(error))
      return false
    } finally {
      if (packer) {
        try {
          packer.release()
        } catch (e) {
          Logger.error('[ImageFileService] 释放 packer 失败: ' + JSON.stringify(e))
        }
      }
      if (imageSource) {
        try {
          imageSource.release()
        } catch (e) {
          Logger.error('[ImageFileService] 释放 imageSource 失败: ' + JSON.stringify(e))
        }
      }
    }
  }

  /**
   * 获取图片 URI（用于显示）
   * 注：新记录已统一为 URI 格式，此方法保留用于兼容旧数据
   * @param path 图片路径（URI 或旧沙箱路径）
   */
  static getImageUri(path: string): string {
    if (path.startsWith('file://')) {
      return path  // 已经是 URI 格式
    }
    try {
      return fileUri.getUriFromPath(path)  // 兼容旧的沙箱路径格式
    } catch (error) {
      Logger.error('[ImageFileService] 获取图片URI失败: ' + JSON.stringify(error))
      return path
    }
  }

  /**
   * 删除图片文件（逐个尝试，失败不影响其余）
   * @param context 应用上下文
   * @param paths 图片路径列表（URI 或沙箱路径）
   */
  static deleteImageFiles(context: common.UIAbilityContext, paths: string[]): void {
    for (const imagePath of paths) {
      try {
        const sandboxPath = ImagePathUtils.uriToSandboxPath(imagePath)
        if (fileIo.accessSync(sandboxPath)) {
          fileIo.unlinkSync(sandboxPath)
        }
      } catch (error) {
        Logger.error('[ImageFileService] 删除图片文件失败: ' + JSON.stringify(error))
      }
    }
  }

  /**
   * 复制图片到沙箱目录作为头像（返回 URI 格式）
   * 会先清理旧的 avatar 前缀缓存文件
   * @param context 应用上下文
   * @param sourceUri 源图片 URI
   * @returns file:// URI；失败返回 null
   */
  static async copyAvatar(context: common.UIAbilityContext, sourceUri: string): Promise<string | null> {
    // 删除旧的头像缓存文件
    ImageFileService.deleteOldAvatarCache(context)

    let sourceFile: fileIo.File | null = null
    try {
      // 打开源图片文件
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)

      // 生成新的文件名（使用时间戳避免重复）
      const timestamp = Date.now()
      const fileName = `avatar_${timestamp}.jpg`
      const sandboxPath = `${context.filesDir}/${fileName}`

      // 使用同步方法复制文件到沙箱目录
      fileIo.copyFileSync(sourceFile.fd, sandboxPath)

      // 将沙箱路径转换为 URI（Image组件需要URI格式）
      return fileUri.getUriFromPath(sandboxPath)
    } catch (error) {
      Logger.error('[ImageFileService] 复制头像失败: ' + JSON.stringify(error))
      return null
    } finally {
      // 关闭源文件
      if (sourceFile) {
        try {
          fileIo.closeSync(sourceFile)
        } catch (closeError) {
          Logger.error('[ImageFileService] 关闭文件失败: ' + JSON.stringify(closeError))
        }
      }
    }
  }

  /**
   * 删除 filesDir 下以 avatar 开头的旧头像缓存文件
   */
  private static deleteOldAvatarCache(context: common.UIAbilityContext): void {
    try {
      const filesDir = context.filesDir
      // 列出目录下的所有文件（返回的是文件名数组，不是完整路径）
      const fileNames = fileIo.listFileSync(filesDir)
      for (const fileName of fileNames) {
        // 删除以 avatar 开头的文件
        if (fileName.startsWith('avatar')) {
          const filePath = `${filesDir}/${fileName}`
          try {
            fileIo.unlinkSync(filePath)
          } catch (e) {
            Logger.error('[ImageFileService] 删除旧头像缓存失败: ' + filePath + ', 错误: ' + JSON.stringify(e))
          }
        }
      }
    } catch (error) {
      Logger.error('[ImageFileService] 列出头像目录失败: ' + JSON.stringify(error))
    }
  }
}
