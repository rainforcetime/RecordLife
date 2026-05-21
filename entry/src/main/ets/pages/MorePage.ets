// 更多设置页面：pages/MorePage.ets
import { common } from '@kit.AbilityKit'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItemWithAction } from '../components/SettingItemWithAction'

@Entry
@Component
export struct MorePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  private context: common.UIAbilityContext | null = null
  
  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      console.info('MorePage: context 已获取 - ' + (this.context ? '成功' : '失败'))
    } catch (error) {
      console.error('MorePage 初始化失败: ' + JSON.stringify(error))
    }
  }
  
  build() {
    Column() {
      // 页面标题
      Row() {
        // 返回按钮
        Image($r('sys.media.ohos_ic_public_arrow_left'))
          .width(24)
          .height(24)
          .fillColor(this.themeColors.iconColor)
          .onClick(() => {
            this.goBack()
          })
        
        Text('更多')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 15 })
          .layoutWeight(1)
      }
      .width('100%')
      .height(56)
      .padding({ left: 15, right: 15 })
      .backgroundColor(this.themeColors.cardBackground)
      
      Scroll() {
        Column() {
          // 功能列表
          this.FunctionsSection()
        }
        .width('100%')
        .margin({ top: 15 })
        .align(Alignment.Top)
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Off)
      .edgeEffect(EdgeEffect.Spring)
      .align(Alignment.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }
  
  // 功能列表组件
  @Builder
  FunctionsSection() {
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
  
  // 返回处理
  private goBack() {
    // 获取UI上下文并执行路由返回
    this.getUIContext().getRouter().back()
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
}
