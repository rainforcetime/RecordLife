// 账号设置页面：pages/AccountPage.ets
import { common } from '@kit.AbilityKit'
import { promptAction, PromptAction } from '@kit.ArkUI'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItem } from '../components/setting/SettingItem'
import { SettingItemWithSelector } from '../components/setting/SettingItemWithSelector'
import { SettingItemWithInfo } from '../components/setting/SettingItemWithInfo'
import { EditProfileDialog } from '../components/dialog/EditProfileDialog'
import { AboutAppDialog } from '../components/dialog/AboutAppDialog'
import { UserInfoSection, UserInfo } from '../components/user/UserInfoSection'
import { AccountViewModel, DataStatistics } from '../viewmodel/AccountViewModel'
import { AccountUtils } from '../common/utils/AccountUtils'
import { AppInfo } from '../config/UserConfig'
import { RefreshManager } from '../common/RefreshManager'

@Component
export struct AccountPage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  // 用户信息状态
  @State userInfo: UserInfo = {
    userName: '张三',
    userBirthday: '1990-01-15',
    userGender: '男',
    userAvatar: '',
    hasCustomAvatar: false
  }
  
  // 设置项状态
  @State currentTheme: string = '跟随系统'
  
  // 数据统计
  @State statisticsInfo: DataStatistics = {
    usageDays: 0,
    dataVersion: 'v1.0.0',
    lastActiveTime: '',
    storageSize: '计算中...'
  }
  
  // 应用信息
  @State appInfo: AppInfo = {
    appName: '活着',
    appVersion: '0.0.1',
    buildNumber: '20260521',
    developer: 'rainforcetime',
    website: 'https://github.com/rainforcetime/RecordLife',
    description: '记录生活，珍惜每一刻'
  }
  
  // 业务逻辑
  private viewModel: AccountViewModel = new AccountViewModel()
  private context: common.UIAbilityContext | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()
  
  // 编辑资料弹窗控制器
  private editProfileDialog: CustomDialogController = new CustomDialogController({
    builder: EditProfileDialog({
      userName: this.userInfo.userName,
      userBirthday: this.userInfo.userBirthday,
      userGender: this.userInfo.userGender,
      themeColors: this.themeColors,
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
      appInfo: this.appInfo,
      themeColors: this.themeColors
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
      
      // 初始化业务逻辑
      await this.viewModel.initialize(this.context)
      
      // 加载用户资料
      await this.loadUserProfile()
      
      // 加载主题设置
      await this.loadThemeSettings()
      
      // 加载应用信息
      await this.loadAppInfo()
      
      // 加载保存的头像
      await this.loadSavedAvatar()
      
      // 加载数据统计信息
      await this.loadDataStatistics()
      
      // 注册全局刷新回调
      RefreshManager.getInstance().register('AccountPage', () => {
        console.info('[AccountPage] 收到全局刷新通知')
        this.loadDataStatistics()
      })
    } catch (error) {
      console.error('AccountPage 初始化失败: ' + JSON.stringify(error))
    }
  }
  
  // 页面销毁时注销回调
  aboutToDisappear() {
    console.info('[AccountPage] aboutToDisappear')
    // 注销刷新回调
    RefreshManager.getInstance().unregister('AccountPage')
  }
  
  // 页面显示时刷新数据
  onPageShow() {
    console.info('[AccountPage] onPageShow')
    this.loadDataStatistics()
  }
  
  // 加载用户资料
  private async loadUserProfile() {
    const profile = await this.viewModel.loadUserProfile()
    this.userInfo.userName = profile.name
    this.userInfo.userBirthday = profile.birthday
    this.userInfo.userGender = profile.gender
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
    console.info('[AccountPage] 开始加载数据统计')
    const statistics = await this.viewModel.loadDataStatistics()
    console.info('[AccountPage] 获取到统计数据: ' + JSON.stringify(statistics))
    
    // 必须重新赋值整个对象才能触发UI更新
    this.statisticsInfo = {
      usageDays: statistics.usageDays,
      dataVersion: statistics.dataVersion,
      lastActiveTime: statistics.lastActiveTime,
      storageSize: statistics.storageSize
    }
    
    console.info('[AccountPage] statisticsInfo已更新: ' + JSON.stringify(this.statisticsInfo))
  }
  
  // 加载保存的头像
  private async loadSavedAvatar() {
    const avatarInfo = await this.viewModel.loadSavedAvatar()
    this.userInfo.userAvatar = avatarInfo.avatar
    this.userInfo.hasCustomAvatar = avatarInfo.hasCustomAvatar
  }
  
  // 主题切换处理
  private async onThemeChange(value: string) {
    this.currentTheme = value
    const success = await this.viewModel.onThemeChange(value)
    
    if (success) {
      AccountUtils.showToastSafely(this.promptAction, '主题设置已保存')
    } else {
      AccountUtils.showToastSafely(this.promptAction, '主题保存失败，请重试')
    }
  }
  
  // 编辑资料处理
  private onEditProfile() {
    console.log('编辑资料')
    this.editProfileDialog.open()
  }
  
  // 保存用户资料
  private async onSaveProfile(name: string, birthday: string, gender: string) {
    const avatarPath = this.userInfo.hasCustomAvatar ? this.userInfo.userAvatar : ''
    const success = await this.viewModel.saveProfile(name, birthday, gender, avatarPath)
    
    if (success) {
      // 更新UI显示
      this.userInfo.userName = name
      this.userInfo.userBirthday = birthday
      this.userInfo.userGender = gender
      
      console.info('用户资料保存成功')
      AccountUtils.showToastSafely(this.promptAction, '保存成功')
    } else {
      console.error('用户资料保存失败')
      AccountUtils.showToastSafely(this.promptAction, '保存失败')
    }
  }
  
  // 头像更换处理
  private async onChangeAvatar() {
    const avatarUri = await this.viewModel.onChangeAvatar()
    if (avatarUri) {
      this.userInfo.userAvatar = avatarUri
      this.userInfo.hasCustomAvatar = true
    }
  }
  
  // 关于应用处理
  private onAboutApp() {
    console.log('关于应用')
    this.aboutAppDialog.open()
  }
  
  // 更多设置处理
  private onMoreSettings() {
    console.log('更多设置')
    try {
      this.getUIContext().getRouter().pushUrl({
        url: 'pages/MorePage'
      })
    } catch (error) {
      console.error('页面跳转失败: ' + JSON.stringify(error))
    }
  }
  
  build() {
    Scroll() {
      Column() {
        // 页面标题
        Text('账号设置')
          .fontSize(26)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ top: 24, bottom: 20 })
          .width('90%')
        
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
        
        // 设置项列表
        this.SettingsSection()
        
        // 已使用天数提示
        Row() {
          SymbolGlyph($r('sys.symbol.calendar'))
            .fontSize(14)
            .fontColor([this.themeColors.textSecondary])
            .margin({ right: 4 })
          
          Text(`已使用 ${this.statisticsInfo.usageDays} 天`)
            .fontSize(12)
            .fontColor(this.themeColors.textSecondary)
        }
        .width('90%')
        .justifyContent(FlexAlign.Center)
        .margin({ top: 2, bottom: 2 })
        
        // 底部留白
        Column()
          .height(20)
      }
      .width('100%')
      .alignItems(HorizontalAlign.Center)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Spring)
  }
  
  // 设置项列表组件
  @Builder
  SettingsSection() {
    Column() {
      // 区域标题
      Row() {
        Text('设置')
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
      }
      .width('100%')
      .padding({ left: 4, bottom: 12 })
      
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
        .height(0.5)
      
      // 存储空间（信息展示）
      SettingItemWithInfo({
        label: '存储空间',
        info: this.statisticsInfo.storageSize
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 关于应用（信息展示）
      SettingItemWithInfo({
        label: '关于应用',
        info: `版本 ${this.appInfo.appVersion}`
      })
      .onClick(() => {
        this.onAboutApp()
      })
      
      Divider()
        .color(this.themeColors.divider)
        .margin({ left: 15 })
        .height(0.5)
      
      // 更多设置
      SettingItem({
        label: '更多',
        summary: '导入/导出配置、备份/恢复记录、重置应用'
      })
      .onClick(() => {
        this.onMoreSettings()
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
