/**
 * 配置管理类
 * 负责用户配置的读取、保存、导入导出等操作
 * 使用 HarmonyOS Preferences API 进行持久化存储
 */

import preferences from '@ohos.data.preferences';
import common from '@ohos.app.ability.common';
import { UserConfig, UserProfile, AppSettings, BackupConfig, DataStatistics, ConfigMetadata, createDefaultConfig, createDefaultConfigSync, validateConfig } from './UserConfig';
import { Tag } from '../common/types';
import { TimeUtils } from '../common/utils/TimeUtils';
import { AppInfoManager } from './AppInfoConfig';
import { ImageBase64Utils } from '../common/utils/ImageBase64Utils';
import { MorePageHelper } from '../common/utils/MorePageHelper';

// 导出数据接口
interface ExportData {
  settings: AppSettings;
  backup: BackupConfig;
  statistics: DataStatistics;
  metadata: ConfigMetadata;
  exportedAt: string;
  appVersion: string;
  profile: UserProfile;  // 放在最后，因为头像的 base64 数据很长
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
      
      // 如果 uiContext 不存在，尝试从 AppStorage 获取 uiContext
      if (!uiContext) {
        uiContext = AppStorage.get('uiContext') as common.UIAbilityContext;
        console.info('ConfigManager.init: 从 AppStorage 获取 uiContext - ' + (uiContext ? '成功' : '失败'))
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
          // 兼容旧配置：确保 customTags 字段存在
          if (!this.config.settings.customTags) {
            this.config.settings.customTags = [];
          }
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

  // ==================== 自定义标签管理 ====================

  // 获取所有自定义标签
  getCustomTags(): Tag[] {
    const config = this.getConfig();
    return config.settings.customTags || [];
  }

  // 添加自定义标签
  async addCustomTag(tag: Tag): Promise<boolean> {
    console.info('[ConfigManager] addCustomTag 开始, tag: ' + JSON.stringify(tag))
    console.info('[ConfigManager] addCustomTag config: ' + (this.config ? '存在' : 'null') + ', preferences: ' + (this.preferences ? '存在' : 'null'))
    if (!this.config || !this.preferences) {
      console.warn('[ConfigManager] addCustomTag 失败: config或preferences为null')
      return false;
    }
    const customTags = this.config.settings.customTags || [];
    const newTags = [...customTags, tag];
    this.config.settings.customTags = newTags;
    console.info('[ConfigManager] addCustomTag 准备保存, tags count: ' + newTags.length)
    const result = await this.saveConfig();
    console.info('[ConfigManager] addCustomTag saveConfig 返回: ' + result)
    return result;
  }

  // 更新自定义标签
  async updateCustomTag(tag: Tag): Promise<boolean> {
    if (!this.config || !this.preferences) {
      return false;
    }
    const tags = this.config.settings.customTags || [];
    const index = tags.findIndex(t => t.id === tag.id);
    if (index === -1) {
      return false;
    }
    tags[index] = tag;
    return await this.saveConfig();
  }

  // 删除自定义标签
  async deleteCustomTag(id: string): Promise<boolean> {
    if (!this.config || !this.preferences) {
      return false;
    }
    const tags = (this.config.settings.customTags || []).filter(t => t.id !== id);
    this.config.settings.customTags = tags;
    return await this.saveConfig();
  }

  // 保存整个自定义标签列表
  async saveCustomTags(tags: Tag[]): Promise<boolean> {
    if (!this.config || !this.preferences) {
      return false;
    }
    this.config.settings.customTags = tags;
    return await this.saveConfig();
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
    
    // 从AppInfoManager获取应用版本号
    let appVersion = '0.0.2';  // 默认使用当前app.json5中的版本号
    try {
      console.info('[ConfigManager] 开始获取应用版本...');
      const appInfoManager = await AppInfoManager.getInstance();
      appVersion = appInfoManager.getAppVersion();
      console.info('[ConfigManager] 获取到应用版本: ' + appVersion);
    } catch (error) {
      console.error('[ConfigManager] 获取应用版本失败: ' + JSON.stringify(error));
    }
    
    // 处理头像：将图片转换为 base64
    let profileAvatar = config.profile.avatar;
    if (config.profile.avatar && config.profile.avatar.length > 0) {
      try {
        // 将 URI 转换为沙箱路径
        const avatarPath = MorePageHelper.uriToSandboxPath(config.profile.avatar);
        console.info('[ConfigManager] 头像 URI: ' + config.profile.avatar);
        console.info('[ConfigManager] 头像沙箱路径: ' + avatarPath);
        
        // 检查文件是否存在
        if (MorePageHelper.fileExists(avatarPath)) {
          // 转换为 base64
          const base64Str = ImageBase64Utils.imageToBase64(avatarPath);
          if (base64Str && base64Str.length > 0) {
            profileAvatar = base64Str;
            console.info('[ConfigManager] 头像已转换为 base64，长度: ' + base64Str.length);
          } else {
            console.warn('[ConfigManager] 头像转换 base64 失败，保留原始路径');
          }
        } else {
          console.warn('[ConfigManager] 头像文件不存在: ' + avatarPath);
        }
      } catch (error) {
        console.error('[ConfigManager] 处理头像失败: ' + JSON.stringify(error));
      }
    } else {
      console.info('[ConfigManager] 没有头像，跳过转换');
    }
    
    const profileWithBase64Avatar: UserProfile = {
      name: config.profile.name,
      birthDate: config.profile.birthDate,
      gender: config.profile.gender,
      avatar: profileAvatar
    };
    
    const exportData: ExportData = {
      settings: config.settings,
      backup: config.backup,
      statistics: config.statistics,
      metadata: config.metadata,
      exportedAt: new Date().toISOString(),
      appVersion: appVersion,
      profile: profileWithBase64Avatar  // 放在最后
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
      
      // 处理头像：如果是 base64 字符串，则转换为图片文件
      let profileAvatar = importedConfig.profile.avatar;
      if (importedConfig.profile.avatar && importedConfig.profile.avatar.length > 0) {
        // 检查是否是 base64 字符串
        // Base64 字符串特征：长度较长且不是 file:// URI 格式
        const avatarValue = importedConfig.profile.avatar;
        const isFileUri = avatarValue.startsWith('file://');
        const isBase64 = !isFileUri && avatarValue.length > 200;
        
        console.info('[ConfigManager] 头像检测: isFileUri=' + isFileUri + ', isBase64=' + isBase64 + ', length=' + avatarValue.length);
        
        if (isBase64) {
          try {
            // 获取 context
            const context = AppStorage.get('uiContext') as common.UIAbilityContext;
            if (context) {
              // 获取头像保存路径
              const avatarPath = ImageBase64Utils.getAvatarSavePath(context);
              console.info('[ConfigManager] 将 base64 转换为图片: ' + avatarPath);
              
              // 转换 base64 为图片
              const success = ImageBase64Utils.base64ToImage(importedConfig.profile.avatar, avatarPath);
              if (success) {
                // 将 avatar 更新为文件路径
                profileAvatar = avatarPath;
                console.info('[ConfigManager] 头像已从 base64 转换为图片文件');
              } else {
                console.warn('[ConfigManager] base64 转图片失败，保留原始数据');
              }
            } else {
              console.warn('[ConfigManager] 无法获取 context，跳过头像转换');
            }
          } catch (error) {
            console.error('[ConfigManager] 处理头像失败: ' + JSON.stringify(error));
          }
        } else {
          console.info('[ConfigManager] 头像是文件路径或URI，无需转换');
        }
      }
      
      const profileWithImageAvatar: UserProfile = {
        name: importedConfig.profile.name,
        birthDate: importedConfig.profile.birthDate,
        gender: importedConfig.profile.gender,
        avatar: profileAvatar
      };
      
      this.config.profile = profileWithImageAvatar;
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
    if (!this.config || !this.preferences) {
      return false;
    }
    this.config.settings.isAccumulatedMode = isAccumulatedMode;
    return await this.saveConfig();
  }

  // 设置剩余模式
  async setIsRemainingMode(isRemainingMode: boolean): Promise<boolean> {
    if (!this.config || !this.preferences) {
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
    if (!this.config || !this.preferences) {
      return false;
    }
    this.config.settings.targetAge = targetAge;
    return await this.saveConfig();
  }
}
