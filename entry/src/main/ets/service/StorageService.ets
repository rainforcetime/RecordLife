/**
 * 存储统计服务（service 层）
 * 应用存储空间统计与使用天数计算，拆自 AccountViewModel（P4 重构，A3 IO/统计职责下沉）
 */
import { storageStatistics } from '@kit.CoreFileKit'
import { common } from '@kit.AbilityKit'
import { TimeUtils } from '../common/utils/TimeUtils'
import { Logger } from '../common/utils/Logger'

export class StorageService {
  /**
   * 获取应用存储空间大小（appSize + cacheSize + dataSize，已格式化）
   * @returns 格式化后的字符串（如 "123.4MB"）；失败返回「计算失败」
   */
  static async getAppStorageSize(context: common.UIAbilityContext): Promise<string> {
    try {
      const bundleStats = await storageStatistics.getCurrentBundleStats()
      // 计算总大小：appSize + cacheSize + dataSize
      const totalSize = bundleStats.appSize + bundleStats.cacheSize + bundleStats.dataSize
      return StorageService.formatStorageSize(totalSize)
    } catch (error) {
      Logger.error('[StorageService] 获取应用存储空间失败: ' + JSON.stringify(error))
      return context.resourceManager.getStringByNameSync('calc_failed')
    }
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
}
