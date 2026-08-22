// 账号页面业务逻辑类：viewmodel/AccountViewModel.ets
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { ConfigManager } from '../config/ConfigManager'
import { AppInfo } from '../config/UserConfig'
import { AppInfoManager } from '../config/AppInfoConfig'
import { ThemeManager } from '../config/ThemeManager'
import { AccountUtils } from '../common/utils/AccountUtils'
import { AccountProfile, ThemeSettings, AccountDataStatistics, AvatarInfo } from '../model/AccountModel'
import { ImageFileService } from '../service/ImageFileService'
import { StorageService } from '../service/StorageService'
import { resourceManager } from '@kit.LocalizationKit'
import { Logger } from '../common/utils/Logger'

// 向后兼容：AccountPage.ets 通过 AccountViewModel 导入这些类型
export { AccountProfile, AccountDataStatistics }

// 账号页面状态管理类
export class AccountViewModel {
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private themeManager: ThemeManager | null = null

  // 初始化配置管理器
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.context = context
      Logger.info('AccountViewModel: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      this.configManager = await ConfigManager.getInstance(this.context)
      Logger.info('AccountViewModel: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
      
      this.themeManager = await ThemeManager.getInstance(this.context)
      Logger.info('AccountViewModel: themeManager 已初始化 - ' + (this.themeManager ? '成功' : '失败'))
    } catch (error) {
      Logger.error('AccountViewModel 初始化失败: ' + JSON.stringify(error))
    }
  }

  // 获取 ResourceManager（用于国际化资源读取）
  private getRm(): resourceManager.ResourceManager | null {
    if (!this.context) {
      return null
    }
    return this.context.resourceManager
  }

  // 加载用户资料
  async loadUserProfile(): Promise<AccountProfile> {
    const rm = this.getRm()
    const defaultProfile: AccountProfile = {
      name: rm ? rm.getStringByNameSync('username_default') : '',
      birthday: '1990-01-15',
      gender: rm ? rm.getStringByNameSync('gender_other') : '',
      avatar: '',
      hasCustomAvatar: false,
      signature: ''
    }

    if (!this.configManager) {
      return defaultProfile
    }

    try {
      const config = this.configManager.getConfig()
      const profile = config.profile

      // 加载用户名
      if (profile.name && profile.name.length > 0) {
        defaultProfile.name = profile.name
      }

      // 加载出生日期
      if (profile.birthDate && profile.birthDate.length > 0) {
        defaultProfile.birthday = profile.birthDate
      }

      // 加载性别
      if (profile.gender && profile.gender.length > 0) {
        defaultProfile.gender = AccountUtils.convertGenderToDisplay(profile.gender, rm)
      }

      // 加载签名（可选字段，旧配置缺省为空）
      if (profile.signature && profile.signature.length > 0) {
        defaultProfile.signature = profile.signature
      }

      Logger.info('用户资料加载成功')
      return defaultProfile
    } catch (error) {
      Logger.error('加载用户资料失败: ' + JSON.stringify(error))
      return defaultProfile
    }
  }

  // 加载主题设置
  async loadThemeSettings(): Promise<ThemeSettings> {
    const rm = this.getRm()
    if (!this.configManager) {
      return { currentTheme: rm ? rm.getStringByNameSync('follow_system') : '' }
    }

    try {
      const config = this.configManager.getConfig()
      const theme = config.settings.theme
      const currentTheme = AccountUtils.themeToDisplay(theme, rm)
      return { currentTheme }
    } catch (error) {
      Logger.error('加载主题设置失败: ' + JSON.stringify(error))
      return { currentTheme: rm ? rm.getStringByNameSync('follow_system') : '' }
    }
  }

  // 加载应用信息（从AppInfoManager获取）
  async loadAppInfo(): Promise<AppInfo> {
    // 默认应用信息（作为备用）
    const rm = this.getRm()
    const defaultAppInfo: AppInfo = {
      appName: rm ? rm.getStringByNameSync('app_name') : '',
      appVersion: '0.0.1',
      buildNumber: '20260521',
      developer: 'rainforcetime',
      website: 'https://github.com/rainforcetime/RecordLife',
      description: rm ? rm.getStringByNameSync('app_desc') : ''
    };

    try {
      // 从AppInfoManager获取应用信息（从bundleManager读取）
      const appInfoManager = await AppInfoManager.getInstance();
      const config = appInfoManager.getAppInfo();
      
      return {
        appName: config.appName,
        appVersion: config.appVersion,
        buildNumber: config.buildNumber,
        developer: config.developer,
        website: config.website,
        description: config.description
      };
    } catch (error) {
      Logger.error('从AppInfoManager加载应用信息失败: ' + JSON.stringify(error));
      return defaultAppInfo;
    }
  }

