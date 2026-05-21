/**
 * 主题管理器
 * 负责主题状态管理和主题配置提供
 * 使用 AppStorage 实现全局状态同步
 */

import { ConfigurationConstant } from '@kit.AbilityKit'
import { ThemeColors, ThemeMode, ThemeConfig, LightTheme, DarkTheme } from './ThemeConfig'

export class ThemeManager {
  private static instance: ThemeManager | null = null
  
  private constructor() {}
  
  // 获取单例实例
  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager()
    }
    return ThemeManager.instance
  }
  
  // 初始化主题系统
  init(theme: ThemeMode = 'light'): void {
    // 设置初始主题到 AppStorage
    AppStorage.setOrCreate('appTheme', theme)
    AppStorage.setOrCreate('isDarkMode', theme === 'dark')
    
    // 初始化主题颜色
    const colors = ThemeConfig.getColors(theme === 'dark')
    AppStorage.setOrCreate('themeColors', colors)
    
    console.info('ThemeManager: 主题系统初始化完成, theme=' + theme)
  }
  
  // 更新主题
  updateTheme(theme: ThemeMode, systemColorMode?: ConfigurationConstant.ColorMode): void {
    // 计算是否为深色模式
    const isDark = ThemeConfig.isDarkMode(theme, systemColorMode)
    
    // 更新 AppStorage
    AppStorage.setOrCreate('appTheme', theme)
    AppStorage.setOrCreate('isDarkMode', isDark)
    
    // 更新主题颜色
    const colors = ThemeConfig.getColors(isDark)
    AppStorage.setOrCreate('themeColors', colors)
    
    console.info('ThemeManager: 主题已更新, theme=' + theme + ', isDark=' + isDark)
  }
  
  // 获取当前主题
  getCurrentTheme(): ThemeMode {
    return AppStorage.get('appTheme') as ThemeMode || 'light'
  }
  
  // 获取当前是否为深色模式
  isDarkMode(): boolean {
    return AppStorage.get('isDarkMode') as boolean || false
  }
  
  // 获取当前主题颜色
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
      this.updateTheme('auto', colorModeNumber)
      console.info('ThemeManager: 系统主题变化，已更新为 ' + (colorModeNumber === ConfigurationConstant.ColorMode.COLOR_MODE_DARK ? '深色' : '浅色') + ' 模式')
    }
  }
}
