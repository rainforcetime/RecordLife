// 全局刷新管理器：common/RefreshManager.ets
import { Logger } from '../utils/Logger'

type RefreshCallback = () => void

export class RefreshManager {
  private static instance: RefreshManager | null = null
  private callbacks: Map<string, RefreshCallback> = new Map()
  
  private constructor() {}
  
  static getInstance(): RefreshManager {
    if (!RefreshManager.instance) {
      RefreshManager.instance = new RefreshManager()
    }
    return RefreshManager.instance
  }
  
  // 注册刷新回调
  register(key: string, callback: RefreshCallback): void {
    this.callbacks.set(key, callback)
    Logger.info('[RefreshManager] 注册回调: ' + key)
  }
  
  // 注销刷新回调
  unregister(key: string): void {
    this.callbacks.delete(key)
    Logger.info('[RefreshManager] 注销回调: ' + key)
  }
  
  // 触发刷新
  refresh(): void {
    Logger.info('[RefreshManager] 触发刷新，回调数量: ' + this.callbacks.size)
    this.callbacks.forEach((callback, key) => {
      try {
        callback()
        Logger.info('[RefreshManager] 执行回调: ' + key)
      } catch (error) {
        Logger.error('[RefreshManager] 回调执行失败: ' + key + ', 错误: ' + JSON.stringify(error))
      }
    })
  }
}
