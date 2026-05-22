// 图片选择工具类：支持拍照和从相册选择
import { common } from '@kit.AbilityKit'
import { cameraPicker as picker, camera } from '@kit.CameraKit'
import { photoAccessHelper } from '@kit.MediaLibraryKit'
import { promptAction } from '@kit.ArkUI'

// 图片选择结果
export interface ImagePickResult {
  success: boolean
  uri?: string
  errorMessage?: string
}

// 图片选择方式
export enum ImagePickMode {
  CAMERA = 'camera',      // 拍照
  GALLERY = 'gallery'     // 从相册选择
}

export class ImagePickerUtils {
  /**
   * 选择图片（统一入口）
   * @param context UI上下文
   * @param mode 选择方式（拍照或相册）
   * @returns 图片选择结果
   */
  static async pickImage(
    context: common.UIAbilityContext,
    mode: ImagePickMode
  ): Promise<ImagePickResult> {
    try {
      if (mode === ImagePickMode.CAMERA) {
        return await ImagePickerUtils.pickFromCamera(context)
      } else {
        return await ImagePickerUtils.pickFromGallery()
      }
    } catch (error) {
      console.error(`[ImagePickerUtils] 选择图片失败: ${JSON.stringify(error)}`)
      return {
        success: false,
        errorMessage: '选择图片失败，请重试'
      }
    }
  }

  /**
   * 从相机拍照
   * @param context UI上下文
   * @returns 图片选择结果
   */
  private static async pickFromCamera(
    context: common.UIAbilityContext
  ): Promise<ImagePickResult> {
    try {
      // 配置相机设置
      const pickerProfile: picker.PickerProfile = {
        cameraPosition: camera.CameraPosition.CAMERA_POSITION_BACK
      }

      // 使用相机拍照
      const pickerResult: picker.PickerResult = await picker.pick(
        context,
        [picker.PickerMediaType.PHOTO],
        pickerProfile
      )

      if (pickerResult && pickerResult.resultUri && pickerResult.resultCode === 0) {
        console.info('[ImagePickerUtils] 拍照成功: ' + pickerResult.resultUri)
        return {
          success: true,
          uri: pickerResult.resultUri
        }
      }

      return {
        success: false,
        errorMessage: '拍照取消或失败'
      }
    } catch (error) {
      console.error('[ImagePickerUtils] 拍照失败: ' + JSON.stringify(error))
      return {
        success: false,
        errorMessage: '拍照失败，请重试'
      }
    }
  }

  /**
   * 从相册选择图片
   * @returns 图片选择结果
   */
  private static async pickFromGallery(): Promise<ImagePickResult> {
    try {
      // 创建图片选择选项
      const photoSelectOptions = new photoAccessHelper.PhotoSelectOptions()
      // 设置选择图片类型
      photoSelectOptions.MIMEType = photoAccessHelper.PhotoViewMIMETypes.IMAGE_TYPE
      // 设置最多选择1张图片
      photoSelectOptions.maxSelectNumber = 1

      // 创建图片选择器
      const photoPicker = new photoAccessHelper.PhotoViewPicker()

      // 调用select方法拉起图库选择界面
      const photoSelectResult = await photoPicker.select(photoSelectOptions)
      console.info('[ImagePickerUtils] 从相册选择成功: ' + JSON.stringify(photoSelectResult))

      // 获取选中的图片URI
      if (photoSelectResult.photoUris && photoSelectResult.photoUris.length > 0) {
        const selectedUri = photoSelectResult.photoUris[0]
        console.info('[ImagePickerUtils] 选中的图片URI: ' + selectedUri)
        return {
          success: true,
          uri: selectedUri
        }
      }

      return {
        success: false,
        errorMessage: '未选择图片'
      }
    } catch (error) {
      console.error('[ImagePickerUtils] 从相册选择失败: ' + JSON.stringify(error))
      return {
        success: false,
        errorMessage: '选择图片失败，请重试'
      }
    }
  }

  /**
   * 显示错误提示
   * @param message 错误消息
   */
  static showErrorToast(message: string): void {
    promptAction.showToast({ message: message })
  }
}
