/**
 * 应用信息配置
 * 统一管理应用的基本信息，避免多处硬编码
 */
import { bundleManager, common } from '@kit.AbilityKit';
import { Logger } from '../common/utils/Logger'

// 应用信息接口
export interface AppInfoConfig {
  appName: string;
  appVersion: string;
  buildNumber: string;
  developer: string;
  website: string;
  description: string;
}

/**
 * 应用信息管理类
 * 从应用配置文件中读取信息，提供统一的访问接口
 */
export class AppInfoManager {
  private static instance: AppInfoManager | null = null;
  private appInfo: AppInfoConfig | null = null;
  private context: common.UIAbilityContext | null = null;

  private constructor() {}

  /**
   * 获取单例实例（支持显式注入 context，A5；替代废弃的全局 getContext）
   */
  static async getInstance(context?: common.UIAbilityContext): Promise<AppInfoManager> {
    if (!AppInfoManager.instance) {
      AppInfoManager.instance = new AppInfoManager();
      AppInfoManager.instance.context = context ?? null;
      await AppInfoManager.instance.initialize();
    } else if (context && !AppInfoManager.instance.context) {
      AppInfoManager.instance.context = context;
    }
    return AppInfoManager.instance;
  }

  /**
   * 初始化应用信息
   * 从bundleManager获取应用版本等信息
   */
  private async initialize(): Promise<void> {
    try {
      // 获取应用包信息
      const bundleInfo = await bundleManager.getBundleInfoForSelf(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT);
      
      // 从资源文件读取应用名称和描述
      const appName = await this.getResourceString('app_name', '');
      const appDescription = await this.getResourceString('app_description', '');
      
      // 构建应用信息
      this.appInfo = {
        appName: appName,
        appVersion: bundleInfo.versionName,
        buildNumber: this.generateBuildNumber(),
        developer: 'rainforcetime',
        website: 'https://github.com/rainforcetime/RecordLife',
        description: appDescription
      };
      
      Logger.info('应用信息初始化成功: ' + JSON.stringify(this.appInfo));
    } catch (error) {
      Logger.error('应用信息初始化失败，使用默认值: ' + JSON.stringify(error));
      // 使用默认值
      this.appInfo = this.getDefaultAppInfo();
    }
  }

  /**
   * 从资源文件读取字符串
   */
  private async getResourceString(resourceName: string, defaultValue: string): Promise<string> {
    try {
      const rm = this.context?.resourceManager;
      if (rm) {
        return rm.getStringByNameSync(resourceName);
      }
      return defaultValue;
    } catch (error) {
      Logger.error(`读取资源字符串 ${resourceName} 失败: ` + JSON.stringify(error));
      return defaultValue;
    }
  }

  /**
   * 生成构建号
   * 基于当前日期生成，格式：YYYYMMDD
   */
  private generateBuildNumber(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = (now.getMonth() + 1).toString().padStart(2, '0');
    const day = now.getDate().toString().padStart(2, '0');
    return `${year}${month}${day}`;
  }

  /**
   * 获取默认应用信息
   */
  private getDefaultAppInfo(): AppInfoConfig {
    return {
      appName: '',
      appVersion: '0.0.1',
      buildNumber: this.generateBuildNumber(),
      developer: 'rainforcetime',
      website: 'https://github.com/rainforcetime/RecordLife',
      description: ''
    };
  }

  /**
   * 获取应用信息
   */
  getAppInfo(): AppInfoConfig {
    if (!this.appInfo) {
      this.appInfo = this.getDefaultAppInfo();
    }
    return this.appInfo;
  }

  /**
   * 获取应用名称
   */
  getAppName(): string {
    return this.getAppInfo().appName;
  }

  /**
   * 获取应用版本
   */
  getAppVersion(): string {
    return this.getAppInfo().appVersion;
  }

  /**
   * 获取构建号
   */
  getBuildNumber(): string {
    return this.getAppInfo().buildNumber;
  }

  /**
   * 获取开发者信息
   */
  getDeveloper(): string {
    return this.getAppInfo().developer;
  }

  /**
   * 获取官方网站
   */
  getWebsite(): string {
    return this.getAppInfo().website;
  }

  /**
   * 获取应用描述
   */
  getDescription(): string {
    return this.getAppInfo().description;
  }
}
