/**
 * 腾讯云 COS 对象存储服务（service 层）
 * 图片存储优化 M2：本地压缩 + 云端原图
 * 实现：COS XML API（REST）+ 自实现 V5 签名（HMAC-SHA1），零第三方依赖（@kit.NetworkKit + @kit.CryptoArchitectureKit）
 * 密钥：App 不内置，用户设置页自填（防反编译泄露）
 */
import { http } from '@kit.NetworkKit'
import { fileIo } from '@kit.CoreFileKit'
import { CosConfig } from '../model/UserConfigModel'
import { HmacSha1 } from '../common/utils/HmacSha1'
import { Logger } from '../common/utils/Logger'

// 参与签名的请求头项（name 小写）
interface SignedHeader {
  name: string
  value: string
}

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
      // COS 白名单头（content-type/content-length）必须纳入签名，否则签名校验失败
      const auth = await CosService.buildAuth(config, 'put', '/' + key,
        ['content-type:image/jpeg', 'content-length:' + buffer.byteLength])
      const client = http.createHttp()
      try {
        const resp = await client.request(CosService.buildUrl(config, key), {
          method: http.RequestMethod.PUT,
          header: {
            'Authorization': auth,
            'Content-Type': 'image/jpeg',
            'Content-Length': buffer.byteLength
          },
          extraData: buffer
        })
        const ok = resp.responseCode === 200
        if (!ok) {
          Logger.error('[CosService] 上传失败 code=' + resp.responseCode +
            ' body=' + CosService.extractErrorBody(resp.result))
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

  // 检查对象是否存在（HEAD Object），返回是否已存在
  static async exists(config: CosConfig, key: string): Promise<boolean> {
    try {
      const auth = await CosService.buildAuth(config, 'head', '/' + key)
      const client = http.createHttp()
      try {
        const resp = await client.request(CosService.buildUrl(config, key), {
          method: http.RequestMethod.HEAD,
          header: {
            'Authorization': auth
          }
        })
        return resp.responseCode === 200
      } finally {
        client.destroy()
      }
    } catch (error) {
      Logger.error('[CosService] 检查对象异常: ' + JSON.stringify(error))
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
  // headers 可选：'name:value' 列表（如 content-type/content-length），请求头含 COS 白名单头时必须纳入签名
  private static async buildAuth(config: CosConfig, method: string, path: string, headers?: string[]): Promise<string> {
    const host = CosService.getHost(config)
    return CosService.buildAuthWithHeaders(config, method, path, host, headers)
  }

  // 构建 Authorization（指定 host，供 testConnection 等场景）
  private static async buildAuthWithHost(config: CosConfig, method: string, path: string, host: string): Promise<string> {
    return CosService.buildAuthWithHeaders(config, method, path, host)
  }

  // 构建 Authorization（核心）：headers 按 name 字典序排序、值 URL 编码，参与 HttpString 与 q-header-list
  private static async buildAuthWithHeaders(config: CosConfig, method: string, path: string, host: string, headers?: string[]): Promise<string> {
    const now = Math.floor(Date.now() / 1000)
    const signTime = `${now - 60};${now + 3600}`
    const keyTime = signTime
    // 组装 header 列表（含 host），name 转小写
    const headerList: SignedHeader[] = []
    headerList.push({ name: 'host', value: host })
    if (headers) {
      for (const h of headers) {
        const idx = h.indexOf(':')
        if (idx > 0) {
          headerList.push({ name: h.substring(0, idx).toLowerCase(), value: h.substring(idx + 1) })
        }
      }
    }
    // 按 name 字典序排序
    headerList.sort((a: SignedHeader, b: SignedHeader) => {
      return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0)
    })
    // HttpString = method\npath\n\n{headers}\n；headers 为 name=value 用 & 连接，值 URL 编码
    let headersStr = ''
    let namesList = ''
    for (let i = 0; i < headerList.length; i++) {
      const h = headerList[i]
      const encName = encodeURIComponent(h.name)
      const encValue = encodeURIComponent(h.value)
      if (i > 0) {
        headersStr += '&'
      }
      headersStr += `${encName}=${encValue}`
      if (i > 0) {
        namesList += ';'
      }
      namesList += encName
    }
    const httpString = `${method}\n${path}\n\n${headersStr}\n`
    // SignKey = HMAC-SHA1(SecretKey, KeyTime)
    const signKey = HmacSha1.hex(config.secretKey, keyTime)
    const httpStringSha1 = HmacSha1.sha1Hex(httpString)
    // StringToSign = sha1\nKeyTime\nSHA1(HttpString)\n
    const stringToSign = `sha1\n${keyTime}\n${httpStringSha1}\n`
    const signature = HmacSha1.hex(signKey, stringToSign)
    return `q-sign-algorithm=sha1&q-ak=${config.secretId}&q-sign-time=${signTime}&q-key-time=${keyTime}&q-header-list=${namesList}&q-url-param-list=&q-signature=${signature}`
  }

  // 提取 COS 错误响应中的错误码/信息（body 为 XML，如 <Code>SignatureDoesNotMatch</Code> <Message>...）
  private static extractErrorBody(result: Object): string {
    try {
      const str = typeof result === 'string' ? result : JSON.stringify(result)
      if (!str) {
        return ''
      }
      const codeMatch = str.match(/<Code>([^<]+)<\/Code>/)
      const msgMatch = str.match(/<Message>([^<]+)<\/Message>/)
      if (codeMatch || msgMatch) {
        return `Code=${codeMatch ? codeMatch[1] : ''} Message=${msgMatch ? msgMatch[1] : ''}`
      }
      return str.length > 300 ? str.substring(0, 300) : str
    } catch (error) {
      return ''
    }
  }
}
