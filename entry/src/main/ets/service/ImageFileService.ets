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

// 压缩档位参数
interface CompressParams {
  quality: number
  maxEdge: number
}

export class ImageFileService {
  /**
   * 保存图片到沙箱目录（返回 URI 格式）
   * 图片存储优化 M1：优先压缩保存（保留原分辨率，JPEG quality 0.92，尽量不损画质）；
   * 压缩失败（非解码格式等）兜底原样复制
   * @param context 应用上下文
   * @param sourceUri 源图片 URI
   * @returns file:// URI；失败返回 null
   */
  static async saveRecordImage(context: common.UIAbilityContext, sourceUri: string, timestamp?: number,
    compressMode?: string): Promise<string | null> {
    let sourceFile: fileIo.File | null = null
    try {
      // 打开源图片
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)

      // 生成文件名（timestamp 由调用方传入，与 saveOriginalPending 保持一致，供「上传全部图片」按名匹配）
      const ts = timestamp ? timestamp : Date.now()
      const fileName = `record_${ts}.jpg`
      const sandboxPath = `${context.filesDir}/records/${fileName}`

      // 确保目录存在
      const dirPath = `${context.filesDir}/records`
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath)
      }

      // 优先按档位压缩保存；失败兜底原样复制
      const mode = compressMode ? compressMode : ImageFileService.COMPRESS_BALANCED
      const compressed = await ImageFileService.compressToFile(sourceFile.fd, sandboxPath, mode)
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

  // 压缩画质档位（图片存储优化：可选压缩比例）
  static readonly COMPRESS_HIGH = 'high'        // 高：原尺寸 + q92（视觉近似无损）
  static readonly COMPRESS_BALANCED = 'balanced' // 均衡：最长边 2560 + q85（默认）
  static readonly COMPRESS_COMPACT = 'compact'   // 省空间：最长边 1280 + q72

  // 压缩档位参数映射
  private static getCompressParams(mode: string): CompressParams {
    if (mode === ImageFileService.COMPRESS_HIGH) {
      return { quality: 92, maxEdge: 0 }
    }
    if (mode === ImageFileService.COMPRESS_COMPACT) {
      return { quality: 72, maxEdge: 1280 }
    }
    return { quality: 85, maxEdge: 2560 }  // balanced 默认
  }

  /**
   * 压缩图片到目标路径（按档位缩放最长边 + 调整质量）
   * @param sourceFd 源图片文件描述符
   * @param destPath 目标沙箱路径
   * @param mode 压缩档位（high/balanced/compact）
   * @returns 是否成功（失败时调用方兜底原样复制）
   */
  private static async compressToFile(sourceFd: number, destPath: string, mode: string): Promise<boolean> {
    let imageSource: image.ImageSource | null = null
    let pixelMap: image.PixelMap | null = null
    let packer: image.ImagePacker | null = null
    try {
      imageSource = image.createImageSource(sourceFd)
      packer = image.createImagePacker()
      const params = ImageFileService.getCompressParams(mode)
      const option: image.PackingOption = {
        format: 'image/jpeg',
        quality: params.quality
      }
      // 等比缩放：按最长边上限缩放（PixelMap.scale，desiredSize 当前 SDK 不支持）
      let scaled: boolean = false
      if (params.maxEdge > 0) {
        const info = await imageSource.getImageInfo()
        const srcWidth = info.size.width
        const srcHeight = info.size.height
        const maxSide = srcWidth > srcHeight ? srcWidth : srcHeight
        if (maxSide > params.maxEdge) {
          const ratio = params.maxEdge / maxSide
          pixelMap = await imageSource.createPixelMap()
          await pixelMap.scale(ratio, ratio)
          scaled = true
        }
      }
      // packToData 重载不兼容联合类型，需分支调用（ImageSource / PixelMap）
      let data: ArrayBuffer
      if (scaled && pixelMap) {
        data = await packer.packToData(pixelMap, option)
      } else {
        data = await packer.packToData(imageSource, option)
      }
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
      if (pixelMap) {
        try {
          pixelMap.release()
        } catch (e) {
          Logger.error('[ImageFileService] 释放 pixelMap 失败: ' + JSON.stringify(e))
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
   * 复制原图到待上传缓存目录（图片存储优化 M3：本地压缩 + 云端原图）
   * @param context 应用上下文
   * @param sourceUri 源图片 URI
   * @returns pending 文件路径；失败返回 null
   */
  static async saveOriginalPending(context: common.UIAbilityContext, sourceUri: string, timestamp?: number): Promise<string | null> {
    let sourceFile: fileIo.File | null = null
    try {
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)
      // timestamp 由调用方传入，与压缩图 saveRecordImage 保持同一值（文件名对应，供「上传全部图片」匹配）
      const ts = timestamp ? timestamp : Date.now()
      const pendingDir = `${context.cacheDir}/pending`
      if (!fileIo.accessSync(pendingDir)) {
        fileIo.mkdirSync(pendingDir)
      }
      const pendingPath = `${pendingDir}/record_${ts}_orig.jpg`
      fileIo.copyFileSync(sourceFile.fd, pendingPath)
      return pendingPath
    } catch (error) {
      Logger.error('[ImageFileService] 保存原图待上传失败: ' + JSON.stringify(error))
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
