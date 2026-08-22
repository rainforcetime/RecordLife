// MorePage 辅助工具类：提供文件操作相关功能
import { fileIo } from '@kit.CoreFileKit'
import { ImagePathUtils } from './ImagePathUtils'
import { Logger } from './Logger'

export class MorePageHelper {
  /**
   * 删除目录及其所有内容
   * @param dirPath 目录路径
   */
  static deleteDirectory(dirPath: string): void {
    try {
      if (!fileIo.accessSync(dirPath)) {
        return
      }
      
      const files = fileIo.listFileSync(dirPath)
      for (const fileName of files) {
        const filePath = `${dirPath}/${fileName}`
        const stat = fileIo.statSync(filePath)
        
        if (stat.isDirectory()) {
          // 递归删除子目录
          MorePageHelper.deleteDirectory(filePath)
        } else {
          // 删除文件
          fileIo.unlinkSync(filePath)
        }
      }
      
      // 删除空目录
      fileIo.rmdirSync(dirPath)
    } catch (error) {
      Logger.error('[MorePageHelper] 删除目录失败: ' + JSON.stringify(error))
    }
  }
  
  /**
   * 将 URI 转换为沙箱路径（用于文件操作）
   * @param uri 文件URI
   * @returns 沙箱路径
   */
  static uriToSandboxPath(uri: string): string {
    return ImagePathUtils.uriToSandboxPath(uri)  // 统一实现收敛至 ImagePathUtils（P3）
  }
  
  /**
   * 检查文件是否存在
   * @param filePath 文件路径
   * @returns 是否存在
   */
  static fileExists(filePath: string): boolean {
    try {
      return fileIo.accessSync(filePath)
    } catch (error) {
      return false
    }
  }
}
