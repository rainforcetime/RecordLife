/**
 * Zip 传输服务（service 层）
 * 封装 DocumentViewPicker 的 zip 保存/选择 + 沙箱复制操作
 * 拆分自 MorePageBackupHandler（P3 重构）：exportBackup/exportAll/importBackup/importAll 共用的 picker 流程收敛于此
 * 设计约定：仅将「用户取消」转为 false；IO 异常不捕获，冒泡给调用方外层 try/catch（保持原行为）
 */
import { common } from '@kit.AbilityKit'
import { picker } from '@kit.CoreFileKit'
import { fileIo } from '@kit.CoreFileKit'

export class ZipTransferService {
  /**
   * 通过 DocumentViewPicker 将 zip 保存到用户选择的位置
   * @param context 应用上下文
   * @param zipPath 沙箱内的 zip 文件路径
   * @returns true = 已保存；false = 用户取消；IO 异常向上抛出
   */
  static async saveZipToDocument(context: common.UIAbilityContext, zipPath: string): Promise<boolean> {
    const fileName = zipPath.split('/').pop() || 'backup.zip'
    const documentSaveOptions: picker.DocumentSaveOptions = new picker.DocumentSaveOptions()
    documentSaveOptions.newFileNames = [fileName]
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()

    const uriResult: Array<string> = await documentPicker.save(documentSaveOptions)
    if (uriResult && uriResult.length > 0) {
      const saveUri: string = uriResult[0]

      // 读取 zip 内容并写入目标文件
      const zipFile = fileIo.openSync(zipPath, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(zipFile.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(zipFile.fd, buffer)
      fileIo.closeSync(zipFile)

      const destFile = fileIo.openSync(saveUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(destFile.fd, buffer)
      fileIo.closeSync(destFile)

      return true
    }
    return false
  }

  /**
   * 通过 DocumentViewPicker 选择文件并复制到沙箱指定路径
   * @param context 应用上下文
   * @param destPath 沙箱内的目标文件路径
   * @returns true = 已复制；false = 用户取消；IO 异常向上抛出
   */
  static async pickZipToSandbox(context: common.UIAbilityContext, destPath: string): Promise<boolean> {
    const documentSelectOptions: picker.DocumentSelectOptions = new picker.DocumentSelectOptions()
    documentSelectOptions.maxSelectNumber = 1
    const documentPicker: picker.DocumentViewPicker = new picker.DocumentViewPicker()

    const uriResult: Array<string> = await documentPicker.select(documentSelectOptions)
    if (uriResult && uriResult.length > 0) {
      const selectUri: string = uriResult[0]

      // 将选中的文件复制到沙箱临时目录
      const srcFile = fileIo.openSync(selectUri, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(srcFile.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(srcFile.fd, buffer)
      fileIo.closeSync(srcFile)

      const destFile = fileIo.openSync(destPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE)
      fileIo.writeSync(destFile.fd, buffer)
      fileIo.closeSync(destFile)

      return true
    }
    return false
  }
}
