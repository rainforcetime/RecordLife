/**
 * 标签服务（service 层）
 * 自定义标签 CRUD：读写 ConfigManager 的 config.settings.customTags
 * 拆分自 ConfigManager（P3 重构，解决 A2 职责过重）；ConfigManager 不再承担标签管理
 */
import { common } from '@kit.AbilityKit'
import { ConfigManager } from '../config/ConfigManager'
import { Tag } from '../common/types'

export class TagService {
  private static instance: TagService | null = null
  private configManager: ConfigManager | null = null

  private constructor() {}

  // 获取单例实例（支持显式注入 context，A5；透传至 ConfigManager）
  static async getInstance(context?: common.UIAbilityContext): Promise<TagService> {
    if (!TagService.instance) {
      TagService.instance = new TagService()
      TagService.instance.configManager = await ConfigManager.getInstance(context)
    } else if (!TagService.instance.configManager) {
      TagService.instance.configManager = await ConfigManager.getInstance(context)
    }
    return TagService.instance
  }

  // 获取所有自定义标签
  getCustomTags(): Tag[] {
    if (!this.configManager) {
      return []
    }
    return this.configManager.getConfig().settings.customTags || []
  }

  // 添加自定义标签
  async addCustomTag(tag: Tag): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const customTags = this.configManager.getConfig().settings.customTags || []
    const newTags = [...customTags, tag]
    this.configManager.getConfig().settings.customTags = newTags
    return await this.configManager.saveConfig()
  }

  // 更新自定义标签
  async updateCustomTag(tag: Tag): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const tags = this.configManager.getConfig().settings.customTags || []
    const index = tags.findIndex(t => t.id === tag.id)
    if (index === -1) {
      return false
    }
    tags[index] = tag
    return await this.configManager.saveConfig()
  }

  // 删除自定义标签
  async deleteCustomTag(id: string): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const tags = (this.configManager.getConfig().settings.customTags || []).filter(t => t.id !== id)
    this.configManager.getConfig().settings.customTags = tags
    return await this.configManager.saveConfig()
  }

  // 保存整个自定义标签列表
  async saveCustomTags(tags: Tag[]): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    this.configManager.getConfig().settings.customTags = tags
    return await this.configManager.saveConfig()
  }
}
