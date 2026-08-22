/**
 * 心情服务（service 层，更新计划二期：自定义心情）
 * 自定义心情 CRUD：读写 ConfigManager 的 config.settings.customMoods
 * 预置心情（MoodUtils.PRESET_MOODS）不可增删，仅自定义可管理
 */
import { common } from '@kit.AbilityKit'
import { ConfigManager } from '../config/ConfigManager'
import { Mood } from '../model/RecordModel'

export class MoodService {
  private static instance: MoodService | null = null
  private configManager: ConfigManager | null = null

  private constructor() {}

  // 获取单例实例（支持显式注入 context，A5；透传至 ConfigManager）
  static async getInstance(context?: common.UIAbilityContext): Promise<MoodService> {
    if (!MoodService.instance) {
      MoodService.instance = new MoodService()
      MoodService.instance.configManager = await ConfigManager.getInstance(context)
    } else if (!MoodService.instance.configManager) {
      MoodService.instance.configManager = await ConfigManager.getInstance(context)
    }
    return MoodService.instance
  }

  // 获取自定义心情列表
  getCustomMoods(): Mood[] {
    if (!this.configManager) {
      return []
    }
    return this.configManager.getConfig().settings.customMoods || []
  }

  // 添加自定义心情（按 emoji；id 自动生成）
  async addCustomMood(emoji: string): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const customMoods = this.configManager.getConfig().settings.customMoods || []
    const mood: Mood = {
      id: 'mood_' + Date.now().toString(36) + Math.random().toString(36).substring(2),
      emoji: emoji
    }
    const newMoods = [...customMoods, mood]
    this.configManager.getConfig().settings.customMoods = newMoods
    return await this.configManager.saveConfig()
  }

  // 删除自定义心情
  async deleteCustomMood(id: string): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const moods = (this.configManager.getConfig().settings.customMoods || []).filter(m => m.id !== id)
    this.configManager.getConfig().settings.customMoods = moods
    return await this.configManager.saveConfig()
  }

  // 保存整个自定义心情列表
  async saveCustomMoods(moods: Mood[]): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    this.configManager.getConfig().settings.customMoods = moods
    return await this.configManager.saveConfig()
  }
}
