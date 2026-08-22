/**
 * 资源读取工具（common/utils/ResourceUtils.ets）
 * 统一安全读取字符串资源：getStringByNameSync 可能抛异常（ArkTS may throw 警告），
 * 此处集中 try/catch 消除调用方警告；取不到返回空串（与原 `?.` / `? : ''` 行为一致）
 */
import { resourceManager } from '@kit.LocalizationKit'

export class ResourceUtils {
  static getString(
    rm: resourceManager.ResourceManager | null | undefined,
    name: string,
    ...args: Array<string | number>
  ): string {
    if (!rm) {
      return ''
    }
    try {
      return rm.getStringByNameSync(name, ...args)
    } catch (error) {
      return ''
    }
  }
}