  // 加载数据统计信息
  async loadDataStatistics(): Promise<AccountDataStatistics> {
    const rm = this.getRm()
    const defaultStatistics: AccountDataStatistics = {
      usageDays: 0,
      dataVersion: 'v0.0.1',
      lastActiveTime: '',
      storageSize: rm ? rm.getStringByNameSync('calculation_hint') : ''
    }

    try {
      // 优先从AppInfoManager获取最新版本信息
      let appVersion = '0.0.1';
      try {
        const appInfoManager = await AppInfoManager.getInstance();
        appVersion = appInfoManager.getAppVersion();
      } catch (error) {
        Logger.error('从AppInfoManager获取版本失败: ' + JSON.stringify(error));
      }

      if (!this.configManager) {
        return {
          usageDays: 0,
          dataVersion: `v${appVersion}`,
          lastActiveTime: '',
          storageSize: rm ? rm.getStringByNameSync('calculation_hint') : ''
        };
      }

      const config = this.configManager.getConfig();

      // 使用天数与存储大小统计已下沉至 service/StorageService（P4）
      const usageDays = StorageService.calcUsageDays(config.metadata.createdAt);
      const lastActiveTime = this.formatDateTime(new Date(config.statistics.lastActiveTime));
      const storageSize = this.context ? await StorageService.getAppStorageSize(this.context) : ''

      const result: AccountDataStatistics = {
        usageDays: usageDays,
        dataVersion: `v${appVersion}`,
        lastActiveTime: lastActiveTime,
        storageSize: storageSize
      };

      return result;
    } catch (error) {
      Logger.error('[AccountViewModel] 加载数据统计失败: ' + JSON.stringify(error));
      return defaultStatistics;
    }
  }

  // 格式化日期时间
  private formatDateTime(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    return `${year}-${month}-${day} ${hours}:${minutes}`
  }

  // 加载保存的头像（从ConfigManager统一读取）
  async loadSavedAvatar(): Promise<AvatarInfo> {
    try {
      if (!this.configManager) {
        return { avatar: '', hasCustomAvatar: false }
      }

      // 从ConfigManager获取头像路径
      const config = this.configManager.getConfig()
      const savedAvatarPath = config.profile.avatar

      if (savedAvatarPath && savedAvatarPath.length > 0) {
        // 如果是URI格式（file://开头），直接使用
        if (savedAvatarPath.startsWith('file://')) {
          Logger.info('加载保存的头像URI成功: ' + savedAvatarPath)
          return { avatar: savedAvatarPath, hasCustomAvatar: true }
        } else {
          // 如果是旧的沙箱路径格式，转换为URI
          if (fileIo.accessSync(savedAvatarPath)) {
            let avatarUri = fileUri.getUriFromPath(savedAvatarPath)
            Logger.info('加载保存的头像并转换为URI成功: ' + avatarUri)
            return { avatar: avatarUri, hasCustomAvatar: true }
          }
        }
      }
      
      // 没有保存的头像，使用默认头像
      return { avatar: '', hasCustomAvatar: false }
    } catch (error) {
      Logger.error('加载保存的头像失败: ' + JSON.stringify(error))
      return { avatar: '', hasCustomAvatar: false }
    }
  }

  // 主题切换处理
  async onThemeChange(value: string): Promise<boolean> {
    Logger.info('开始切换主题: ' + value)
    
    if (!this.themeManager) {
      Logger.error('主题管理器未初始化')
      return false
    }
    
    if (!this.context) {
      Logger.error('上下文未初始化')
      return false
    }

    try {
      // 转换为存储格式
      const theme = AccountUtils.displayToTheme(value, this.getRm())
      Logger.info('转换后的主题: ' + theme)

      // 通过ThemeManager更新主题（会自动保存到ConfigManager并更新AppStorage）
      const success = await this.themeManager.updateTheme(theme as 'light' | 'dark' | 'auto')
      Logger.info('更新主题结果: ' + success)

      if (success) {
        // 应用主题到系统
        await this.applyTheme(theme)

        // 更新 AppStorage（供页面监听）
        AppStorage.setOrCreate('currentTheme', theme)

        Logger.info('主题设置成功: ' + theme)
        return true
      } else {
        Logger.error('主题更新失败')
        return false
      }
    } catch (error) {
      Logger.error('主题切换异常: ' + JSON.stringify(error))
      return false
    }
  }

