// 账号页面业务逻辑类：viewmodel/AccountViewModel.ets
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, fileUri, storageStatistics } from '@kit.CoreFileKit'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { ConfigManager } from '../config/ConfigManager'
import { AppInfo } from '../config/UserConfig'
import { AppInfoManager } from '../config/AppInfoConfig'
import { ThemeManager } from '../config/ThemeManager'
import { AccountUtils } from '../common/utils/AccountUtils'
import { TimeUtils } from '../common/utils/TimeUtils'

// 用户资料数据模型
export interface UserProfile {
  name: string
  birthday: string
  gender: string
  avatar: string
  hasCustomAvatar: boolean
}

// 主题设置数据模型
export interface ThemeSettings {
  currentTheme: string
}

// 数据统计模型
export interface DataStatistics {
  usageDays: number
  dataVersion: string
  lastActiveTime: string
  storageSize: string
}

// 头像信息模型
interface AvatarInfo {
  avatar: string
  hasCustomAvatar: boolean
}

// 账号页面状态管理类
export class AccountViewModel {
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private themeManager: ThemeManager | null = null

  // 初始化配置管理器
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.context = context
      console.info('AccountViewModel: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      this.configManager = await ConfigManager.getInstance()
      console.info('AccountViewModel: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
      
      this.themeManager = await ThemeManager.getInstance()
      console.info('AccountViewModel: themeManager 已初始化 - ' + (this.themeManager ? '成功' : '失败'))
    } catch (error) {
      console.error('AccountViewModel 初始化失败: ' + JSON.stringify(error))
    }
  }

