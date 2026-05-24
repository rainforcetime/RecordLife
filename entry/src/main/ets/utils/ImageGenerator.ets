// 图片生成工具：utils/ImageGenerator.ets
import { image } from '@kit.ImageKit';
import { fileIo as fs } from '@kit.CoreFileKit';
import { common } from '@kit.AbilityKit';

export class ImageGenerator {
  /**
   * 生成纯色图片
   * @param context 应用上下文
   * @param width 图片宽度
   * @param height 图片高度
   * @param color 颜色（ARGB格式，如 0xFF4A90E2）
   * @param fileName 文件名（可选，默认自动生成）
   * @returns 图片文件路径，失败返回 null
   */
  static async generateSolidColorImage(
    context: common.UIAbilityContext,
    width: number,
    height: number,
    color: number,
    fileName?: string
  ): Promise<string | null> {
    try {
      // 1. 创建像素数据缓冲区
      const bufferSize = width * height * 4; // BGRA_8888 每个像素 4 字节
      const buffer = new ArrayBuffer(bufferSize);
      const view = new Uint8Array(buffer);
      
      // 解析颜色 (ARGB -> BGRA)
      const a = (color >> 24) & 0xFF;
      const r = (color >> 16) & 0xFF;
      const g = (color >> 8) & 0xFF;
      const b = color & 0xFF;
      
      // 填充像素数据 (BGRA_8888 格式)
      for (let i = 0; i < width * height; i++) {
        const offset = i * 4;
        view[offset] = b;     // B
        view[offset + 1] = g; // G
        view[offset + 2] = r; // R
        view[offset + 3] = a; // A
      }
      
      // 2. 创建 PixelMap
      const opts: image.InitializationOptions = {
        editable: true,
        pixelFormat: image.PixelMapFormat.BGRA_8888,
        size: { width: width, height: height }
      };
      
      const pixelMap = await image.createPixelMap(buffer, opts);
      
      // 3. 确保保存目录存在
      const saveDir = `${context.filesDir}/records`;
      if (!fs.accessSync(saveDir)) {
        fs.mkdirSync(saveDir);
        console.info('[ImageGenerator] 创建目录: ' + saveDir);
      }

      // 4. 生成文件名
      const timestamp = Date.now();
      const actualFileName = fileName || `sample_${timestamp}.png`;
      const filePath = `${saveDir}/${actualFileName}`;

      // 5. 将 PixelMap 编码为 PNG 并保存
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };
      
      const packData = await imagePackerApi.packing(pixelMap, packOpts);
      
      // 6. 写入文件
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, packData);
      fs.closeSync(file);
      
      // 7. 释放资源
      imagePackerApi.release();
      pixelMap.release();
      
      console.info('[ImageGenerator] 图片生成成功: ' + filePath);
      return filePath;
      
    } catch (error) {
      console.error('[ImageGenerator] 生成图片失败: ' + JSON.stringify(error));
      return null;
    }
  }

  /**
   * 生成渐变色图片
   * @param context 应用上下文
   * @param width 图片宽度
   * @param height 图片高度
   * @param startColor 起始颜色（ARGB格式）
   * @param endColor 结束颜色（ARGB格式）
   * @param fileName 文件名（可选）
   * @returns 图片文件路径，失败返回 null
   */
  static async generateGradientImage(
    context: common.UIAbilityContext,
    width: number,
    height: number,
    startColor: number,
    endColor: number,
    fileName?: string
  ): Promise<string | null> {
    try {
      // 1. 创建像素数据缓冲区
      const bufferSize = width * height * 4; // BGRA_8888 每个像素 4 字节
      const buffer = new ArrayBuffer(bufferSize);
      const view = new Uint8Array(buffer);
      
      // 解析颜色 (ARGB)
      const startA = (startColor >> 24) & 0xFF;
      const startR = (startColor >> 16) & 0xFF;
      const startG = (startColor >> 8) & 0xFF;
      const startB = startColor & 0xFF;
      
      const endA = (endColor >> 24) & 0xFF;
      const endR = (endColor >> 16) & 0xFF;
      const endG = (endColor >> 8) & 0xFF;
      const endB = endColor & 0xFF;
      
      // 填充像素数据 (BGRA_8888 格式，从上到下渐变)
      for (let y = 0; y < height; y++) {
        const ratio = y / (height - 1); // 渐变比例
        
        const b = Math.round(startB + (endB - startB) * ratio);
        const g = Math.round(startG + (endG - startG) * ratio);
        const r = Math.round(startR + (endR - startR) * ratio);
        const a = Math.round(startA + (endA - startA) * ratio);
        
        for (let x = 0; x < width; x++) {
          const offset = (y * width + x) * 4;
          view[offset] = b;     // B
          view[offset + 1] = g; // G
          view[offset + 2] = r; // R
          view[offset + 3] = a; // A
        }
      }
      
      // 2. 创建 PixelMap
      const opts: image.InitializationOptions = {
        editable: true,
        pixelFormat: image.PixelMapFormat.BGRA_8888,
        size: { width: width, height: height }
      };
      
      const pixelMap = await image.createPixelMap(buffer, opts);

      // 3. 确保保存目录存在
      const saveDir = `${context.filesDir}/sample_images`;
      if (!fs.accessSync(saveDir)) {
        fs.mkdirSync(saveDir);
      }

      // 4. 生成文件名
      const timestamp = Date.now();
      const actualFileName = fileName || `gradient_${timestamp}.png`;
      const filePath = `${saveDir}/${actualFileName}`;

      // 5. 编码并保存
      const imagePackerApi = image.createImagePacker();
      const packOpts: image.PackingOption = {
        format: 'image/png',
        quality: 100
      };
      
      const packData = await imagePackerApi.packing(pixelMap, packOpts);
      
      const file = fs.openSync(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY);
      fs.writeSync(file.fd, packData);
      fs.closeSync(file);
      
      // 6. 释放资源
      imagePackerApi.release();
      pixelMap.release();
      
      console.info('[ImageGenerator] 渐变图片生成成功: ' + filePath);
      return filePath;
      
    } catch (error) {
      console.error('[ImageGenerator] 生成渐变图片失败: ' + JSON.stringify(error));
      return null;
    }
  }
}