  // 应用主题到系统
  private async applyTheme(theme: string): Promise<void> {
    if (!this.context) {
      return
    }

    try {
      const applicationContext = this.context.getApplicationContext()
      
      // 根据主题设置颜色模式
      switch (theme) {
        case 'light':
          applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
          break
        case 'dark':
          applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
          break
        case 'auto':
        default:
          applicationContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
          break
      }

      Logger.info('主题已应用: ' + theme)
    } catch (error) {
      Logger.error('应用主题失败: ' + JSON.stringify(error))
    }
  }

  // 头像更换处理
  async onChangeAvatar(): Promise<string | null> {
    try {
      // 创建图片选择选项
      let photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      // 设置选择图片类型
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      // 设置最多选择1张图片
      photoSelectOptions.maxSelectNumber = 1

      // 创建图片选择器
      let photoPicker = new photoAccessHelper.PhotoViewPicker()

      // 调用select方法拉起图库选择界面
      const photoSelectResult = await photoPicker.select(photoSelectOptions)
      Logger.info('PhotoViewPicker.select successfully, photoSelectResult: ' + JSON.stringify(photoSelectResult))

      // 获取选中的图片URI数组
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        let selectedUri = photoSelectResult.photoUris[0]
        // 复制图片到沙箱目录并更新头像
        return await this.copyImageToSandbox(selectedUri)
      }
      return null
    } catch (error) {
      let err: BusinessError = error as BusinessError
      Logger.error(`PhotoViewPicker failed with err: ${err.code}, ${err.message}`)
      return null
    }
  }

  // 复制图片到沙箱目录（图片 IO 已下沉至 service/ImageFileService，P3）
  private async copyImageToSandbox(sourceUri: string): Promise<string | null> {
    if (!this.context) {
      Logger.error('上下文为空，无法复制图片')
      return null
    }

    const avatarUri = await ImageFileService.copyAvatar(this.context, sourceUri)
    if (avatarUri) {
      // 保存头像路径到配置（统一存储）
      await this.saveAvatarPath(avatarUri)
    }
    return avatarUri
  }

  // 保存头像路径到ConfigManager（统一存储）
  private async saveAvatarPath(avatarPath: string): Promise<void> {
    try {
      if (!this.configManager) {
        Logger.error('配置管理器未初始化，无法保存头像')
        return
      }

      // 获取当前配置
      const config = this.configManager.getConfig()
      
      // 更新头像路径并保存
      const success = await this.configManager.updateProfile(
        config.profile.name,
        config.profile.birthDate,
        config.profile.gender,
        avatarPath
      )

      if (success) {
        Logger.info('头像路径保存成功: ' + avatarPath)
      } else {
        Logger.error('头像路径保存失败')
      }
    } catch (error) {
      Logger.error('保存头像路径失败: ' + JSON.stringify(error))
    }
  }

  // 保存用户资料
  async saveProfile(name: string, birthday: string, gender: string, avatarPath: string, signature: string): Promise<boolean> {
    if (!this.configManager) {
      Logger.error('配置管理器未初始化')
      return false
    }

    try {
      // 转换性别格式
      const genderStorage = AccountUtils.convertGenderToStorage(gender, this.getRm())

      // 保存到配置管理器（签名可选字段，更新计划一期）
      const success = await this.configManager.updateProfile(name, birthday, genderStorage, avatarPath, signature)

      if (success) {
        Logger.info('用户资料保存成功')
        return true
      } else {
        Logger.error('用户资料保存失败')
        return false
      }
    } catch (error) {
      Logger.error('保存用户资料异常: ' + JSON.stringify(error))
      return false
    }
  }

  // 获取配置管理器
  getConfigManager(): ConfigManager | null {
    return this.configManager
  }

  // 获取字体大小设置（更新计划一期）
  getFontSize(): string {
    if (!this.configManager) {
      return 'medium'
    }
    return this.configManager.getFontSize()
  }

  // 设置字体大小（持久化 + AppStorage fontScale）
  async setFontSize(fontSize: string): Promise<boolean> {
    if (!this.configManager) {
      return false
    }
    return await this.configManager.setFontSize(fontSize)
  }

  // 获取上下文
  getContext(): common.UIAbilityContext | null {
    return this.context
  }
}