  // 加载用户资料
  async loadUserProfile(): Promise<UserProfile> {
    const defaultProfile: UserProfile = {
      name: '张三',
      birthday: '1990-01-15',
      gender: '男',
      avatar: '',
      hasCustomAvatar: false
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
        defaultProfile.gender = AccountUtils.convertGenderToDisplay(profile.gender)
      }

      console.info('用户资料加载成功')
      return defaultProfile
    } catch (error) {
      console.error('加载用户资料失败: ' + JSON.stringify(error))
      return defaultProfile
    }
  }

  // 加载主题设置
  async loadThemeSettings(): Promise<ThemeSettings> {
    if (!this.configManager) {
      return { currentTheme: '跟随系统' }
    }

    try {
      const config = this.configManager.getConfig()
      const theme = config.settings.theme
      const currentTheme = AccountUtils.themeToDisplay(theme)
      return { currentTheme }
    } catch (error) {
      console.error('加载主题设置失败: ' + JSON.stringify(error))
      return { currentTheme: '跟随系统' }
    }
  }

  // 加载应用信息（从AppInfoManager获取）
  async loadAppInfo(): Promise<AppInfo> {
    // 默认应用信息（作为备用）
    const defaultAppInfo: AppInfo = {
      appName: '活着',
      appVersion: '0.0.1',
      buildNumber: '20260521',
      developer: 'rainforcetime',
      website: 'https://github.com/rainforcetime/RecordLife',
      description: '记录生活，珍惜每一刻'
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
      console.error('从AppInfoManager加载应用信息失败: ' + JSON.stringify(error));
      return defaultAppInfo;
    }
  }

  // 加载数据统计信息
  async loadDataStatistics(): Promise<DataStatistics> {
    console.info('[StorageDebug] loadDataStatistics 开始执行')
    
    const defaultStatistics: DataStatistics = {
      usageDays: 0,
      dataVersion: 'v0.0.1',
      lastActiveTime: '',
      storageSize: '计算中...'
    }

    try {
      // 优先从AppInfoManager获取最新版本信息
      let appVersion = '0.0.1';
      try {
        const appInfoManager = await AppInfoManager.getInstance();
        appVersion = appInfoManager.getAppVersion();
      } catch (error) {
        console.error('从AppInfoManager获取版本失败: ' + JSON.stringify(error));
      }

      if (!this.configManager) {
        console.warn('[StorageDebug] configManager 未初始化')
        return {
          usageDays: 0,
          dataVersion: `v${appVersion}`,
          lastActiveTime: '',
          storageSize: '计算中...'
        };
      }

      const config = this.configManager.getConfig();
      
      // 计算使用天数（使用日期边界计算，符合用户直觉）
      // 例如：1月1日23:00创建，1月2日01:00查看，应显示1天
      const createdAt = new Date(config.metadata.createdAt);
      const now = TimeUtils.now();
      const startDate = TimeUtils.formatDate(createdAt);  // "YYYY-MM-DD" UTC+8
      const endDate = TimeUtils.formatDate(now);          // "YYYY-MM-DD" UTC+8
      const startDateTime = TimeUtils.parseDate(startDate);
      const endDateTime = TimeUtils.parseDate(endDate);
      const daysDiff = Math.floor((endDateTime.getTime() - startDateTime.getTime()) / (1000 * 60 * 60 * 24));
      
      // 格式化最后活跃时间
      const lastActiveDate = new Date(config.statistics.lastActiveTime);
      const lastActiveTime = this.formatDateTime(lastActiveDate);
      
      // 获取应用存储空间大小
      console.info('[StorageDebug] 准备调用 getAppStorageSize()')
      const storageSize = await this.getAppStorageSize();
      console.info('[StorageDebug] getAppStorageSize() 返回: ' + storageSize)
      
      const result: DataStatistics = {
        usageDays: daysDiff >= 0 ? daysDiff : 0,
        dataVersion: `v${appVersion}`,
        lastActiveTime: lastActiveTime,
        storageSize: storageSize
      };
      
      console.info('[StorageDebug] loadDataStatistics 完成: ' + JSON.stringify(result))
      return result;
    } catch (error) {
      console.error('[StorageDebug] 加载数据统计失败: ' + JSON.stringify(error));
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

  // 获取应用存储空间大小
  private async getAppStorageSize(): Promise<string> {
    console.info('[StorageDebug] 开始获取应用存储空间')
    
    try {
      console.info('[StorageDebug] 调用 storageStatistics.getCurrentBundleStats()')
      const bundleStats = await storageStatistics.getCurrentBundleStats()
      
      console.info('[StorageDebug] 获取成功，详细信息:')
      console.info('[StorageDebug] - appSize: ' + bundleStats.appSize + ' bytes')
      console.info('[StorageDebug] - cacheSize: ' + bundleStats.cacheSize + ' bytes')
      console.info('[StorageDebug] - dataSize: ' + bundleStats.dataSize + ' bytes')
      
      // 计算总大小：appSize + cacheSize + dataSize
      const totalSize = bundleStats.appSize + bundleStats.cacheSize + bundleStats.dataSize
      console.info('[StorageDebug] - totalSize: ' + totalSize + ' bytes')
      
      const formattedSize = this.formatStorageSize(totalSize)
      console.info('[StorageDebug] 格式化结果: ' + formattedSize)
      
      return formattedSize
    } catch (error) {
      console.error('[StorageDebug] 获取应用存储空间失败')
      console.error('[StorageDebug] 错误类型: ' + typeof error)
      console.error('[StorageDebug] 错误详情: ' + JSON.stringify(error))
      
      if (error instanceof Error) {
        console.error('[StorageDebug] 错误消息: ' + error.message)
        console.error('[StorageDebug] 错误堆栈: ' + error.stack)
      }
      
      return '计算失败'
    }
  }

  // 格式化存储大小
  private formatStorageSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes}B`
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(1)}KB`
    } else if (bytes < 1024 * 1024 * 1024) {
      return `${(bytes / (1024 * 1024)).toFixed(1)}MB`
    } else {
      return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)}GB`
    }
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
          console.info('加载保存的头像URI成功: ' + savedAvatarPath)
          return { avatar: savedAvatarPath, hasCustomAvatar: true }
        } else {
          // 如果是旧的沙箱路径格式，转换为URI
          if (fileIo.accessSync(savedAvatarPath)) {
            let avatarUri = fileUri.getUriFromPath(savedAvatarPath)
            console.info('加载保存的头像并转换为URI成功: ' + avatarUri)
            return { avatar: avatarUri, hasCustomAvatar: true }
          }
        }
      }
      
      // 没有保存的头像，使用默认头像
      return { avatar: '', hasCustomAvatar: false }
    } catch (error) {
      console.error('加载保存的头像失败: ' + JSON.stringify(error))
      return { avatar: '', hasCustomAvatar: false }
    }
  }

  // 主题切换处理
  async onThemeChange(value: string): Promise<boolean> {
    console.info('开始切换主题: ' + value)
    
    if (!this.themeManager) {
      console.error('主题管理器未初始化')
      return false
    }
    
    if (!this.context) {
      console.error('上下文未初始化')
      return false
    }

    try {
      // 转换为存储格式
      const theme = AccountUtils.displayToTheme(value)
      console.info('转换后的主题: ' + theme)

      // 通过ThemeManager更新主题（会自动保存到ConfigManager并更新AppStorage）
      const success = await this.themeManager.updateTheme(theme as 'light' | 'dark' | 'auto')
      console.info('更新主题结果: ' + success)

      if (success) {
        // 应用主题到系统
        await this.applyTheme(theme)

        // 更新 AppStorage（供页面监听）
        AppStorage.setOrCreate('currentTheme', theme)

        console.info('主题设置成功: ' + theme)
        return true
      } else {
        console.error('主题更新失败')
        return false
      }
    } catch (error) {
      console.error('主题切换异常: ' + JSON.stringify(error))
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

      console.info('主题已应用: ' + theme)
    } catch (error) {
      console.error('应用主题失败: ' + JSON.stringify(error))
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
      console.info('PhotoViewPicker.select successfully, photoSelectResult: ' + JSON.stringify(photoSelectResult))

      // 获取选中的图片URI数组
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        let selectedUri = photoSelectResult.photoUris[0]
        // 复制图片到沙箱目录并更新头像
        return await this.copyImageToSandbox(selectedUri)
      }
      return null
    } catch (error) {
      let err: BusinessError = error as BusinessError
      console.error(`PhotoViewPicker failed with err: ${err.code}, ${err.message}`)
      return null
    }
  }

  // 删除旧的头像缓存文件
  private deleteOldAvatarCache(): void {
    if (!this.context) {
      return
    }
    try {
      const filesDir = this.context.filesDir
      // 列出目录下的所有文件（返回的是文件名数组，不是完整路径）
      const fileNames = fileIo.listFileSync(filesDir)
      for (const fileName of fileNames) {
        // 删除以 avatar 开头的文件
        if (fileName.startsWith('avatar')) {
          const filePath = `${filesDir}/${fileName}`
          try {
            fileIo.unlinkSync(filePath)
            console.info('删除旧头像缓存: ' + filePath)
          } catch (e) {
            console.error('删除旧头像缓存失败: ' + filePath + ', 错误: ' + JSON.stringify(e))
          }
        }
      }
    } catch (error) {
      console.error('列出头像目录失败: ' + JSON.stringify(error))
    }
  }

  // 复制图片到沙箱目录
  private async copyImageToSandbox(sourceUri: string): Promise<string | null> {
    if (!this.context) {
      console.error('上下文为空，无法复制图片')
      return null
    }

    let sourceFile: fileIo.File | null = null
    try {
      // 删除旧的头像缓存文件
      this.deleteOldAvatarCache()

      // 打开源图片文件
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)

      // 生成新的文件名（使用时间戳避免重复）
      let timestamp = Date.now()
      let fileName = `avatar_${timestamp}.jpg`
      // 沙箱目录路径
      let sandboxPath = `${this.context.filesDir}/${fileName}`

      // 使用同步方法复制文件到沙箱目录
      fileIo.copyFileSync(sourceFile.fd, sandboxPath)

      console.info('图片复制成功，沙箱路径: ' + sandboxPath)

      // 将沙箱路径转换为URI（Image组件需要URI格式）
      let avatarUri = fileUri.getUriFromPath(sandboxPath)
      console.info('头像URI: ' + avatarUri)

      // 保存头像路径到首选项（保存URI）
      await this.saveAvatarPath(avatarUri)

      return avatarUri
    } catch (error) {
      console.error('复制图片失败: ' + JSON.stringify(error))
      return null
    } finally {
      // 关闭源文件
      if (sourceFile) {
        try {
          fileIo.closeSync(sourceFile)
        } catch (closeError) {
          console.error('关闭文件失败: ' + JSON.stringify(closeError))
        }
      }
    }
  }

  // 保存头像路径到ConfigManager（统一存储）
  private async saveAvatarPath(avatarPath: string): Promise<void> {
    try {
      if (!this.configManager) {
        console.error('配置管理器未初始化，无法保存头像')
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
        console.info('头像路径保存成功: ' + avatarPath)
      } else {
        console.error('头像路径保存失败')
      }
    } catch (error) {
      console.error('保存头像路径失败: ' + JSON.stringify(error))
    }
  }

  // 保存用户资料
  async saveProfile(name: string, birthday: string, gender: string, avatarPath: string): Promise<boolean> {
    if (!this.configManager) {
      console.error('配置管理器未初始化')
      return false
    }

    try {
      // 转换性别格式
      const genderStorage = AccountUtils.convertGenderToStorage(gender)

      // 保存到配置管理器
      const success = await this.configManager.updateProfile(name, birthday, genderStorage, avatarPath)

      if (success) {
        console.info('用户资料保存成功')
        return true
      } else {
        console.error('用户资料保存失败')
        return false
      }
    } catch (error) {
      console.error('保存用户资料异常: ' + JSON.stringify(error))
      return false
    }
  }

  // 获取配置管理器
  getConfigManager(): ConfigManager | null {
    return this.configManager
  }

  // 获取上下文
  getContext(): common.UIAbilityContext | null {
    return this.context
  }
}
