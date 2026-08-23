/**
 * 腾讯云 COS 对象存储服务（service 层）
 * 图片存储优化 M2：本地压缩 + 云端原图
 * 实现：COS XML API（REST）+ 自实现 V5 签名（HMAC-SHA1），零第三方依赖（@kit.NetworkKit + @kit.CryptoArchitectureKit）
 * 密钥：App 不内置，用户设置页自填（防反编译泄露）
 */
import { http } from '@kit.NetworkKit'
import { cryptoFramework } from '@kit.CryptoArchitectureKit'
import { util } from '@kit.ArkTS'
import { fileIo } from '@kit.CoreFileKit'
import { CosConfig } from '../model/UserConfigModel'
import { Logger } from '../common/utils/Logger'

export class CosService {
  // 获取访问域名（自定义域名优先，缺省 {bucket}.cos.{region}.myqcloud.com）
  // 签名 host 必须与实际请求域名一致——自定义域名场景下两者都用 getHost
  static getHost(config: CosConfig): string {
    if (config.customDomain && config.customDomain.length > 0) {
      return config.customDomain
    }
    return `${config.bucket}.cos.${config.region}.myqcloud.com`
  }

  // 构建对象 URL（https://{host}/{key}）
  static buildUrl(config: CosConfig, key: string): string {
    const scheme = config.useHttps === false ? 'http' : 'https'
    return `${scheme}://${CosService.getHost(config)}/${key}`
  }

  // 上传原图（PUT Object），返回是否成功
  static async uploadFile(config: CosConfig, key: string, filePath: string): Promise<boolean> {
    let file: fileIo.File | null = null
    try {
      file = fileIo.openSync(filePath, fileIo.OpenMode.READ_ONLY)
      const stat = fileIo.statSync(file.fd)
      const buffer = new ArrayBuffer(stat.size)
      fileIo.readSync(file.fd, buffer)
      fileIo.closeSync(file)
      file = null
      const auth = await CosService.buildAuth(config, 'put', '/' + key, 'image/jpeg')
      const client = http.createHttp()
      try {
        const resp = await client.request(CosService.buildUrl(config, key), {
          method: http.RequestMethod.PUT,
          header: {
            'Authorization': auth,
            'Content-Type': 'image/jpeg'
          },
          extraData: buffer
        })
        const ok = resp.responseCode === 200
        if (!ok) {
          Logger.error('[CosService] 上传失败 code=' + resp.responseCode + ' body=' + JSON.stringify(resp.result))
        }
        return ok
      } finally {
        client.destroy()
      }
    } catch (error) {
      Logger.error('[CosService] 上传异常: ' + JSON.stringify(error))
      return false
    } finally {
      if (file) {
        try {
          fileIo.closeSync(file)
        } catch (e) {
          Logger.error('[CosService] 关闭文件失败: ' + JSON.stringify(e))
        }
      }
    }
  }

  // 下载原图（GET Object）到目标路径，返回是否成功
  static async downloadFile(config: CosConfig, key: string, destPath: string): Promise<boolean> {
    try {
      const auth = await CosService.buildAuth(config, 'get', '/' + key)
      const client = http.createHttp()
      try {
        const resp = await client.request(CosService.buildUrl(config, key), {
          method: http.RequestMethod.GET,
          header: {
            'Authorization': auth
          },
          expectDataType: http.HttpDataType.ARRAY_BUFFER
        })
        if (resp.responseCode !== 200) {
          Logger.error('[CosService] 下载失败 code=' + resp.responseCode)
          return false
        }
        const data = resp.result as ArrayBuffer
        const destFile = fileIo.openSync(destPath, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE | fileIo.OpenMode.TRUNC)
        fileIo.writeSync(destFile.fd, data)
        fileIo.closeSync(destFile)
        return true
      } finally {
        client.destroy()
      }
    } catch (error) {
      Logger.error('[CosService] 下载异常: ' + JSON.stringify(error))
      return false
    }
  }

  // 删除对象（DELETE Object），返回是否成功
  static async deleteObject(config: CosConfig, key: string): Promise<boolean> {
    try {
      const auth = await CosService.buildAuth(config, 'delete', '/' + key)
      const client = http.createHttp()
      try {
        const resp = await client.request(CosService.buildUrl(config, key), {
          method: http.RequestMethod.DELETE,
          header: {
            'Authorization': auth
          }
        })
        return resp.responseCode === 204 || resp.responseCode === 200
      } finally {
        client.destroy()
      }
    } catch (error) {
      Logger.error('[CosService] 删除异常: ' + JSON.stringify(error))
      return false
    }
  }

