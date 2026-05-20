/**
 * 配置管理类
 * 负责用户配置的读取、保存、导入导出等操作
 * 使用 HarmonyOS Preferences API 进行持久化存储
 */

import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { UserConfig, UserProfile, AppSettings, BackupConfig, DataStatistics, ConfigMetadata, createDefaultConfig, validateConfig } from './UserConfig';
import { TimeUtils } from './TimeUtils';

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
    }
    return ConfigManager.instance;
  }

  // 初始化配置管理器
  private async init(): Promise<void> {
    try {
      // 获取 Preferences 实例
      // 使用 UIContext 获取上下文（替代已废弃的 getContext）
      const uiContext = AppStorage.get('uiContext') as common.UIAbilityContext;
      if (!uiContext) {
        console.error('UIContext not found in AppStorage');
        this.config = createDefaultConfig();
        return;
      }
      this.preferences = await preferences.getPreferences(uiContext, this.STORE_NAME);
      
      // 加载配置
      await this.loadConfig();
    } catch (error) {
      console.error('ConfigManager init failed:', error);
      // 使用默认配置
      this.config = createDefaultConfig();
    }
  }

  // 从存储加载配置
  private async loadConfig(): Promise<void> {
    if (!this.preferences) {
      this.config = createDefaultConfig();
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
          this.config = createDefaultConfig();
        }
      } else {
        // 首次使用，创建默认配置
        this.config = createDefaultConfig();
        await this.saveConfig();
      }
    } catch (error) {
      console.error('Load config failed:', error);
      this.config = createDefaultConfig();
    }
  }

  // 保存配置到存储
  async saveConfig(): Promise<boolean> {
    if (!this.preferences || !this.config) {
      return false;
    }

    try {
      // 更新修改时间
      this.config.metadata.updatedAt = new Date().toISOString();
      
      const configStr = JSON.stringify(this.config);
      await this.preferences.put(this.CONFIG_KEY, configStr);
      await this.preferences.flush();
      
      return true;
    } catch (error) {
      console.error('Save config failed:', error);
      return false;
    }
  }

  // 获取完整配置
  getConfig(): UserConfig {
    if (!this.config) {
      this.config = createDefaultConfig();
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
        this.config = createDefaultConfig();
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
    this.config = createDefaultConfig();
    return await this.saveConfig();
  }

  // 更新统计信息（使用UTC+8时区）
  async updateStatistics(): Promise<void> {
    if (!this.config) {
      return;
    }

    const now = TimeUtils.now();
    const lastActive = new Date(this.config.statistics.lastActiveTime);
    const daysDiff = Math.floor((now.getTime() - lastActive.getTime()) / (1000 * 60 * 60 * 24));

    if (daysDiff > 0) {
      this.config.statistics.usageDays += daysDiff;
      this.config.statistics.lastActiveTime = now.toISOString();
      await this.saveConfig();
    }
  }
}
