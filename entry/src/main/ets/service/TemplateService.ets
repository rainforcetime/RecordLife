/**
 * 记录模板服务（service 层，更新计划三期：记录模板）
 * 模板 CRUD：读写 ConfigManager 的 config.settings.recordTemplates
 */
import { common } from '@kit.AbilityKit'
import { ConfigManager } from '../config/ConfigManager'
import { RecordTemplate } from '../model/UserConfigModel'

export class TemplateService {
  private static instance: TemplateService | null = null
  private configManager: ConfigManager | null = null

  private constructor() {}

  // 获取单例实例（支持显式注入 context，A5；透传至 ConfigManager）
  static async getInstance(context?: common.UIAbilityContext): Promise<TemplateService> {
    if (!TemplateService.instance) {
      TemplateService.instance = new TemplateService()
      TemplateService.instance.configManager = await ConfigManager.getInstance(context)
    } else if (!TemplateService.instance.configManager) {
      TemplateService.instance.configManager = await ConfigManager.getInstance(context)
    }
    return TemplateService.instance
  }

  // 获取模板列表
  getTemplates(): RecordTemplate[] {
    if (!this.configManager) {
      return []
    }
    return this.configManager.getConfig().settings.recordTemplates || []
  }

  // 添加模板
  async addTemplate(name: string, content: string): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const templates = this.configManager.getConfig().settings.recordTemplates || []
    const template: RecordTemplate = {
      id: 'tpl_' + Date.now().toString(36) + Math.random().toString(36).substring(2),
      name: name,
      content: content
    }
    const newTemplates = [...templates, template]
    this.configManager.getConfig().settings.recordTemplates = newTemplates
    return await this.configManager.saveConfig()
  }

  // 更新模板
  async updateTemplate(template: RecordTemplate): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const templates = this.configManager.getConfig().settings.recordTemplates || []
    const index = templates.findIndex(t => t.id === template.id)
    if (index === -1) {
      return false
    }
    templates[index] = template
    return await this.configManager.saveConfig()
  }

  // 删除模板
  async deleteTemplate(id: string): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    const templates = (this.configManager.getConfig().settings.recordTemplates || []).filter(t => t.id !== id)
    this.configManager.getConfig().settings.recordTemplates = templates
    return await this.configManager.saveConfig()
  }
}
