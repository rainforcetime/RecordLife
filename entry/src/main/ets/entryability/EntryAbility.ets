import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { ConfigManager } from '../config/ConfigManager';
import { ThemeManager } from '../config/ThemeManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // 将 context 存储到 AppStorage，供 ConfigManager 使用
    // 必须在 initTheme 之前设置，确保 ConfigManager 能获取到 context
    AppStorage.setOrCreate('uiContext', this.context);
    
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
    try {
      // 初始化主题设置
      this.initTheme();
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to set colorMode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  // 初始化主题设置
  private async initTheme(): Promise<void> {
    try {
      // 初始化主题管理器（会自动从ConfigManager读取主题并初始化AppStorage）
      const themeManager = await ThemeManager.getInstance();
      
      // 从ConfigManager获取主题设置
      const configManager = await ConfigManager.getInstance();
      const theme = configManager.getTheme();
      
      // 根据保存的主题设置应用颜色模式
      const colorMode = this.themeToColorMode(theme);
      this.context.getApplicationContext().setColorMode(colorMode);
      
      // 保存当前主题到 AppStorage，供页面监听
      AppStorage.setOrCreate('currentTheme', theme);
      
      hilog.info(DOMAIN, 'testTag', 'Theme initialized: %{public}s', theme);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to init theme. Cause: %{public}s', JSON.stringify(err));
      // 失败时使用默认跟随系统模式
      try {
        this.context.getApplicationContext().setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
      } catch (e) {
        hilog.error(DOMAIN, 'testTag', 'Failed to set default color mode. Cause: %{public}s', JSON.stringify(e));
      }
    }
  }

  // 主题字符串转换为 ColorMode
  private themeToColorMode(theme: string): ConfigurationConstant.ColorMode {
    switch (theme) {
      case 'light':
        return ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
      case 'dark':
        return ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      case 'auto':
      default:
        return ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    }
  }

  // 监听系统配置变化（包括深浅色模式）
  async onConfigurationUpdate(newConfig: Configuration): Promise<void> {
    hilog.info(DOMAIN, 'testTag', 'Configuration updated: %{public}s', JSON.stringify(newConfig));
    
    // 如果当前是跟随系统模式，更新 AppStorage 中的主题状态
    const currentTheme = AppStorage.get('currentTheme') as string;
    if (currentTheme === 'auto') {
      // 通知页面系统主题已变化
      AppStorage.setOrCreate('systemColorMode', newConfig.colorMode);
      
      // 通知主题管理器系统主题已变化
      const themeManager = await ThemeManager.getInstance();
      themeManager.onSystemColorModeChange(newConfig.colorMode);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}