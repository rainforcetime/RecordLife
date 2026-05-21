// 更多设置页面：pages/MorePage.ets
import { common } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import { fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { SettingItemWithAction } from '../components/SettingItemWithAction'
import { ConfigManager } from '../config/ConfigManager'
import { promptAction, PromptAction } from '@kit.ArkUI'

@Entry
@Component
export struct MorePage {
  // 主题颜色配置（响应式）
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  private context: common.UIAbilityContext | null = null
  private configManager: ConfigManager | null = null
  private promptAction: PromptAction = this.getUIContext().getPromptAction()
  
  // 页面初始化
  async aboutToAppear() {
    try {
      // 获取应用上下文
      this.context = this.getUIContext().getHostContext() as common.UIAbilityContext
      console.info('MorePage: context 已获取 - ' + (this.context ? '成功' : '失败'))
      
      // 初始化配置管理器
      this.configManager = await ConfigManager.getInstance()
      console.info('MorePage: configManager 已初始化 - ' + (this.configManager ? '成功' : '失败'))
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
  private async onExportConfig() {
    console.info('[MorePage] 开始导出配置')
    
    if (!this.configManager) {
      promptAction.showToast({ message: '配置管理器未初始化' })
      return
    }
    
    if (!this.context) {
      promptAction.showToast({ message: '上下文未初始化' })
      return
    }
    
    try {
      // 获取配置内容
      const configStr = await this.configManager.exportConfig()
      console.info('[MorePage] 配置内容长度: ' + configStr.length)
      
      // 生成文件名（带时间戳）
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19)
      const fileName = `RecordLife_config_${timestamp}.json`
      
      // 使用DocumentViewPicker保存文件
      const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
      console.info('[MorePage] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const saveUri: string = uriResult[0]
        
        // 打开文件并写入配置内容
        const file = fileIo.openSync(saveUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(file.fd, configStr)
        fileIo.closeSync(file)
        
        console.info('[MorePage] 配置导出成功: ' + saveUri)
        promptAction.showToast({ message: '配置导出成功' })
      } else {
        console.info('[MorePage] 用户取消导出')
      }
    } catch (error) {
      console.error('[MorePage] 导出配置失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
    }
  }
  
  // 导入配置处理
  private async onImportConfig() {
    console.info('[MorePage] 开始导入配置')
    
    if (!this.configManager) {
      promptAction.showToast({ message: '配置管理器未初始化' })
      return
    }
    
    try {
      // 使用DocumentViewPicker选择配置文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      console.info('[MorePage] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const selectUri: string = uriResult[0]
        
        // 打开文件并读取配置内容
        const file = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(file.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(file.fd, buffer)
        fileIo.closeSync(file)
        
        // 将ArrayBuffer转换为字符串
        const decoder: util.TextDecoder = new util.TextDecoder('utf-8')
        const configStr = decoder.decodeToString(new Uint8Array(buffer))
        console.info('[MorePage] 配置内容长度: ' + configStr.length)
        
        // 导入配置
        const success = await this.configManager.importConfig(configStr)
        
        if (success) {
          console.info('[MorePage] 配置导入成功')
          promptAction.showToast({ message: '配置导入成功，部分设置需重启生效' })
        } else {
          console.error('[MorePage] 配置导入失败：格式无效')
          promptAction.showToast({ message: '配置文件格式无效' })
        }
      } else {
        console.info('[MorePage] 用户取消导入')
      }
    } catch (error) {
      console.error('[MorePage] 导入配置失败: ' + JSON.stringify(error))
      promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
    }
  }
  
  // 重置应用处理
  private onResetApp() {
    this.getUIContext().showAlertDialog({
      title: '重置应用',
      message: '确定要重置应用吗？此操作将清除所有用户数据并恢复默认设置，不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('[MorePage] 用户取消重置')
        }
      },
      secondaryButton: {
        value: '确定',
        action: async () => {
          console.info('[MorePage] 开始重置应用')
          
          if (!this.configManager) {
            promptAction.showToast({ message: '配置管理器未初始化' })
            return
          }
          
          try {
            const success = await this.configManager.resetToDefault()
            
            if (success) {
              console.info('[MorePage] 应用重置成功')
              promptAction.showToast({ message: '应用已重置，请重启应用生效' })
            } else {
              console.error('[MorePage] 应用重置失败')
              promptAction.showToast({ message: '重置失败，请重试' })
            }
          } catch (error) {
            console.error('[MorePage] 重置应用异常: ' + JSON.stringify(error))
            promptAction.showToast({ message: '重置失败: ' + (error as Error).message })
          }
        }
      }
    })
  }
}
