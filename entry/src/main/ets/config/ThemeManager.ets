/**
 * 主题管理器
 * 负责主题状态管理和主题配置提供
 * 使用 AppStorage 实现全局状态同步
 * 注意：主题数据源统一由 ConfigManager 管理，本类仅作为 AppStorage 的便捷访问层
 */

import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { window } from '@kit.ArkUI'
import { ThemeColors, ThemeMode, ThemeConfig, LightTheme, DarkTheme, DEFAULT_THEME_COLOR } from './ThemeConfig'
import { ConfigManager } from './ConfigManager'
import { Logger } from '../common/utils/Logger'

export class ThemeManager {
  private static instance: ThemeManager | null = null
  private configManager: ConfigManager | null = null
  
  private constructor() {}
  
  // 获取单例实例（支持显式注入 context，A5；未传时回退 AppStorage）
  static async getInstance(context?: common.UIAbilityContext): Promise<ThemeManager> {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager()
      await ThemeManager.instance.init(context)
    }
    return ThemeManager.instance
  }
  
  // 初始化主题管理器（context 传递至 ConfigManager）
  private async init(context?: common.UIAbilityContext): Promise<void> {
    try {
      // 获取ConfigManager实例（传递注入的 context）
      this.configManager = await ConfigManager.getInstance(context)
      
      // 从ConfigManager读取主题设置
      const savedTheme = this.configManager.getTheme() as ThemeMode
      Logger.info('ThemeManager.init: 从ConfigManager读取主题: ' + savedTheme)
      
      // 初始化AppStorage
      this.initAppStorage(savedTheme)
    } catch (error) {
      Logger.error('ThemeManager.init 失败: ' + JSON.stringify(error))
      // 使用默认主题
      this.initAppStorage('light')
    }
  }
  
  // 初始化AppStorage中的主题状态（携带主题主色）
  private initAppStorage(theme: ThemeMode): void {
    AppStorage.setOrCreate('appTheme', theme)
    AppStorage.setOrCreate('isDarkMode', theme === 'dark')
    
    // 初始化主题颜色（含自定义主色）
    const themeColor = this.configManager ? this.configManager.getThemeColor() : DEFAULT_THEME_COLOR
    const colors = ThemeConfig.getColors(theme === 'dark', themeColor)
    AppStorage.setOrCreate('themeColors', colors)
    
    Logger.info('ThemeManager: 主题系统初始化完成, theme=' + theme + ', color=' + themeColor)
  }
  
  // 更新主题（先保存到ConfigManager，再更新AppStorage）
  async updateTheme(theme: ThemeMode, systemColorMode?: ConfigurationConstant.ColorMode): Promise<boolean> {
    try {
      // 1. 先保存到ConfigManager（持久化）
      if (this.configManager) {
        const saved = await this.configManager.setTheme(theme)
        if (!saved) {
          Logger.error('ThemeManager.updateTheme: 保存主题到ConfigManager失败')
          return false
        }
      }
      
      // 2. 计算是否为深色模式
      const isDark = ThemeConfig.isDarkMode(theme, systemColorMode)
      
      // 3. 更新AppStorage（运行时状态）
      AppStorage.setOrCreate('appTheme', theme)
      AppStorage.setOrCreate('isDarkMode', isDark)
      
      // 4. 更新主题颜色（携带主题主色）
      const themeColor = this.configManager ? this.configManager.getThemeColor() : DEFAULT_THEME_COLOR
      const colors = ThemeConfig.getColors(isDark, themeColor)
      AppStorage.setOrCreate('themeColors', colors)
      
      // 5. 更新窗口系统栏颜色
      this.updateWindowSystemBarColor(colors)
      
      Logger.info('ThemeManager: 主题已更新, theme=' + theme + ', isDark=' + isDark)
      return true
    } catch (error) {
      Logger.error('ThemeManager.updateTheme 异常: ' + JSON.stringify(error))
      return false
    }
  }
  
  // 更新主题主色（先保存到ConfigManager，再更新AppStorage广播；主题配色功能）
  async updateThemeColor(color: string): Promise<boolean> {
    try {
      // 1. 先保存到ConfigManager（持久化）
      if (this.configManager) {
        const saved = await this.configManager.setThemeColor(color)
        if (!saved) {
          Logger.error('ThemeManager.updateThemeColor: 保存主题主色到ConfigManager失败')
          return false
        }
      }
      
      // 2. 更新AppStorage（运行时状态，全局组件响应）
      const isDark = this.isDarkMode()
      const colors = ThemeConfig.getColors(isDark, color)
      AppStorage.setOrCreate('themeColors', colors)
      
      // 3. 更新窗口系统栏颜色
      this.updateWindowSystemBarColor(colors)
      
      Logger.info('ThemeManager: 主题主色已更新, color=' + color + ', isDark=' + isDark)
      return true
    } catch (error) {
      Logger.error('ThemeManager.updateThemeColor 异常: ' + JSON.stringify(error))
      return false
    }
  }
  
  // 获取当前主题（从AppStorage读取）
  getCurrentTheme(): ThemeMode {
    return AppStorage.get('appTheme') as ThemeMode || 'light'
  }
  
  // 获取当前是否为深色模式（从AppStorage读取）
  isDarkMode(): boolean {
    return AppStorage.get('isDarkMode') as boolean || false
  }
  
  // 获取当前主题颜色（从AppStorage读取）
  getThemeColors(): ThemeColors {
    return AppStorage.get('themeColors') as ThemeColors || LightTheme
  }
  
  // 监听系统主题变化（用于 auto 模式）
  onSystemColorModeChange(systemColorMode?: ConfigurationConstant.ColorMode): void {
    const currentTheme = this.getCurrentTheme()
    
    // 只有在 auto 模式下才响应系统主题变化
    if (currentTheme === 'auto') {
      // 将 ColorMode 转换为 number
      const colorModeNumber = systemColorMode !== undefined ? systemColorMode : ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
      
      // 计算是否为深色模式
      const isDark = ThemeConfig.isDarkMode('auto', colorModeNumber)
      
      // 更新AppStorage（不保存到ConfigManager，因为主题设置未变）
      AppStorage.setOrCreate('isDarkMode', isDark)
      const themeColor = this.configManager ? this.configManager.getThemeColor() : DEFAULT_THEME_COLOR
      const colors = ThemeConfig.getColors(isDark, themeColor)
      AppStorage.setOrCreate('themeColors', colors)
      
      // 更新窗口系统栏颜色
      this.updateWindowSystemBarColor(colors)
      
      Logger.info('ThemeManager: 系统主题变化，已更新为 ' + (isDark ? '深色' : '浅色') + ' 模式')
    }
  }
  
  // 更新窗口系统栏颜色（状态栏和导航栏）
  private async updateWindowSystemBarColor(colors: ThemeColors): Promise<void> {
    try {
      // 从 AppStorage 获取窗口实例
      const uiContext = AppStorage.get('uiContext') as common.UIAbilityContext | undefined
      if (!uiContext) {
        Logger.warn('ThemeManager: uiContext 未初始化，无法更新系统栏颜色')
        return
      }
      
      // 获取窗口实例并设置系统栏颜色
      const mainWindow = await window.getLastWindow(uiContext)
      if (mainWindow) {
        await mainWindow.setWindowSystemBarProperties({
          statusBarColor: colors.background,
          statusBarContentColor: colors.textPrimary === '#FFFFFF' ? 'light' : 'dark',
          navigationBarColor: colors.background,
          navigationBarContentColor: colors.textPrimary === '#FFFFFF' ? 'light' : 'dark'
        })
        Logger.info('ThemeManager: 系统栏颜色已更新')
      }
    } catch (error) {
      Logger.error('ThemeManager: 更新窗口系统栏颜色异常: ' + JSON.stringify(error))
    }
  }
}
