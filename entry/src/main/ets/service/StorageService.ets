/**
 * 存储统计服务（service 层）
 * 应用存储空间统计与使用天数计算，拆自 AccountViewModel（P4 重构，A3 IO/统计职责下沉）
 */
import { fileIo } from '@kit.CoreFileKit'
import { ResourceUtils } from '../common/utils/ResourceUtils'
import { common } from '@kit.AbilityKit'
import { TimeUtils } from '../common/utils/TimeUtils'
import { Logger } from '../common/utils/Logger'
import { LifeRecord } from '../model/RecordModel'

export class StorageService {
  /**
   * 获取应用存储空间大小（应用沙箱实际占用：filesDir + cacheDir 递归统计）
   * @returns 格式化后的字符串（如 "123.4MB"）；失败返回「计算失败」
   */
  static async getAppStorageSize(context: common.UIAbilityContext): Promise<string> {
    try {
      // 计算总大小：应用沙箱实际文件占用（bundleStats 口径偏小且与页内不一致）
      let totalSize = 0
      const dirs: string[] = [context.filesDir, context.cacheDir]
      for (const dir of dirs) {
        if (dir) {
          totalSize += StorageService.getDirSizeSync(dir)
        }
      }
      return StorageService.formatStorageSize(totalSize)
    } catch (error) {
      Logger.error('[StorageService] 获取应用存储空间失败: ' + JSON.stringify(error))
      return ResourceUtils.getString(context.resourceManager, 'calc_failed')
    }
  }

  // 递归统计目录下所有文件大小（与存储空间页同口径，范围更全）
  private static getDirSizeSync(dir: string): number {
    let sum = 0
    try {
      const filenames = fileIo.listFileSync(dir)
      for (const name of filenames) {
        const fullPath = dir + '/' + name
        const stat = fileIo.statSync(fullPath)
        if (stat.isDirectory()) {
          sum += StorageService.getDirSizeSync(fullPath)
        } else {
          sum += stat.size
        }
      }
    } catch (error) {
      Logger.error('[StorageService] 统计目录失败: ' + dir + ', ' + JSON.stringify(error))
    }
    return sum
  }

  /**
   * 格式化存储大小（纯函数，可单测）
   * @param bytes 字节数
   * @returns B / KB / MB / GB 字符串
   */
  static formatStorageSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes}B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)}KB`
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)}MB`
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)}GB`
    }
  }

  /**
   * 计算使用天数（日期边界计算，符合用户直觉）
   * 例如：1月1日23:00创建，1月2日01:00查看，应显示1天
   * @param createdAt 创建时间 ISO 字符串
   * @returns 使用天数（≥0）
   */
  static calcUsageDays(createdAt: string): number {
    const startDate = TimeUtils.formatDate(new Date(createdAt));  // "YYYY-MM-DD" UTC+8
    const endDate = TimeUtils.formatDate(TimeUtils.now());        // "YYYY-MM-DD" UTC+8
    const startDateTime = TimeUtils.parseDate(startDate);
    const endDateTime = TimeUtils.parseDate(endDate);
    const daysDiff = Math.floor((endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60 * 60 * 24));
    return daysDiff >= 0 ? daysDiff : 0;
  }

  // ==================== 缓存清理（更新计划三期） ====================

  /**
   * 清理缓存：分享临时图片（cacheDir/share_*.jpg 全删）+ 孤儿记录图片（filesDir/records 下未被任何记录引用的 jpg/png）
   * + 原图缓存（cacheDir/original_*）与待上传原图（cacheDir/pending/，图片存储优化 M3）
   * @returns 删除的文件数
   */
  static async cleanupCache(context: common.Context, records: LifeRecord[]): Promise<number> {
    let deletedCount = 0
    deletedCount += await StorageService.clearShareCache(context)
    deletedCount += await StorageService.clearOrphanRecordImages(context, records)
    deletedCount += await StorageService.clearOriginalCache(context)
    return deletedCount
  }

  // 清理分享临时图片（cacheDir/share_*.jpg，分享产物可随时重建，全删）
  static async clearShareCache(context: common.Context): Promise<number> {
    try {
      let count = 0
      const files: string[] = fileIo.listFileSync(context.cacheDir)
      for (const fileName of files) {
        if (fileName.startsWith('share_') && fileName.endsWith('.jpg')) {
          fileIo.unlinkSync(context.cacheDir + '/' + fileName)
          count++
        }
      }
      if (count > 0) {
        Logger.info('[StorageService] 已清理分享缓存 ' + count + ' 个文件')
      }
      return count
    } catch (error) {
      Logger.error('[StorageService] 清理分享缓存失败: ' + JSON.stringify(error))
      return 0
    }
  }

  // 清理原图缓存（cacheDir/original_*.jpg）与待上传原图（cacheDir/pending/，图片存储优化 M3）
  static async clearOriginalCache(context: common.Context): Promise<number> {
    try {
      let count = 0
      const files: string[] = fileIo.listFileSync(context.cacheDir)
      for (const fileName of files) {
        if (fileName.startsWith('original_') && fileName.endsWith('.jpg')) {
          fileIo.unlinkSync(context.cacheDir + '/' + fileName)
          count++
        }
      }
      // 待上传原图目录
      const pendingDir = context.cacheDir + '/pending'
      if (fileIo.accessSync(pendingDir)) {
        const pendingFiles: string[] = fileIo.listFileSync(pendingDir)
        for (const fileName of pendingFiles) {
          fileIo.unlinkSync(pendingDir + '/' + fileName)
          count++
        }
      }
      if (count > 0) {
        Logger.info('[StorageService] 已清理原图缓存 ' + count + ' 个文件')
      }
      return count
    } catch (error) {
      Logger.error('[StorageService] 清理原图缓存失败: ' + JSON.stringify(error))
      return 0
    }
  }

  // 清理孤儿记录图片（filesDir/records 下未被任何记录引用的图片；按文件名匹配，兼容 URI/沙箱路径）
  static async clearOrphanRecordImages(context: common.Context, records: LifeRecord[]): Promise<number> {
    try {
      // 收集所有被引用的文件名
      const referencedNames = new Set<string>()
      for (const record of records) {
        if (record.imagePaths) {
          for (const path of record.imagePaths) {
            const name = path.split('/').pop()
            if (name && name.length > 0) {
              referencedNames.add(name)
            }
          }
        }
      }

      const dir = context.filesDir + '/records'
      if (!fileIo.accessSync(dir)) {
        return 0
      }
      let count = 0
      const files: string[] = fileIo.listFileSync(dir)
      for (const fileName of files) {
        if (!fileName.endsWith('.jpg') && !fileName.endsWith('.png')) {
          continue
        }
        if (!referencedNames.has(fileName)) {
          fileIo.unlinkSync(dir + '/' + fileName)
          count++
        }
      }
      if (count > 0) {
        Logger.info('[StorageService] 已清理孤儿记录图片 ' + count + ' 个文件')
      }
      return count
    } catch (error) {
      Logger.error('[StorageService] 清理孤儿记录图片失败: ' + JSON.stringify(error))
      return 0
    }
  }
}
