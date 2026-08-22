/**
 * 配置管理类
 * 负责用户配置的读取、保存、导入导出等操作
 * 使用 HarmonyOS Preferences API 进行持久化存储
 */

import { common } from '@kit.AbilityKit';
import { UserConfig, createDefaultConfig, createDefaultConfigSync, validateConfig } from './UserConfig';
import { ConfigRepository } from '../repository/ConfigRepository';
import { TimeUtils } from '../common/utils/TimeUtils';
import { Logger } from '../common/utils/Logger'

export class ConfigManager {
  private static instance: ConfigManager | null = null;
  private context: common.UIAbilityContext | null = null;
  private config: UserConfig | null = null;

  private constructor() {}

  // 获取单例实例（支持显式注入 context，A5 构造器注入；未传时回退 AppStorage）
  static async getInstance(context?: common.UIAbilityContext): Promise<ConfigManager> {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
      await ConfigManager.instance.init(context);
    } else if (context && !ConfigManager.instance.context) {
      // 已有 instance 但 context 未初始化，用显式传入的 context 重新初始化
      Logger.info('ConfigManager.getInstance: 使用注入的 context 重新初始化');
      await ConfigManager.instance.init(context);
    }
    return ConfigManager.instance;
  }

  // 初始化配置管理器（context 显式注入优先，否则回退 AppStorage）
  private async init(context?: common.UIAbilityContext): Promise<void> {
    Logger.info('ConfigManager.init 开始')
    
    try {
      // 优先使用显式注入的 context（A5），否则从 AppStorage 获取
      let uiContext = context;
      if (!uiContext) {
        uiContext = AppStorage.get('uiContext') as common.UIAbilityContext;
      }
      Logger.info('ConfigManager.init: uiContext - ' + (uiContext ? '存在' : '不存在'))
      
      if (!uiContext) {
        Logger.warn('ConfigManager.init: uiContext 不存在，延迟初始化');
        // 创建默认配置，但不返回，等待下次初始化
        if (!this.config) {
          this.config = await createDefaultConfig();
        }
        return;
      }
      
      Logger.info('ConfigManager.init: 保存 context')
      this.context = uiContext;
      
      // 加载配置
      await this.loadConfig();
      Logger.info('ConfigManager.init: 配置加载完成')
    } catch (error) {
      Logger.error('ConfigManager init failed: ' + JSON.stringify(error));
      // 使用默认配置
      this.config = await createDefaultConfig();
    }
  }

  // 从存储加载配置
  private async loadConfig(): Promise<void> {
    if (!this.context) {
      this.config = await createDefaultConfig();
      return;
    }

    try {
      const configStr = await ConfigRepository.getConfigString(this.context);
      if (configStr) {
        const parsedConfig = JSON.parse(configStr) as UserConfig;
        
        // 验证配置有效性
        if (validateConfig(parsedConfig)) {
          this.config = parsedConfig;
          // 兼容旧配置：确保 customTags 字段存在
          if (!this.config.settings.customTags) {
            this.config.settings.customTags = [];
          }
        } else {
          Logger.warn('Invalid config, using default');
          this.config = await createDefaultConfig();
        }
      } else {
        // 首次使用，创建默认配置
        this.config = await createDefaultConfig();
        await this.saveConfig();
      }
    } catch (error) {
      Logger.error('Load config failed: ' + JSON.stringify(error));
      this.config = await createDefaultConfig();
    }
  }

  // 保存配置到存储
  async saveConfig(): Promise<boolean> {
    Logger.info('saveConfig 开始')
    Logger.info('this.context: ' + (this.context ? '存在' : '不存在'))
    Logger.info('this.config: ' + (this.config ? '存在' : '不存在'))
    
    if (!this.context || !this.config) {
      Logger.error('saveConfig: context 或 config 不存在')
      return false;
    }

    try {
      // 更新修改时间
      this.config.metadata.updatedAt = new Date().toISOString();
      
      const configStr = JSON.stringify(this.config);
      Logger.info('saveConfig: 配置字符串长度: ' + configStr.length)
      
      const success = await ConfigRepository.saveConfigString(this.context, configStr);
      Logger.info('saveConfig: 保存 ' + (success ? '成功' : '失败'))
      
      return success;
    } catch (error) {
      Logger.error('Save config failed: ' + JSON.stringify(error));
      return false;
    }
  }

  // 获取完整配置
  getConfig(): UserConfig {
    if (!this.config) {
      this.config = createDefaultConfigSync();
    }
    return this.config;
  }

  // 更新用户档案
  async updateProfile(name: string, birthDate: string, gender: string, avatar: string): Promise<boolean> {
    if (!this.config) {
      return false;
    }

    this.config.profile.name = name;
    this.config.profile.birthDate = birthDate;
    this.config.profile.gender = gender;
    this.config.profile.avatar = avatar;
    
    return await this.saveConfig();
  }

  // 更新应用设置
  async updateSettings(theme: string, language: string, showTimeDetails: boolean, 
                       enableNotifications: boolean, timeFormat: string): Promise<boolean> {
    if (!this.config) {
      return false;
    }

    this.config.settings.theme = theme;
    this.config.settings.language = language;
    this.config.settings.showTimeDetails = showTimeDetails;
    this.config.settings.enableNotifications = enableNotifications;
    this.config.settings.timeFormat = timeFormat;
    
    return await this.saveConfig();
  }

  // 获取当前主题设置
  getTheme(): string {
    const config = this.getConfig();
    return config.settings.theme;
  }

  // 设置主题并保存
  async setTheme(theme: string): Promise<boolean> {
    Logger.info('ConfigManager.setTheme 开始, theme: ' + theme)
    Logger.info('this.config: ' + (this.config ? '存在' : '不存在'))
    Logger.info('this.context: ' + (this.context ? '存在' : '不存在'))
    
    if (!this.config) {
      Logger.error('ConfigManager.setTheme: config 不存在')
      return false;
    }

    if (!this.context) {
      Logger.error('ConfigManager.setTheme: context 不存在')
      return false;
    }

    try {
      this.config.settings.theme = theme;
      const result = await this.saveConfig();
      Logger.info('ConfigManager.setTheme saveConfig 结果: ' + result)
      return result;
    } catch (error) {
      Logger.error('ConfigManager.setTheme 异常: ' + JSON.stringify(error))
      return false;
    }
  }

  // 更新备份配置
  async updateBackupConfig(autoBackup: boolean, backupFrequency: number, 
                           lastBackupTime: string, backupPath: string): Promise<boolean> {
    if (!this.config) {
      return false;
    }

    this.config.backup.autoBackup = autoBackup;
    this.config.backup.backupFrequency = backupFrequency;
    this.config.backup.lastBackupTime = lastBackupTime;
    this.config.backup.backupPath = backupPath;
    
    return await this.saveConfig();
  }

  // 更新出生日期
  async setBirthDate(birthDate: string): Promise<boolean> {
    if (!this.config) {
      return false;
    }
    
    this.config.profile.birthDate = birthDate;
    return await this.saveConfig();
  }

  // 获取出生日期（返回UTC+8时区日期）
  getBirthDate(): Date {
    const config = this.getConfig();
    // 使用TimeUtils解析日期（UTC+8时区）
    return TimeUtils.parseDate(config.profile.birthDate);
  }

  // 重置为默认配置
  async resetToDefault(): Promise<boolean> {
    this.config = await createDefaultConfig();
    return await this.saveConfig();
  }

  // 更新最后活跃时间（使用天数从 metadata.createdAt 实时计算，无需累加）
  async updateLastActiveTime(): Promise<void> {
    if (!this.config) {
      return;
    }

    this.config.statistics.lastActiveTime = TimeUtils.now().toISOString();
    await this.saveConfig();
  }

  // 获取累计模式设置
  getIsAccumulatedMode(): boolean {
    const config = this.getConfig();
    return config.settings.isAccumulatedMode;
  }

  // 获取剩余模式设置
  getIsRemainingMode(): boolean {
    const config = this.getConfig();
    return config.settings.isRemainingMode;
  }

  // 设置累计模式
  async setIsAccumulatedMode(isAccumulatedMode: boolean): Promise<boolean> {
    if (!this.config || !this.context) {
      return false;
    }
    this.config.settings.isAccumulatedMode = isAccumulatedMode;
    return await this.saveConfig();
  }

  // 设置剩余模式
  async setIsRemainingMode(isRemainingMode: boolean): Promise<boolean> {
    if (!this.config || !this.context) {
      return false;
    }
    this.config.settings.isRemainingMode = isRemainingMode;
    return await this.saveConfig();
  }

  // 获取目标年龄
  getTargetAge(): number {
    const config = this.getConfig();
    const age = config.settings.targetAge;
    // 防护：如果存储值为 undefined/null/NaN/非正数，返回默认值80
    if (age === undefined || age === null || isNaN(age) || age <= 0) {
      return 80;
    }
    return age;
  }

  // 设置目标年龄
  async setTargetAge(targetAge: number): Promise<boolean> {
    if (!this.config || !this.context) {
      return false;
    }
    this.config.settings.targetAge = targetAge;
    return await this.saveConfig();
  }
}
