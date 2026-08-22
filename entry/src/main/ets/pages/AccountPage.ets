// 账号设置页面：pages/AccountPage.ets
import { common } from '@kit.AbilityKit'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItem } from '../components/setting/SettingItem'
import { SettingItemWithSelector } from '../components/setting/SettingItemWithSelector'
import { SettingItemWithInfo } from '../components/setting/SettingItemWithInfo'
import { EditProfileDialog } from '../components/dialog/EditProfileDialog'
import { AboutAppDialog } from '../components/dialog/AboutAppDialog'
import { TagManagementDialog } from '../components/dialog/TagManagementDialog'
import { UserInfoSection, UserInfo } from '../components/user/UserInfoSection'
import { AccountViewModel, AccountDataStatistics } from '../viewmodel/AccountViewModel'
import { AccountUtils } from '../common/utils/AccountUtils'
import { AppInfo } from '../config/UserConfig'
import { RefreshManager } from '../common/managers/RefreshManager'
import { Logger } from '../common/utils/Logger'

@Component
export struct AccountPage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 用户信息状态
  @State userInfo: UserInfo = {
    userName: '',
    userBirthday: '1990-01-15',
    userGender: '',
    userAvatar: '',
    hasCustomAvatar: false,
    userSignature: ''
  }
  
  // 设置项状态
  @State currentTheme: string = ''
  @State currentFontSize: string = 'medium'  // 字体大小（更新计划一期）
  
  // 数据统计
  @State statisticsInfo: AccountDataStatistics = {
    usageDays: 0,
    dataVersion: 'v0.0.1',  // 初始值，会在loadAppInfo时更新为实际版本
    lastActiveTime: '',
    storageSize: ''
  }
  
  // 应用信息
  @State appInfo: AppInfo = {
    appName: '',
    appVersion: '0.0.1',
    buildNumber: '20260521',
    developer: 'rainforcetime',
    website: 'https://github.com/rainforcetime/RecordLife',
    description: ''
  }
  
  // 业务逻辑
  private viewModel: AccountViewModel = new AccountViewModel()
  private context: common.UIAbilityContext | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()
  
  // 标记是否首次显示（避免 aboutToAppear 和 onPageShow 双重加载）
  private isFirstShow: boolean = true
  
  // 标记后台是否已通过 RefreshManager 刷新过数据
  private hasBackgroundRefresh: boolean = false
  
  // 编辑资料弹窗控制器
  private editProfileDialog: CustomDialogController = new CustomDialogController({
    builder: EditProfileDialog({
      userName: this.userInfo.userName,
      userBirthday: this.userInfo.userBirthday,
      userGender: this.userInfo.userGender,
      userSignature: this.userInfo.userSignature,
      themeColors: this.themeColors,
      onSave: (name: string, birthday: string, gender: string, signature: string) => {
        this.onSaveProfile(name, birthday, gender, signature)
      }
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })
  
  // 关于应用弹窗控制器
  private aboutAppDialog: CustomDialogController = new CustomDialogController({
    builder: AboutAppDialog({
      appInfo: this.appInfo,
      themeColors: this.themeColors,
      usageDays: this.statisticsInfo.usageDays
    }),
    autoCancel: true,
    alignment: DialogAlignment.Center,
    customStyle: true
  })

  // 标签管理弹窗控制器
  private tagManagementDialogController: CustomDialogController = new CustomDialogController({
    builder: TagManagementDialog({}),
    autoCancel: true,
    customStyle: true,
    maskColor: 'rgba(0, 0, 0, 0.5)'
  })
  
  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      
      // 初始化业务逻辑
      await this.viewModel.initialize(this.context)
      
      // 加载用户资料
      await this.loadUserProfile()
      
      // 加载主题设置
      await this.loadThemeSettings()
      
      // 加载字体大小设置（更新计划一期）
      this.currentFontSize = this.viewModel.getFontSize()
      
      // 加载应用信息
      await this.loadAppInfo()
      
      // 加载保存的头像
      await this.loadSavedAvatar()
      
      // 加载数据统计信息
      await this.loadDataStatistics()
      
      // 注册全局刷新回调
      RefreshManager.getInstance().register('AccountPage', () => {
        Logger.info('[AccountPage] 收到全局刷新通知')
        this.hasBackgroundRefresh = true
        this.loadDataStatistics()
      })
    } catch (error) {
      Logger.error('AccountPage 初始化失败: ' + JSON.stringify(error))
    }
  }
  
  // 页面销毁时注销回调
  aboutToDisappear() {
    Logger.info('[AccountPage] aboutToDisappear')
    // 注销刷新回调
    RefreshManager.getInstance().unregister('AccountPage')
  }
  
  // 页面显示时刷新数据（跳过首次，避免与 aboutToAppear 重复加载；
  // 跳过已在后台通过 RefreshManager 刷新过的情况）
  onPageShow() {
    if (this.isFirstShow) {
      this.isFirstShow = false
      Logger.info('[AccountPage] onPageShow 跳过首次加载（已在 aboutToAppear 中完成）')
      return
    }
    if (this.hasBackgroundRefresh) {
      this.hasBackgroundRefresh = false
      Logger.info('[AccountPage] onPageShow 跳过加载（已在后台通过 RefreshManager 刷新）')
      return
    }
    Logger.info('[AccountPage] onPageShow 刷新统计数据')
    this.loadDataStatistics()
  }
  
  // 加载用户资料
  private async loadUserProfile() {
    const profile = await this.viewModel.loadUserProfile()
    // 必须替换整个对象才能触发子组件 @Prop 更新
    this.userInfo = {
      userName: profile.name,
      userBirthday: profile.birthday,
      userGender: profile.gender,
      userAvatar: this.userInfo.userAvatar,
      hasCustomAvatar: this.userInfo.hasCustomAvatar,
      userSignature: profile.signature
    }
  }
  
  // 加载主题设置
  private async loadThemeSettings() {
    const themeSettings = await this.viewModel.loadThemeSettings()
    this.currentTheme = themeSettings.currentTheme
  }
  
  // 加载应用信息
  private async loadAppInfo() {
    this.appInfo = await this.viewModel.loadAppInfo()
    this.statisticsInfo.dataVersion = `v${this.appInfo.appVersion}`
  }

  // 加载数据统计信息
  private async loadDataStatistics() {
    Logger.info('[AccountPage] 开始加载数据统计')
    const statistics = await this.viewModel.loadDataStatistics()
    Logger.info('[AccountPage] 获取到统计数据: ' + JSON.stringify(statistics))
    
    // 必须重新赋值整个对象才能触发UI更新
    this.statisticsInfo = {
      usageDays: statistics.usageDays,
      dataVersion: statistics.dataVersion,
      lastActiveTime: statistics.lastActiveTime,
      storageSize: statistics.storageSize
    }
    
    Logger.info('[AccountPage] statisticsInfo已更新: ' + JSON.stringify(this.statisticsInfo))
  }
  
  // 加载保存的头像
  private async loadSavedAvatar() {
    const avatarInfo = await this.viewModel.loadSavedAvatar()
    // 必须替换整个对象才能触发子组件 @Prop 更新
    this.userInfo = {
      userName: this.userInfo.userName,
      userBirthday: this.userInfo.userBirthday,
      userGender: this.userInfo.userGender,
      userAvatar: avatarInfo.avatar,
      hasCustomAvatar: avatarInfo.hasCustomAvatar,
      userSignature: this.userInfo.userSignature
    }
  }
  
  // 主题选项（国际化：读资源）
  private getThemeOptions(): string[] {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (!rm) {
      return []
    }
    return [rm.getStringByNameSync('follow_system'), rm.getStringByNameSync('light_mode'), rm.getStringByNameSync('dark_mode')]
  }

  // 主题切换处理
  private async onThemeChange(value: string) {
    this.currentTheme = value
    const success = await this.viewModel.onThemeChange(value)
    
    if (success) {
      AccountUtils.showToastSafely(this.promptAction, $r('app.string.theme_settings_saved'))
    } else {
      AccountUtils.showToastSafely(this.promptAction, $r('app.string.theme_settings_save_failed'))
    }
  }

  // 字体大小选项（国际化：读资源）
  private getFontSizeOptions(): string[] {
    const rm = this.getUIContext().getHostContext()?.resourceManager
    if (!rm) {
      return []
    }
    return [rm.getStringByNameSync('font_size_small'), rm.getStringByNameSync('font_size_medium'), rm.getStringByNameSync('font_size_large')]
  }

  // 字体大小切换处理
  private async onFontSizeChange(value: string) {
    this.currentFontSize = value
    const success = await this.viewModel.setFontSize(value)
    if (success) {
      AccountUtils.showToastSafely(this.promptAction, $r('app.string.font_size_saved'))
      // 通知其他页面刷新（时间线字体缩放）
      RefreshManager.getInstance().refresh()
    } else {
      AccountUtils.showToastSafely(this.promptAction, $r('app.string.font_size_save_failed'))
    }
  }
  
  // 编辑资料处理
  private onEditProfile() {
    Logger.info('编辑资料')
    this.editProfileDialog.open()
  }
  
  // 保存用户资料
  private async onSaveProfile(name: string, birthday: string, gender: string, signature: string) {
    const avatarPath = this.userInfo.hasCustomAvatar ? this.userInfo.userAvatar : ''
    const success = await this.viewModel.saveProfile(name, birthday, gender, avatarPath, signature)
    
    if (success) {
      // 必须替换整个对象才能触发子组件 @Prop 更新
      this.userInfo = {
        userName: name,
        userBirthday: birthday,
        userGender: gender,
        userAvatar: this.userInfo.userAvatar,
        hasCustomAvatar: this.userInfo.hasCustomAvatar,
        userSignature: signature
      }
      
      Logger.info('用户资料保存成功')
      AccountUtils.showToastSafely(this.promptAction, $r('app.string.save_success'))
      
      // 通知其他页面刷新（如 HomePage 的出生日期显示）
      RefreshManager.getInstance().refresh()
    } else {
      Logger.error('用户资料保存失败')
      AccountUtils.showToastSafely(this.promptAction, $r('app.string.save_failed'))
    }
  }
  
  // 头像更换处理
  private async onChangeAvatar() {
    const avatarUri = await this.viewModel.onChangeAvatar()
    if (avatarUri) {
      // 必须替换整个对象才能触发子组件 @Prop 更新
      this.userInfo = {
        userName: this.userInfo.userName,
        userBirthday: this.userInfo.userBirthday,
        userGender: this.userInfo.userGender,
        userAvatar: avatarUri,
        hasCustomAvatar: true
      }
      // 更新存储空间显示
      await this.loadDataStatistics()
    }
  }
  
  // 关于应用处理
  private onAboutApp() {
    Logger.info('关于应用')
    this.aboutAppDialog.open()
  }
  
  // 更多设置处理
  private onMoreSettings() {
    Logger.info('更多设置')
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/MorePage'
      })
    } catch (error) {
      Logger.error('页面跳转失败: ' + JSON.stringify(error))
    }
  }
  
  // 存储空间点击处理
  private onStorageClick() {
    Logger.info('存储空间')
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/StorageImagePage'
      })
    } catch (error) {
      Logger.error('页面跳转失败: ' + JSON.stringify(error))
    }
  }
  
  build() {
    Scroll() {
      Column() {
        // 用户信息区域
        UserInfoSection({
          themeColors: this.themeColors,
          userInfo: this.userInfo,
          onEditProfile: () => {
            this.onEditProfile()
          },
          onChangeAvatar: () => {
            this.onChangeAvatar()
          }
        })
          .margin({ top: 24 })

        // 设置项列表
        this.SettingsSection()

        // 底部留白
        Column()
          .height(24)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
    .align(Alignment.Top)
  }
  
  // 设置项列表组件
  @Builder
  SettingsSection() {
    Column() {
      // 区域标题
      Row() {
        SymbolGlyph($r('sys.symbol.gearshape_fill'))
          .fontSize(18)
          .fontColor([this.themeColors.primary])
          .margin({ right: 8 })
        
        Text($r('app.string.settings'))
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
      }
      .width('100%')
      .padding({ left: 4, bottom: 12 })
      
      // 主题设置（选择器）
      SettingItemWithSelector({
        label: $r('app.string.theme_settings'),
        currentValue: this.currentTheme,
        options: this.getThemeOptions(),
        onSelect: (value: string) => {
          this.onThemeChange(value)
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 字体大小设置（选择器，更新计划一期）
      SettingItemWithSelector({
        label: $r('app.string.font_size_settings'),
        currentValue: this.currentFontSize,
        options: this.getFontSizeOptions(),
        onSelect: (value: string) => {
          this.onFontSizeChange(value)
        }
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 存储空间（信息展示）
      SettingItemWithInfo({
        label: $r('app.string.storage_space'),
        info: this.statisticsInfo.storageSize
      })
      .onClick(() => {
        this.onStorageClick()
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 标签管理
      SettingItem({
        label: $r('app.string.tag_management'),
        summary: $r('app.string.manage_tags')
      })
      .onClick(() => {
        this.tagManagementDialogController.open()
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 更多设置
      SettingItem({
        label: $r('app.string.more'),
        summary: $r('app.string.import_export_config')
      })
      .onClick(() => {
        this.onMoreSettings()
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 关于应用（信息展示）
      SettingItemWithInfo({
        label: $r('app.string.about_app'),
        info: $r('app.string.version_value', this.appInfo.appVersion)
      })
      .onClick(() => {
        this.onAboutApp()
      })
    }
    .width('90%')
    .backgroundColor(this.themeColors.cardBackground)
    .borderRadius(16)
    .margin({ bottom: 6 })
    .padding(12)
    .shadow({
      radius: 12,
      color: this.themeColors.shadow,
      offsetX: 0,
      offsetY: 4
    })
  }
}
