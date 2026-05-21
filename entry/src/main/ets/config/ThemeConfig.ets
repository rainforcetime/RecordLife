/**
 * 主题颜色配置
 * 定义浅色模式和深色模式的颜色配置
 * 遵循 HarmonyOS 设计规范，易于维护和扩展
 */

import { ConfigurationConstant } from '@kit.AbilityKit'

// 主题颜色接口
export interface ThemeColors {
  // 背景色
  background: string;           // 页面背景色
  cardBackground: string;       // 卡片背景色
  divider: string;              // 分隔线颜色
  
  // 文本色
  textPrimary: string;          // 主要文本色（标题、重要信息）
  textSecondary: string;        // 次要文本色（描述、辅助信息）
  textTertiary: string;         // 第三级文本色（提示、禁用状态）
  
  // 主题色
  primary: string;              // 主题色（按钮、强调元素）
  primaryLight: string;         // 主题色浅色版本
  primaryDark: string;          // 主题色深色版本
  
  // 功能色
  success: string;              // 成功色
  warning: string;              // 警告色
  error: string;                // 错误色
  info: string;                 // 信息色
  
  // 边框和阴影
  border: string;               // 边框颜色
  shadow: string;               // 阴影颜色
  
  // 特殊元素
  avatarBorder: string;         // 头像边框色
  iconColor: string;            // 图标颜色
  overlay: string;              // 遮罩层颜色
}

// 浅色模式配色方案
export const LightTheme: ThemeColors = {
  // 背景色
  background: '#F5F5F5',
  cardBackground: '#FFFFFF',
  divider: '#E5E5E5',
  
  // 文本色
  textPrimary: '#000000',
  textSecondary: '#666666',
  textTertiary: '#999999',
  
  // 主题色
  primary: '#007DFF',
  primaryLight: '#4DA3FF',
  primaryDark: '#0057B8',
  
  // 功能色
  success: '#00C853',
  warning: '#FF9800',
  error: '#FF4444',
  info: '#2196F3',
  
  // 边框和阴影
  border: '#E0E0E0',
  shadow: 'rgba(0, 0, 0, 0.1)',
  
  // 特殊元素
  avatarBorder: '#E0E0E0',
  iconColor: '#666666',
  overlay: 'rgba(0, 0, 0, 0.4)'
}

// 深色模式配色方案
export const DarkTheme: ThemeColors = {
  // 背景色
  background: '#1A1A1A',
  cardBackground: '#2D2D2D',
  divider: '#3D3D3D',
  
  // 文本色
  textPrimary: '#FFFFFF',
  textSecondary: '#B3B3B3',
  textTertiary: '#808080',
  
  // 主题色
  primary: '#4DA3FF',
  primaryLight: '#80BFFF',
  primaryDark: '#007DFF',
  
  // 功能色
  success: '#69F0AE',
  warning: '#FFB74D',
  error: '#FF6B6B',
  info: '#64B5F6',
  
  // 边框和阴影
  border: '#4D4D4D',
  shadow: 'rgba(0, 0, 0, 0.3)',
  
  // 特殊元素
  avatarBorder: '#4D4D4D',
  iconColor: '#B3B3B3',
  overlay: 'rgba(0, 0, 0, 0.6)'
}

// 主题类型
export type ThemeMode = 'light' | 'dark' | 'auto'

// 主题配置类（提供便捷访问方法）
export class ThemeConfig {
  // 获取当前主题颜色
  static getColors(isDark: boolean): ThemeColors {
    return isDark ? DarkTheme : LightTheme
  }
  
  // 判断是否为深色模式
  static isDarkMode(theme: ThemeMode, systemColorMode?: ConfigurationConstant.ColorMode): boolean {
    if (theme === 'dark') {
      return true
    } else if (theme === 'light') {
      return false
    } else {
      // auto 模式：跟随系统
      // ConfigurationConstant.ColorMode: 0=NOT_SET, 1=LIGHT, 2=DARK
      return systemColorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK
    }
  }
  
  // 获取主题显示名称
  static getDisplayName(theme: ThemeMode): string {
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
  
  // 显示名称转主题类型
  static fromDisplayName(displayName: string): ThemeMode {
    switch (displayName) {
      case '浅色模式':
        return 'light'
      case '深色模式':
        return 'dark'
      case '跟随系统':
      default:
        return 'auto'
    }
  }
}
