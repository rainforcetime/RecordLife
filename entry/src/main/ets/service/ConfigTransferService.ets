/**
 * 配置传输服务（service 层）
 * 用户配置的导出/导入（含头像 base64 转换），拆分自 ConfigManager（P3 重构，解决 A2 职责过重）
 * 依赖 ConfigManager 的 getConfig() / saveConfig() 公共接口操作其内存态配置
 */
import { common } from '@kit.AbilityKit'
import { UserConfig, UserProfile, AppSettings, BackupConfig, DataStatistics, ConfigMetadata, validateConfig } from '../config/UserConfig'
import { ConfigManager } from '../config/ConfigManager'
import { AppInfoManager } from '../config/AppInfoConfig'
import { ImageBase64Utils } from '../common/utils/ImageBase64Utils'
import { MorePageHelper } from '../common/utils/MorePageHelper'
import { Logger } from '../common/utils/Logger'

// 导出数据接口（头像 base64 数据很长，放在最后）
interface ExportData {
  settings: AppSettings;
  backup: BackupConfig;
  statistics: DataStatistics;
  metadata: ConfigMetadata;
  exportedAt: string;
  appVersion: string;
  profile: UserProfile;
}

export class ConfigTransferService {
  // 导出配置 (用于备份)
  static async exportConfig(configManager: ConfigManager): Promise<string> {
    const config = configManager.getConfig();

    // 从AppInfoManager获取应用版本号
    let appVersion = '0.0.2';  // 默认使用当前app.json5中的版本号
    try {
      const appInfoManager = await AppInfoManager.getInstance();
      appVersion = appInfoManager.getAppVersion();
    } catch (error) {
      Logger.error('[ConfigTransferService] 获取应用版本失败: ' + JSON.stringify(error));
    }

    // 处理头像：将图片转换为 base64
    let profileAvatar = config.profile.avatar;
    if (config.profile.avatar && config.profile.avatar.length > 0) {
      try {
        // 将 URI 转换为沙箱路径
        const avatarPath = MorePageHelper.uriToSandboxPath(config.profile.avatar);

        // 检查文件是否存在
        if (MorePageHelper.fileExists(avatarPath)) {
          // 转换为 base64
          const base64Str = ImageBase64Utils.imageToBase64(avatarPath);
          if (base64Str && base64Str.length > 0) {
            profileAvatar = base64Str;
          } else {
            Logger.warn('[ConfigTransferService] 头像转换 base64 失败，保留原始路径');
          }
        } else {
          Logger.warn('[ConfigTransferService] 头像文件不存在: ' + avatarPath);
        }
      } catch (error) {
        Logger.error('[ConfigTransferService] 处理头像失败: ' + JSON.stringify(error));
      }
    }

    const profileWithBase64Avatar: UserProfile = {
      name: config.profile.name,
      birthDate: config.profile.birthDate,
      gender: config.profile.gender,
      avatar: profileAvatar,
      signature: config.profile.signature  // 修复：签名/座右铭参与导入导出
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
  static async importConfig(configManager: ConfigManager, configStr: string): Promise<boolean> {
    try {
      const importedConfig = JSON.parse(configStr) as UserConfig;

      // 验证配置
      if (!validateConfig(importedConfig)) {
        Logger.error('[ConfigTransferService] Invalid imported config');
        return false;
      }

      // 获取内存态配置（getConfig 内部保证非空，等价于原 createDefaultConfig 兜底）
      const config = configManager.getConfig();

      config.version = importedConfig.version;

      // 处理头像：如果是 base64 字符串，则转换为图片文件
      let profileAvatar = importedConfig.profile.avatar;
      if (importedConfig.profile.avatar && importedConfig.profile.avatar.length > 0) {
        // 检查是否是 base64 字符串
        // Base64 字符串特征：长度较长且不是 file:// URI 格式
        const avatarValue = importedConfig.profile.avatar;
        const isFileUri = avatarValue.startsWith('file://');
        const isBase64 = !isFileUri && avatarValue.length > 200;

        if (isBase64) {
          try {
            // 获取 context
            const context = AppStorage.get('uiContext') as common.UIAbilityContext;
            if (context) {
              // 获取头像保存路径
              const avatarPath = ImageBase64Utils.getAvatarSavePath(context);

              // 转换 base64 为图片
              const success = ImageBase64Utils.base64ToImage(importedConfig.profile.avatar, avatarPath);
              if (success) {
                // 将 avatar 更新为文件路径
                profileAvatar = avatarPath;
              } else {
                Logger.warn('[ConfigTransferService] base64 转图片失败，保留原始数据');
              }
            } else {
              Logger.warn('[ConfigTransferService] 无法获取 context，跳过头像转换');
            }
          } catch (error) {
            Logger.error('[ConfigTransferService] 处理头像失败: ' + JSON.stringify(error));
          }
        }
      }

      const profileWithImageAvatar: UserProfile = {
        name: importedConfig.profile.name,
        birthDate: importedConfig.profile.birthDate,
        gender: importedConfig.profile.gender,
        avatar: profileAvatar,
        signature: importedConfig.profile.signature  // 修复：签名/座右铭参与导入导出
      };

      config.profile = profileWithImageAvatar;
      config.settings = importedConfig.settings;
      config.backup = importedConfig.backup;
      config.statistics = importedConfig.statistics;
      config.metadata.createdAt = importedConfig.metadata.createdAt;
      config.metadata.updatedAt = new Date().toISOString();
      config.metadata.deviceId = importedConfig.metadata.deviceId;

      return await configManager.saveConfig();
    } catch (error) {
      Logger.error('[ConfigTransferService] Import config failed: ' + JSON.stringify(error));
      return false;
    }
  }
}
