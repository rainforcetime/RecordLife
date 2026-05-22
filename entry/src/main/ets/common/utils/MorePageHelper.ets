// MorePage 辅助工具类：提供文件操作相关功能
import { fileIo } from '@kit.CoreFileKit'
import { fileUri } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'

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
      console.error('[MorePageHelper] 删除目录失败: ' + JSON.stringify(error))
    }
  }
  
  /**
   * 将 URI 转换为沙箱路径（用于文件操作）
   * @param uri 文件URI
   * @returns 沙箱路径
   */
  static uriToSandboxPath(uri: string): string {
    if (uri.startsWith('file://')) {
      // URI 格式: file://<bundleName>/data/storage/... 或 file:///data/storage/...
      let path = uri.substring(7)  // 移除 'file://'
      
      // 找到第一个 '/' 的位置，从那里开始截取路径
      const slashIndex = path.indexOf('/')
      if (slashIndex !== -1) {
        path = path.substring(slashIndex)
      }
      
      return path
    }
    return uri  // 已经是沙箱路径格式
  }
  
  /**
   * 读取文件内容为字符串
   * @param filePath 文件路径
   * @returns 文件内容字符串
   */
  static readFileContent(filePath: string): string {
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(file.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(file.fd, buffer)
      fileIo.closeSync(file)
      
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
      return decoder.decodeToString(new Uint8Array(buffer))
    } catch (error) {
      console.error('[MorePageHelper] 读取文件失败: ' + JSON.stringify(error))
      throw new Error('读取文件失败: ' + JSON.stringify(error))
    }
  }
  
  /**
   * 写入字符串内容到文件
   * @param filePath 文件路径
   * @param content 内容字符串
   */
  static writeFileContent(filePath: string, content: string): void {
    try {
      const file = fileIo.openSync(filePath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(file.fd, content)
      fileIo.closeSync(file)
    } catch (error) {
      console.error('[MorePageHelper] 写入文件失败: ' + JSON.stringify(error))
      throw new Error('写入文件失败: ' + JSON.stringify(error))
    }
  }
  
  /**
   * 复制文件
   * @param srcPath 源文件路径
   * @param destPath 目标文件路径
   */
  static copyFile(srcPath: string, destPath: string): void {
    try {
      fileIo.copyFileSync(srcPath, destPath)
    } catch (error) {
      console.error('[MorePageHelper] 复制文件失败: ' + JSON.stringify(error))
      throw new Error('复制文件失败: ' + JSON.stringify(error))
    }
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
  
  /**
   * 创建目录（如果不存在）
   * @param dirPath 目录路径
   */
  static ensureDirectory(dirPath: string): void {
    try {
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath)
      }
    } catch (error) {
      console.error('[MorePageHelper] 创建目录失败: ' + JSON.stringify(error))
      throw new Error('创建目录失败: ' + JSON.stringify(error))
    }
  }
}
