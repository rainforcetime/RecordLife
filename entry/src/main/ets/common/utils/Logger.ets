// 统一日志工具：common/utils/Logger.ets
// B3 重构：统一 hilog + 日志开关，替代散落的 console.* 调用
import { hilog } from '@kit.PerformanceAnalysisKit'

export class Logger {
  private static readonly DOMAIN = 0x0001
  private static readonly TAG = 'RecordLife'

  // 日志开关：false 时关闭 info/warn；error 始终输出（便于线上问题定位）
  private static debugEnabled: boolean = true

  // 设置日志开关（可接入应用设置）
  static setDebugEnabled(enabled: boolean): void {
    Logger.debugEnabled = enabled
  }

  // 获取日志开关状态
  static isDebugEnabled(): boolean {
    return Logger.debugEnabled
  }

  static info(message: string): void {
    if (Logger.debugEnabled) {
      hilog.info(Logger.DOMAIN, Logger.TAG, '%{public}s', message)
    }
  }

  static warn(message: string): void {
    if (Logger.debugEnabled) {
      hilog.warn(Logger.DOMAIN, Logger.TAG, '%{public}s', message)
    }
  }

  static error(message: string): void {
    hilog.error(Logger.DOMAIN, Logger.TAG, '%{public}s', message)
  }
}
