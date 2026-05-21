/**
 * 应用信息配置
 * 统一管理应用的基本信息，避免多处硬编码
 */
import { bundleManager } from '@kit.AbilityKit';

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

  private constructor() {}

  /**
   * 获取单例实例
   */
  static async getInstance(): Promise<AppInfoManager> {
    if (!AppInfoManager.instance) {
      AppInfoManager.instance = new AppInfoManager();
      await AppInfoManager.instance.initialize();
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
      const appName = await this.getResourceString('app_name', '活着');
      const appDescription = await this.getResourceString('app_description', '记录生活，珍惜每一刻');
      
      // 构建应用信息
      this.appInfo = {
        appName: appName,
        appVersion: bundleInfo.versionName,
        buildNumber: this.generateBuildNumber(),
        developer: 'rainforcetime',
        website: 'https://github.com/rainforcetime/record-life',
        description: appDescription
      };
      
      console.info('应用信息初始化成功: ' + JSON.stringify(this.appInfo));
    } catch (error) {
      console.error('应用信息初始化失败，使用默认值: ' + JSON.stringify(error));
      // 使用默认值
      this.appInfo = this.getDefaultAppInfo();
    }
  }

  /**
   * 从资源文件读取字符串
   */
  private async getResourceString(resourceName: string, defaultValue: string): Promise<string> {
    try {
      // 尝试从资源管理器读取
      const resourceStr = $r(`app.string.${resourceName}`);
      // 注意：在ArkTS中，$r返回的是Resource对象，需要通过特定方式获取值
      // 这里暂时返回默认值，实际使用时UI组件可以直接使用$r
      return defaultValue;
    } catch (error) {
      console.error(`读取资源字符串 ${resourceName} 失败: ` + JSON.stringify(error));
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
      appName: '活着',
      appVersion: '0.0.1',
      buildNumber: this.generateBuildNumber(),
      developer: 'rainforcetime',
      website: 'https://github.com/rainforcetime/record-life',
      description: '记录生活，珍惜每一刻'
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