  // 测试连接（HEAD bucket 根）：200（通）/403（连上但权限不足，也算通）/其他失败
  static async testConnection(config: CosConfig): Promise<boolean> {
    try {
      const host = CosService.getHost(config)
      const auth = await CosService.buildAuthWithHost(config, 'head', '/', host)
      const client = http.createHttp()
      try {
        const scheme = config.useHttps === false ? 'http' : 'https'
        const resp = await client.request(`${scheme}://${host}/`, {
          method: http.RequestMethod.HEAD,
          header: {
            'Authorization': auth
          }
        })
        return resp.responseCode === 200 || resp.responseCode === 403
      } finally {
        client.destroy()
      }
    } catch (error) {
      Logger.error('[CosService] 测试连接异常: ' + JSON.stringify(error))
      return false
    }
  }

  // ==================== COS V5 签名 ====================

  // 构建 Authorization（对象操作，host 由 getHost 推导：自定义域名优先）
  // contentType 可选：请求头含 content-type 时必须纳入签名（腾讯白名单头校验），否则 403
  private static async buildAuth(config: CosConfig, method: string, path: string, contentType?: string): Promise<string> {
    const host = CosService.getHost(config)
    return CosService.buildAuthWithHost(config, method, path, host, contentType)
  }

  // 构建 Authorization（指定 host，供 testConnection 等场景）
  private static async buildAuthWithHost(config: CosConfig, method: string, path: string, host: string, contentType?: string): Promise<string> {
    const now = Math.floor(Date.now() / 1000)
    const signTime = `${now - 60};${now + 3600}`
    const keyTime = signTime
    // SignKey = HMAC-SHA1(SecretKey, KeyTime)
    const signKey = await CosService.hmacSha1Hex(config.secretKey, keyTime)
    // HttpString = method\npath\n\n{headers}\n；headers 按字典序 & 连接，值需 URL 编码
    // 请求头含 content-type（白名单）时必须参与签名
    let headersStr: string
    let headersList: string
    if (contentType && contentType.length > 0) {
      headersStr = `host=${host}&content-type=${encodeURIComponent(contentType)}`
      headersList = 'host;content-type'
    } else {
      headersStr = `host=${host}`
      headersList = 'host'
    }
    const httpString = `${method}\n${path}\n\n${headersStr}\n`
    const httpStringSha1 = await CosService.sha1Hex(httpString)
    // StringToSign = sha1\nKeyTime\nSHA1(HttpString)\n
    const stringToSign = `sha1\n${keyTime}\n${httpStringSha1}\n`
    const signature = await CosService.hmacSha1Hex(signKey, stringToSign)
    return `q-sign-algorithm=sha1&q-ak=${config.secretId}&q-sign-time=${signTime}&q-key-time=${keyTime}&q-header-list=${headersList}&q-url-param-list=&q-signature=${signature}`
  }

  // HMAC-SHA1 十六进制
  private static async hmacSha1Hex(key: string, data: string): Promise<string> {
    const mac = cryptoFramework.createMac('HMAC|SHA1')
    const encoder = util.TextEncoder.create()
    const keyBlob: cryptoFramework.DataBlob = { data: encoder.encodeInto(key) }
    // DataBlob → SymKey（createMac.init 需要 SymKey）
    const keyGenerator = cryptoFramework.createSymKeyGenerator('HMAC')
    const symKey = await keyGenerator.convertKey(keyBlob)
    await mac.init(symKey)
    const dataBlob: cryptoFramework.DataBlob = { data: encoder.encodeInto(data) }
    await mac.update(dataBlob)
    const out: cryptoFramework.DataBlob = await mac.doFinal()
    return CosService.bytesToHex(out.data)
  }

  // SHA-1 十六进制
  private static async sha1Hex(data: string): Promise<string> {
    const md = cryptoFramework.createMd('SHA1')
    const encoder = util.TextEncoder.create()
    const dataBlob: cryptoFramework.DataBlob = { data: encoder.encodeInto(data) }
    await md.update(dataBlob)
    const out: cryptoFramework.DataBlob = await md.digest()
    return CosService.bytesToHex(out.data)
  }

  // 字节转十六进制
  private static bytesToHex(bytes: Uint8Array): string {
    let hex = ''
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0')
    }
    return hex
  }
}
