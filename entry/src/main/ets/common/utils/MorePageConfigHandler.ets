// MorePage 配置处理类：处理配置相关的业务逻辑
import { common, Want } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import { fileIo } from '@kit.CoreFileKit'
import { util } from '@kit.ArkTS'
import { PromptAction, UIContext } from '@kit.ArkUI'
import { ConfigManager } from '../../config/ConfigManager'
import { RefreshManager } from '../RefreshManager'
import { NowViewModel } from '../../viewmodel/NowViewModel'
import preferences from '@ohos.data.preferences'

export class MorePageConfigHandler {
  /**
   * 重启应用
   * 使用 ApplicationContext.restartApp 方法重启应用
   */
  private static restartApp(context: common.UIAbilityContext): void {
    try {
      const applicationContext = context.getApplicationContext()
      const want: Want = {
        bundleName: 'com.rainforcetime.recordlife',
        abilityName: 'EntryAbility'
      }
      console.info('[MorePageConfigHandler] 准备重启应用')
      applicationContext.restartApp(want)
      console.info('[MorePageConfigHandler] 重启应用已触发')
    } catch (error) {
      console.error('[MorePageConfigHandler] 重启应用失败: ' + JSON.stringify(error))
    }
  }
  
  /**
   * 导出配置
   */
  static async exportConfig(
    context: common.UIAbilityContext,
    configManager: ConfigManager,
    promptAction: PromptAction
  ): Promise<void> {
    console.info('[MorePageConfigHandler] 开始导出配置')
    
    try {
      // 获取配置内容
      const configStr = await configManager.exportConfig()
      console.info('[MorePageConfigHandler] 配置内容长度: ' + configStr.length)
      
      // 生成文件名（带时间戳）
      const timestamp = new Date().toISOString().replace(/[:.]/g, '-').substring(0, 19)
      const fileName = `RecordLife_config_${timestamp}.json`
      
      // 使用DocumentViewPicker保存文件
      const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
      documentSaveOptions.newFileNames = [fileName]
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
      console.info('[MorePageConfigHandler] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const saveUri: string = uriResult[0]
        
        // 打开文件并写入配置内容
        const file = fileIo.openSync(saveUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
        fileIo.writeSync(file.fd, configStr)
        fileIo.closeSync(file)
        
        console.info('[MorePageConfigHandler] 配置导出成功: ' + saveUri)
        promptAction.showToast({ message: '配置导出成功' })
      } else {
        console.info('[MorePageConfigHandler] 用户取消导出')
      }
    } catch (error) {
      console.error('[MorePageConfigHandler] 导出配置失败: ' + JSON.stringify(error))
      try {
        promptAction.showToast({ message: '导出失败: ' + (error as Error).message })
      } catch (toastError) {
        console.error('[MorePageConfigHandler] showToast 失败: ' + JSON.stringify(toastError))
      }
    }
  }
  
  /**
   * 导入配置
   */
  static async importConfig(
    context: common.UIAbilityContext,
    configManager: ConfigManager,
    promptAction: PromptAction
  ): Promise<void> {
    console.info('[MorePageConfigHandler] 开始导入配置')
    
    try {
      // 使用DocumentViewPicker选择配置文件
      const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
      documentSelectOptions.maxSelectNumber = 1
      const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()
      
      const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
      console.info('[MorePageConfigHandler] 文件选择结果: ' + JSON.stringify(uriResult))
      
      if (uriResult && uriResult.length > 0) {
        const selectUri: string = uriResult[0]
        
        // 打开文件并读取配置内容
        const file = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
        const stat = fileIo.statSync(file.fd)
        const buffer = new ArrayBuffer(stat.size)
        fileIo.readSync(file.fd, buffer)
        fileIo.closeSync(file)
        
        // 将ArrayBuffer转换为字符串
        const decoder: util.TextDecoder = util.TextDecoder.create('utf-8')
        const configStr = decoder.decodeToString(new Uint8Array(buffer))
        console.info('[MorePageConfigHandler] 配置内容长度: ' + configStr.length)
        
        // 导入配置
        const success = await configManager.importConfig(configStr)
        
        if (success) {
          console.info('[MorePageConfigHandler] 配置导入成功')
          promptAction.showToast({ message: '配置导入成功，应用即将重启' })
          
          // 延迟1秒后重启应用，让用户看到提示
          setTimeout(() => {
            MorePageConfigHandler.restartApp(context)
          }, 1000)
        } else {
          console.error('[MorePageConfigHandler] 配置导入失败：格式无效')
          promptAction.showToast({ message: '配置文件格式无效' })
        }
      } else {
        console.info('[MorePageConfigHandler] 用户取消导入')
      }
    } catch (error) {
      console.error('[MorePageConfigHandler] 导入配置失败: ' + JSON.stringify(error))
      try {
        promptAction.showToast({ message: '导入失败: ' + (error as Error).message })
      } catch (toastError) {
        console.error('[MorePageConfigHandler] showToast 失败: ' + JSON.stringify(toastError))
      }
    }
  }
  
  /**
   * 删除所有此刻记录
   */
  static async deleteAllRecords(context: common.UIAbilityContext): Promise<number> {
    try {
      // 1. 获取所有记录
      const viewModel = await NowViewModel.getInstance()
      const records = viewModel.getRecords()
      
      // 2. 删除所有图片文件
      const recordsDir = `${context.filesDir}/records`
      if (fileIo.accessSync(recordsDir)) {
        const files = fileIo.listFileSync(recordsDir)
        for (const fileName of files) {
          const filePath = `${recordsDir}/${fileName}`
          fileIo.unlinkSync(filePath)
        }
        console.info(`[MorePageConfigHandler] 删除了 ${files.length} 个图片文件`)
      }
      
      // 3. 清空 Preferences 中的记录数据
      const STORE_NAME = 'now_page_records'
      const RECORDS_KEY = 'life_records'
      const prefs = await preferences.getPreferences(context, STORE_NAME)
      await prefs.put(RECORDS_KEY, '[]')
      await prefs.flush()
      
      console.info('[MorePageConfigHandler] 记录数据已清空')
      
      return records.length
    } catch (error) {
      console.error('[MorePageConfigHandler] 删除记录失败: ' + JSON.stringify(error))
      return 0
    }
  }
  
  /**
   * 重置应用
   */
  static async resetApp(
    context: common.UIAbilityContext,
    configManager: ConfigManager,
    promptAction: PromptAction,
    uiContext: UIContext
  ): Promise<void> {
    uiContext.showAlertDialog({
      title: '重置应用',
      message: '确定要重置应用吗？此操作将清除所有用户数据（包括此刻记录）并恢复默认设置，不可恢复。',
      primaryButton: {
        value: '取消',
        action: () => {
          console.info('[MorePageConfigHandler] 用户取消重置')
        }
      },
      secondaryButton: {
        value: '确定',
        action: async () => {
          console.info('[MorePageConfigHandler] 开始重置应用')
          
          try {
            // 1. 删除此刻记录数据
            const recordsDeleted = await MorePageConfigHandler.deleteAllRecords(context)
            console.info(`[MorePageConfigHandler] 删除了 ${recordsDeleted} 条记录`)
            
            // 2. 重置配置
            const success = await configManager.resetToDefault()
            
            if (success) {
              console.info('[MorePageConfigHandler] 应用重置成功')
              promptAction.showToast({ message: '应用已重置，即将重启' })
              
              // 延迟1秒后重启应用，让用户看到提示
              setTimeout(() => {
                MorePageConfigHandler.restartApp(context)
              }, 1000)
            } else {
              console.error('[MorePageConfigHandler] 应用重置失败')
              promptAction.showToast({ message: '重置失败，请重试' })
            }
          } catch (error) {
            console.error('[MorePageConfigHandler] 重置应用异常: ' + JSON.stringify(error))
            promptAction.showToast({ message: '重置失败: ' + (error as Error).message })
          }
        }
      }
    })
  }
}
