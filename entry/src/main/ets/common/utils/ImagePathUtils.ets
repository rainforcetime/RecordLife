/**
 * 图片路径工具类
 * 统一 URI / 沙箱路径 / 文件名的转换逻辑
 * 说明：原 NowViewModel / BackupManager / MorePageHelper 三处重复实现收敛于此（P3 重构）
 */

export class ImagePathUtils {
  /**
   * 将 URI 转换为沙箱路径（用于文件操作）
   * @param uri 文件 URI（file:// 开头）或已是沙箱路径
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
   * 将沙箱路径转换为 URI 格式
   * @param path 沙箱路径或已是 URI
   * @returns file:// 开头的 URI
   */
  static sandboxPathToUri(path: string): string {
    if (path.startsWith('file://')) {
      return path  // 已经是 URI 格式
    }
    return `file://${path}`
  }

  /**
   * 从路径中提取文件名
   * @param path 完整路径（URI 或沙箱路径）
   * @returns 文件名（不含目录部分）
   */
  static getFileName(path: string): string {
    const sandboxPath = ImagePathUtils.uriToSandboxPath(path)
    return sandboxPath.split('/').pop() || ''
  }
}
