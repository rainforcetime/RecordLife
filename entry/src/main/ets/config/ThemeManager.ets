/**
 * 主题管理器
 * 负责主题状态管理和主题配置提供
 * 使用 AppStorage 实现全局状态同步
 * 注意：主题数据源统一由 ConfigManager 管理，本类仅作为 AppStorage 的便捷访问层
 */

import { ConfigurationConstant } from '@kit.AbilityKit'
import { ThemeColors, ThemeMode, ThemeConfig, LightTheme, DarkTheme } from './ThemeConfig'
import { ConfigManager } from './ConfigManager'

export class ThemeManager {
  private static instance: ThemeManager | null = null
  private configManager: ConfigManager | null = null
  
  private constructor() {}
  
  // 获取单例实例（异步模式，统一与其他Manager一致）
  static async getInstance(): Promise<ThemeManager> {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager()
      await ThemeManager.instance.init()
    }
    return ThemeManager.instance
  }
  
  // 初始化主题管理器
  private async init(): Promise<void> {
    try {
      // 获取ConfigManager实例
      this.configManager = await ConfigManager.getInstance()
      
      // 从ConfigManager读取主题设置
      const savedTheme = this.configManager.getTheme() as ThemeMode
      console.info('ThemeManager.init: 从ConfigManager读取主题: ' + savedTheme)
      
      // 初始化AppStorage
      this.initAppStorage(savedTheme)
    } catch (error) {
      console.error('ThemeManager.init 失败: ' + JSON.stringify(error))
      // 使用默认主题
      this.initAppStorage('light')
    }
  }
  
  // 初始化AppStorage中的主题状态
  private initAppStorage(theme: ThemeMode): void {
    AppStorage.setOrCreate('appTheme', theme)
    AppStorage.setOrCreate('isDarkMode', theme === 'dark')
    
    // 初始化主题颜色
    const colors = ThemeConfig.getColors(theme === 'dark')
    AppStorage.setOrCreate('themeColors', colors)
    
    console.info('ThemeManager: 主题系统初始化完成, theme=' + theme)
  }
  
  // 更新主题（先保存到ConfigManager，再更新AppStorage）
  async updateTheme(theme: ThemeMode, systemColorMode?: ConfigurationConstant.ColorMode): Promise<boolean> {
    try {
      // 1. 先保存到ConfigManager（持久化）
      if (this.configManager) {
        const saved = await this.configManager.setTheme(theme)
        if (!saved) {
          console.error('ThemeManager.updateTheme: 保存主题到ConfigManager失败')
          return false
        }
      }
      
      // 2. 计算是否为深色模式
      const isDark = ThemeConfig.isDarkMode(theme, systemColorMode)
      
      // 3. 更新AppStorage（运行时状态）
      AppStorage.setOrCreate('appTheme', theme)
      AppStorage.setOrCreate('isDarkMode', isDark)
      
      // 4. 更新主题颜色
      const colors = ThemeConfig.getColors(isDark)
      AppStorage.setOrCreate('themeColors', colors)
      
      console.info('ThemeManager: 主题已更新, theme=' + theme + ', isDark=' + isDark)
      return true
    } catch (error) {
      console.error('ThemeManager.updateTheme 异常: ' + JSON.stringify(error))
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
      const colors = ThemeConfig.getColors(isDark)
      AppStorage.setOrCreate('themeColors', colors)
      
      console.info('ThemeManager: 系统主题变化，已更新为 ' + (isDark ? '深色' : '浅色') + ' 模式')
    }
  }
}
