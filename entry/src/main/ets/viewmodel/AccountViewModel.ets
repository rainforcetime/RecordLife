// 账号页面业务逻辑类：viewmodel/AccountViewModel.ets
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, fileUri, storageStatistics } from '@kit.CoreFileKit'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { ConfigManager } from '../config/ConfigManager'
import { AppInfo } from '../config/UserConfig'
import { ThemeManager } from '../config/ThemeManager'
import { AccountUtils } from '../common/utils/AccountUtils'
import { TimeUtils } from '../config/TimeUtils'

const AVATAR_PREFERENCES_KEY = 'user_avatar_path'

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
export interface AvatarInfo {
  avatar: string
  hasCustomAvatar: boolean
}

// 账号页面状态管理类
export class AccountViewModel {
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private themeManager: ThemeManager = ThemeManager.getInstance()

  // 初始化配置管理器
  async initialize(context: common.UIAbilityContext): Promise<void> {
    try {
      this.context = context
      console.info('AccountViewModel: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      this.configManager = await ConfigManager.getInstance()
      console.info('AccountViewModel: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
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

  // 加载应用信息
  async loadAppInfo(): Promise<AppInfo> {
    const defaultAppInfo: AppInfo = {
      appName: '记录生活',
      appVersion: '2.1.0',
      buildNumber: '20260521',
      developer: 'RecordLife Team',
      website: 'https://github.com/recordlife',
      description: '记录生活中的每一个精彩瞬间'
    }

    if (!this.configManager) {
      return defaultAppInfo
    }

    try {
      const config = this.configManager.getConfig()
      if (config.appInfo) {
        return config.appInfo
      }
      return defaultAppInfo
    } catch (error) {
      console.error('加载应用信息失败: ' + JSON.stringify(error))
      return defaultAppInfo
    }
  }

  // 加载数据统计信息
  async loadDataStatistics(): Promise<DataStatistics> {
    const defaultStatistics: DataStatistics = {
      usageDays: 0,
      dataVersion: 'v1.0.0',
      lastActiveTime: '',
      storageSize: '计算中...'
    }

    if (!this.configManager) {
      return defaultStatistics
    }

    try {
      const config = this.configManager.getConfig()
      
      // 计算使用天数（从配置创建时间开始）
      const createdAt = new Date(config.metadata.createdAt)
      const now = TimeUtils.now()
      const daysDiff = Math.floor((now.getTime() - createdAt.getTime()) / (1000 * 60 * 60 * 24))
      
      // 格式化最后活跃时间
      const lastActiveDate = new Date(config.statistics.lastActiveTime)
      const lastActiveTime = this.formatDateTime(lastActiveDate)
      
      // 获取应用存储空间大小
      const storageSize = await this.getAppStorageSize()
      
      return {
        usageDays: daysDiff >= 0 ? daysDiff : 0,
        dataVersion: `v${config.appInfo.appVersion}`,
        lastActiveTime: lastActiveTime,
        storageSize: storageSize
      }
    } catch (error) {
      console.error('加载数据统计失败: ' + JSON.stringify(error))
      return defaultStatistics
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
    try {
      const bundleStats = await storageStatistics.getCurrentBundleStats()
      // 计算总大小：appSize + cacheSize + dataSize
      const totalSize = bundleStats.appSize + bundleStats.cacheSize + bundleStats.dataSize
      return this.formatStorageSize(totalSize)
    } catch (error) {
      console.error('获取应用存储空间失败: ' + JSON.stringify(error))
      return '计算中...'
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

  // 加载保存的头像
  async loadSavedAvatar(): Promise<AvatarInfo> {
    try {
      if (!this.context) {
        return { avatar: '', hasCustomAvatar: false }
      }

      // 获取首选项实例
      let dataPreferences = await preferences.getPreferences(this.context, 'user_settings')
      // 读取保存的头像路径（可能是URI格式）
      let savedAvatarPath = await dataPreferences.get(AVATAR_PREFERENCES_KEY, '') as string

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
    
    if (!this.configManager) {
      console.error('配置管理器未初始化')
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

      // 保存到配置管理器
      const success = await this.configManager.setTheme(theme)
      console.info('保存主题结果: ' + success)

      if (success) {
        // 应用主题到系统
        await this.applyTheme(theme)

        // 更新 AppStorage
        AppStorage.setOrCreate('currentTheme', theme)

        // 更新主题管理器（触发颜色更新）
        this.themeManager.updateTheme(theme as 'light' | 'dark' | 'auto')

        console.info('主题设置成功: ' + theme)
        return true
      } else {
        console.error('主题保存失败')
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

  // 复制图片到沙箱目录
  private async copyImageToSandbox(sourceUri: string): Promise<string | null> {
    if (!this.context) {
      console.error('上下文为空，无法复制图片')
      return null
    }

    let sourceFile: fileIo.File | null = null
    try {
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

  // 保存头像路径到首选项
  private async saveAvatarPath(avatarPath: string): Promise<void> {
    try {
      if (!this.context) {
        return
      }

      // 获取首选项实例
      let dataPreferences = await preferences.getPreferences(this.context, 'user_settings')
      // 保存头像路径
      await dataPreferences.put(AVATAR_PREFERENCES_KEY, avatarPath)
      // 持久化存储
      await dataPreferences.flush()

      console.info('头像路径保存成功: ' + avatarPath)
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
