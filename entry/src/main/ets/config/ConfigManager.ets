/**
 * 配置管理类
 * 负责用户配置的读取、保存、导入导出等操作
 * 使用 HarmonyOS Preferences API 进行持久化存储
 */

import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { UserConfig, UserProfile, AppSettings, BackupConfig, DataStatistics, ConfigMetadata, createDefaultConfig, createDefaultConfigSync, validateConfig } from './UserConfig';
import { TimeUtils } from '../common/utils/TimeUtils';

// 导出数据接口
interface ExportData {
  version: string;
  profile: UserProfile;
  settings: AppSettings;
  backup: BackupConfig;
  statistics: DataStatistics;
  metadata: ConfigMetadata;
  exportedAt: string;
  appVersion: string;
}

export class ConfigManager {
  private static instance: ConfigManager | null = null;
  private preferences: preferences.Preferences | null = null;
  private config: UserConfig | null = null;
  private readonly CONFIG_KEY = 'user_config';
  private readonly STORE_NAME = 'record_life_config';

  private constructor() {}

  // 获取单例实例
  static async getInstance(): Promise<ConfigManager> {
    if (!ConfigManager.instance) {
      ConfigManager.instance = new ConfigManager();
      await ConfigManager.instance.init();
    } else if (!ConfigManager.instance.preferences) {
      // 如果 instance 存在但 preferences 未初始化，重新初始化
      console.info('ConfigManager.getInstance: preferences 未初始化，重新初始化');
      await ConfigManager.instance.init();
    }
    return ConfigManager.instance;
  }

  // 初始化配置管理器
  private async init(): Promise<void> {
    console.info('ConfigManager.init 开始')
    
    try {
      // 获取 Preferences 实例
      // 使用 UIContext 获取上下文（替代已废弃的 getContext）
      let uiContext = AppStorage.get('uiContext') as common.UIAbilityContext;
      console.info('ConfigManager.init: uiContext - ' + (uiContext ? '存在' : '不存在'))
      
      // 如果 uiContext 不存在，尝试从 AppStorage 获取 context
      if (!uiContext) {
        uiContext = AppStorage.get('context') as common.UIAbilityContext;
        console.info('ConfigManager.init: 从 AppStorage 获取 context - ' + (uiContext ? '成功' : '失败'))
      }
      
      if (!uiContext) {
        console.warn('ConfigManager.init: uiContext 不存在，延迟初始化 preferences');
        // 创建默认配置，但不返回，等待下次初始化
        if (!this.config) {
          this.config = await createDefaultConfig();
        }
        return;
      }
      
      console.info('ConfigManager.init: 开始获取 Preferences')
      this.preferences = await preferences.getPreferences(uiContext, this.STORE_NAME);
      console.info('ConfigManager.init: Preferences 获取成功 - ' + (this.preferences ? '是' : '否'))
      
      // 加载配置
      await this.loadConfig();
      console.info('ConfigManager.init: 配置加载完成')
    } catch (error) {
      console.error('ConfigManager init failed:', error);
      // 使用默认配置
      this.config = await createDefaultConfig();
    }
  }

  // 从存储加载配置
  private async loadConfig(): Promise<void> {
    if (!this.preferences) {
      this.config = await createDefaultConfig();
      return;
    }

    try {
      const configStr = await this.preferences.get(this.CONFIG_KEY, '') as string;
      if (configStr) {
        const parsedConfig = JSON.parse(configStr) as UserConfig;
        
        // 验证配置有效性
        if (validateConfig(parsedConfig)) {
          this.config = parsedConfig;
        } else {
          console.warn('Invalid config, using default');
          this.config = await createDefaultConfig();
        }
      } else {
        // 首次使用，创建默认配置
        this.config = await createDefaultConfig();
        await this.saveConfig();
      }
    } catch (error) {
      console.error('Load config failed:', error);
      this.config = await createDefaultConfig();
    }
  }

  // 保存配置到存储
  async saveConfig(): Promise<boolean> {
    console.info('saveConfig 开始')
    console.info('this.preferences: ' + (this.preferences ? '存在' : '不存在'))
    console.info('this.config: ' + (this.config ? '存在' : '不存在'))
    
    if (!this.preferences || !this.config) {
      console.error('saveConfig: preferences 或 config 不存在')
      return false;
    }

    try {
      // 更新修改时间
      this.config.metadata.updatedAt = new Date().toISOString();
      
      const configStr = JSON.stringify(this.config);
      console.info('saveConfig: 配置字符串长度: ' + configStr.length)
      
      await this.preferences.put(this.CONFIG_KEY, configStr);
      console.info('saveConfig: put 成功')
      
      await this.preferences.flush();
      console.info('saveConfig: flush 成功')
      
      return true;
    } catch (error) {
      console.error('Save config failed:', error);
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
    console.info('ConfigManager.setTheme 开始, theme: ' + theme)
    console.info('this.config: ' + (this.config ? '存在' : '不存在'))
    console.info('this.preferences: ' + (this.preferences ? '存在' : '不存在'))
    
    if (!this.config) {
      console.error('ConfigManager.setTheme: config 不存在')
      return false;
    }

    if (!this.preferences) {
      console.error('ConfigManager.setTheme: preferences 不存在')
      return false;
    }

    try {
      this.config.settings.theme = theme;
      const result = await this.saveConfig();
      console.info('ConfigManager.setTheme saveConfig 结果: ' + result)
      return result;
    } catch (error) {
      console.error('ConfigManager.setTheme 异常: ' + JSON.stringify(error))
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

  // 导出配置 (用于备份)
  async exportConfig(): Promise<string> {
    const config = this.getConfig();
    const exportData: ExportData = {
      version: config.version,
      profile: config.profile,
      settings: config.settings,
      backup: config.backup,
      statistics: config.statistics,
      metadata: config.metadata,
      exportedAt: new Date().toISOString(),
      appVersion: '1.0.0'
    };
    return JSON.stringify(exportData, null, 2);
  }

  // 导入配置 (用于恢复)
  async importConfig(configStr: string): Promise<boolean> {
    try {
      const importedConfig = JSON.parse(configStr) as UserConfig;
      
      // 验证配置
      if (!validateConfig(importedConfig)) {
        console.error('Invalid imported config');
        return false;
      }

      // 复制配置
      if (!this.config) {
        this.config = await createDefaultConfig();
      }
      
      this.config.version = importedConfig.version;
      this.config.profile = importedConfig.profile;
      this.config.settings = importedConfig.settings;
      this.config.backup = importedConfig.backup;
      this.config.statistics = importedConfig.statistics;
      this.config.metadata.createdAt = importedConfig.metadata.createdAt;
      this.config.metadata.updatedAt = new Date().toISOString();
      this.config.metadata.deviceId = importedConfig.metadata.deviceId;

      return await this.saveConfig();
    } catch (error) {
      console.error('Import config failed:', error);
      return false;
    }
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
}
