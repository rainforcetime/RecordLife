// 账号设置页面：pages/AccountPage.ets
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { common, ConfigurationConstant } from '@kit.AbilityKit'
import { preferences } from '@kit.ArkData'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { ConfigManager } from '../config/ConfigManager'
import { AppInfo } from '../config/UserConfig'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { ThemeManager } from '../config/ThemeManager'
import { SettingItem } from '../components/SettingItem'
import { SettingItemWithToggle } from '../components/SettingItemWithToggle'
import { SettingItemWithSelector } from '../components/SettingItemWithSelector'
import { SettingItemWithAction } from '../components/SettingItemWithAction'
import { SettingItemWithInfo } from '../components/SettingItemWithInfo'
import { EditProfileDialog } from '../components/EditProfileDialog'
import { AboutAppDialog } from '../components/AboutAppDialog'

const AVATAR_PREFERENCES_KEY = 'user_avatar_path'

@Component
export struct AccountPage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 用户信息状态
  @State userAvatar: string | Resource = $r('app.media.user_avatar')
  @State userName: string = '张三'
  @State userBirthday: string = '1990-01-15'
  @State userGender: string = '男'
  @State isEditing: boolean = false
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()
  private themeManager: ThemeManager = ThemeManager.getInstance()

  // 设置项状态
  @State autoBackupEnabled: boolean = false
  @State currentTheme: string = '跟随系统'

  // 数据统计
  @State usageDays: number = 128
  @State dataVersion: string = 'v2.1.0'
  @State lastActiveTime: string = '2026-05-20 14:30'

  // 应用信息
  @State appInfo: AppInfo = {
    appName: '记录生活',
    appVersion: '2.1.0',
    buildNumber: '20260521',
    developer: 'RecordLife Team',
    website: 'https://github.com/recordlife',
    description: '记录生活中的每一个精彩瞬间'
  }

  // 编辑资料弹窗控制器
  private editProfileDialog: CustomDialogController = new CustomDialogController({
    builder: EditProfileDialog({
      userName: this.userName,
      userBirthday: this.userBirthday,
      userGender: this.userGender,
      onSave: (name: string, birthday: string, gender: string) => {
        this.onSaveProfile(name, birthday, gender)
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  // 关于应用弹窗控制器
  private aboutAppDialog: CustomDialogController = new CustomDialogController({
    builder: AboutAppDialog({
      appInfo: this.appInfo
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      console.info('AccountPage: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      // 初始化配置管理器
      this.configManager = await ConfigManager.getInstance()
      console.info('AccountPage: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
      
      // 加载用户配置
      await this.loadUserProfile()
      
      // 加载保存的头像
      await this.loadSavedAvatar()
    } catch (error) {
      console.error('AccountPage 初始化失败: ' + JSON.stringify(error))
    }
  }

  // 加载用户配置
  private async loadUserProfile() {
    if (!this.configManager) {
      return
    }

    try {
      const config = this.configManager.getConfig()
      const profile = config.profile

      // 加载用户名
      if (profile.name && profile.name.length > 0) {
        this.userName = profile.name
      }

      // 加载出生日期
      if (profile.birthDate && profile.birthDate.length > 0) {
        this.userBirthday = profile.birthDate
      }

      // 加载性别
      if (profile.gender && profile.gender.length > 0) {
        this.userGender = this.convertGenderToDisplay(profile.gender)
      }

      // 加载应用信息
      if (config.appInfo) {
        this.appInfo = config.appInfo
        this.dataVersion = `v${config.appInfo.appVersion}`
      }

      // 加载主题设置
      const theme = config.settings.theme
      this.currentTheme = this.themeToDisplay(theme)

      console.info('用户配置加载成功')
    } catch (error) {
      console.error('加载用户配置失败: ' + JSON.stringify(error))
    }
  }

  // 主题格式转换：存储格式转显示格式
  private themeToDisplay(theme: string): string {
    switch (theme) {
      case 'light':
        return '浅色模式'
      case 'dark':
        return '深色模式'
      case 'auto':
      default:
        return '跟随系统'
    }
  }

  // 主题格式转换：显示格式转存储格式
  private displayToTheme(display: string): string {
    switch (display) {
      case '浅色模式':
        return 'light'
      case '深色模式':
        return 'dark'
      case '跟随系统':
      default:
        return 'auto'
    }
  }

  // 主题切换处理
  private async onThemeChange(value: string) {
    console.info('开始切换主题: ' + value)
    console.info('configManager: ' + (this.configManager ? '已初始化' : '未初始化'))
    console.info('context: ' + (this.context ? '已初始化' : '未初始化'))
    
    if (!this.configManager) {
      this.showToastSafely('配置管理器未初始化')
      console.error('配置管理器未初始化')
      return
    }
    
    if (!this.context) {
      this.showToastSafely('上下文未初始化')
      console.error('上下文未初始化')
      return
    }

    try {
      // 更新UI显示
      this.currentTheme = value

      // 转换为存储格式
      const theme = this.displayToTheme(value)
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

        // 显示成功提示
        this.showToastSafely('主题设置已保存')

        console.info('主题设置成功: ' + theme)
      } else {
        this.showToastSafely('主题保存失败，请重试')
        console.error('主题保存失败')
      }
    } catch (error) {
      console.error('主题切换异常: ' + JSON.stringify(error))
      this.showToastSafely('主题设置失败: ' + (error as Error).message)
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

  // 安全显示 Toast 提示
  private showToastSafely(message: string, duration: number = 2000) {
    try {
      this.promptAction.showToast({
        message: message,
        duration: duration
      })
    } catch (error) {
      console.error('显示 Toast 失败: ' + JSON.stringify(error))
    }
  }

  // 性别转换：存储格式转显示格式
  private convertGenderToDisplay(gender: string): string {
    switch (gender) {
      case 'male':
        return '男'
      case 'female':
        return '女'
      case 'other':
        return '其他'
      default:
        return '男'
    }
  }

  // 性别转换：显示格式转存储格式
  private convertGenderToStorage(gender: string): string {
    switch (gender) {
      case '男':
        return 'male'
      case '女':
        return 'female'
      case '其他':
        return 'other'
      default:
        return ''
    }
  }

  // 加载保存的头像
  private async loadSavedAvatar() {
    try {
      if (!this.context) {
        return
      }

      // 获取首选项实例
      let dataPreferences = await preferences.getPreferences(this.context, 'user_settings')
      // 读取保存的头像路径（可能是URI格式）
      let savedAvatarPath = await dataPreferences.get(AVATAR_PREFERENCES_KEY, '') as string

      if (savedAvatarPath && savedAvatarPath.length > 0) {
        // 如果是URI格式（file://开头），直接使用
        if (savedAvatarPath.startsWith('file://')) {
          this.userAvatar = savedAvatarPath
          console.info('加载保存的头像URI成功: ' + savedAvatarPath)
        } else {
          // 如果是旧的沙箱路径格式，转换为URI
          if (fileIo.accessSync(savedAvatarPath)) {
            let avatarUri = fileUri.getUriFromPath(savedAvatarPath)
            this.userAvatar = avatarUri
            console.info('加载保存的头像并转换为URI成功: ' + avatarUri)
          }
        }
      }
    } catch (error) {
      console.error('加载保存的头像失败: ' + JSON.stringify(error))
    }
  }

  build() {
    Scroll() {
      Column() {
        // 页面标题
        Text('账号设置')
          .fontSize(25)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ top: 20, bottom: 20 })

        // 用户信息区域
        this.UserInfoSection()

        // 分隔线
        Divider()
          .color(this.themeColors.divider)
          .margin({ top: 10, bottom: 10 })

        // 设置项列表
        this.SettingsSection()

        // 分隔线
        Divider()
          .color(this.themeColors.divider)
          .margin({ top: 10, bottom: 10 })

        // 数据统计区域
        this.DataStatisticsSection()

        // 分隔线
        Divider()
          .color(this.themeColors.divider)
          .margin({ top: 10, bottom: 10 })

        // 其他功能区域
        this.OtherFunctionsSection()
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }

  // 用户信息区域组件
  @Builder
  UserInfoSection() {
    Column() {
      // 头像展示（可点击更换）
      if (typeof this.userAvatar === 'string') {
        // 显示沙箱路径的图片
        Image(this.userAvatar as string)
          .width(80)
          .height(80)
          .borderRadius(40)
          .border({ width: 2, color: this.themeColors.avatarBorder })
          .margin({ top: 15, bottom: 10 })
          .onClick(() => {
            // 点击更换头像
            this.onChangeAvatar()
          })
      } else {
        // 显示资源图片（默认头像）
        Image(this.userAvatar as Resource)
          .width(80)
          .height(80)
          .borderRadius(40)
          .border({ width: 2, color: this.themeColors.avatarBorder })
          .margin({ top: 15, bottom: 10 })
          .onClick(() => {
            // 点击更换头像
            this.onChangeAvatar()
          })
      }

      // 用户名
      Text(this.userName)
        .fontSize(20)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textPrimary)
        .margin({ bottom: 5 })

      // 出生日期和性别
      Row() {
        Text(`出生日期: ${this.userBirthday}`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
        Text('  |  ')
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
        Text(`性别: ${this.userGender}`)
          .fontSize(14)
          .fontColor(this.themeColors.textSecondary)
      }
      .margin({ bottom: 15 })

      // 编辑资料按钮
      Button('编辑资料')
        .fontSize(16)
        .backgroundColor(this.themeColors.primary)
        .fontColor(Color.White)
        .borderRadius(20)
        .width(120)
        .height(40)
        .onClick(() => {
          this.onEditProfile()
        })
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(10)
    .margin({ left: 15, right: 15 })
    .padding(15)
  }

  // 设置项列表组件
  @Builder
  SettingsSection() {
    Column() {
      // 主题设置（选择器）
      SettingItemWithSelector({
        label: '主题设置',
        currentValue: this.currentTheme,
        options: ['跟随系统', '浅色模式', '深色模式'],
        onSelect: (value: string) => {
          this.onThemeChange(value)
        }
      })

      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })

      // 自动备份设置（开关）
      SettingItemWithToggle({
        label: '自动备份',
        summary: '每日自动备份数据',
        isEnabled: this.autoBackupEnabled,
        onToggle: (value: boolean) => {
          this.autoBackupEnabled = value
        }
      })

      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })

      // 关于应用（信息展示）
      SettingItemWithInfo({
        label: '关于应用',
        info: `版本 ${this.appInfo.appVersion}`
      })
      .onClick(() => {
        this.onAboutApp()
      })
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(10)
    .margin({ left: 15, right: 15 })
  }

  // 数据统计区域组件
  @Builder
  DataStatisticsSection() {
    Column() {
      Text('数据统计')
        .fontSize(18)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.themeColors.textPrimary)
        .margin({ top: 10, bottom: 10 })
        .width('100%')
        .padding({ left: 15 })

      Row() {
        // 使用天数
        Column() {
          Text(this.usageDays.toString())
            .fontSize(24)
            .fontColor(this.themeColors.primary)
            .fontWeight(FontWeight.Bold)
          Text('使用天数')
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 5 })
        }
        .layoutWeight(1)

        // 数据版本
        Column() {
          Text(this.dataVersion)
            .fontSize(24)
            .fontColor(this.themeColors.primary)
            .fontWeight(FontWeight.Bold)
          Text('数据版本')
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 5 })
        }
        .layoutWeight(1)

        // 最后活跃时间
        Column() {
          Text('今天')
            .fontSize(24)
            .fontColor(this.themeColors.primary)
            .fontWeight(FontWeight.Bold)
          Text('最后活跃')
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
            .margin({ top: 5 })
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding({ left: 15, right: 15, bottom: 15 })
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(10)
    .margin({ left: 15, right: 15 })
  }

  // 其他功能区域组件
  @Builder
  OtherFunctionsSection() {
    Column() {
      // 导出配置
      SettingItemWithAction({
        label: '导出配置',
        summary: '导出应用配置文件',
        onAction: () => {
          this.onExportConfig()
        }
      })

      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })

      // 导入配置
      SettingItemWithAction({
        label: '导入配置',
        summary: '从文件导入配置',
        onAction: () => {
          this.onImportConfig()
        }
      })

      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })

      // 重置应用
      SettingItemWithAction({
        label: '重置应用',
        summary: '恢复默认设置',
        isDestructive: true,
        onAction: () => {
          this.onResetApp()
        }
      })
    }
    .width('100%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(10)
    .margin({ left: 15, right: 15 })
  }

  // 头像更换处理
  private async onChangeAvatar() {
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
      photoPicker.select(photoSelectOptions).then(async (photoSelectResult: photoAccessHelper.PhotoSelectResult) => {
        console.info('PhotoViewPicker.select successfully, photoSelectResult: ' + JSON.stringify(photoSelectResult))

        // 获取选中的图片URI数组
        if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
          let selectedUri = photoSelectResult.photoUris[0]
          // 复制图片到沙箱目录并更新头像
          await this.copyImageToSandbox(selectedUri)
        }
      }).catch((err: BusinessError) => {
        console.error(`PhotoViewPicker.select failed with err: ${err.code}, ${err.message}`)
      })
    } catch (error) {
      let err: BusinessError = error as BusinessError
      console.error(`PhotoViewPicker failed with err: ${err.code}, ${err.message}`)
    }
  }

  // 复制图片到沙箱目录
  private async copyImageToSandbox(sourceUri: string) {
    if (!this.context) {
      console.error('上下文为空，无法复制图片')
      return
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

      // 更新头像显示
      this.userAvatar = avatarUri

      // 保存头像路径到首选项（保存URI）
      await this.saveAvatarPath(avatarUri)

    } catch (error) {
      console.error('复制图片失败: ' + JSON.stringify(error))
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
  private async saveAvatarPath(avatarPath: string) {
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

  // 编辑资料处理
  private onEditProfile() {
    console.log('编辑资料')
    // 显示编辑资料弹窗
    this.editProfileDialog.open()
  }

  // 保存用户资料
  private async onSaveProfile(name: string, birthday: string, gender: string) {
    if (!this.configManager) {
      console.error('配置管理器未初始化')
      return
    }

    try {
      // 转换性别格式
      const genderStorage = this.convertGenderToStorage(gender)
      const avatarPath = typeof this.userAvatar === 'string' ? this.userAvatar : ''

      // 保存到配置管理器
      const success = await this.configManager.updateProfile(name, birthday, genderStorage, avatarPath)

      if (success) {
        // 更新UI显示
        this.userName = name
        this.userBirthday = birthday
        this.userGender = gender

        console.info('用户资料保存成功')

        // 显示成功提示
        this.promptAction.showToast({
          message: '保存成功',
          duration: 2000
        })
      } else {
        console.error('用户资料保存失败')
        this.promptAction.showToast({
          message: '保存失败',
          duration: 2000
        })
      }
    } catch (error) {
      console.error('保存用户资料异常: ' + JSON.stringify(error))
      this.promptAction.showToast({
        message: '保存失败',
        duration: 2000
      })
    }
  }

  // 导出配置处理
  private onExportConfig() {
    console.log('导出配置')
    // TODO: 实现配置导出逻辑
    this.getUIContext().showAlertDialog({
      title: '导出配置',
      message: '配置已导出到: /Documents/RecordLife/config.json',
      confirm: {
        value: '确定',
        action: () => {}
      }
    })
  }

  // 导入配置处理
  private onImportConfig() {
    console.log('导入配置')
    // TODO: 实现配置导入逻辑
    this.getUIContext().showAlertDialog({
      title: '导入配置',
      message: '请选择配置文件',
      confirm: {
        value: '确定',
        action: () => {}
      }
    })
  }

  // 重置应用处理
  private onResetApp() {
    this.getUIContext().showAlertDialog({
      title: '重置应用',
      message: '确定要重置应用吗？此操作不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {}
      },
      secondaryButton: {
        value: '确定',
        action: () => {
          console.log('重置应用')
          // TODO: 实现应用重置逻辑
        }
      }
    })
  }

  // 关于应用处理
  private onAboutApp() {
    console.log('关于应用')
    this.aboutAppDialog.open()
  }
}

