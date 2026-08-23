/**
 * HMAC-SHA1 纯 ArkTS 实现（common/utils/HmacSha1.ets）
 * 背景：部分设备 cryptoFramework 的 createMac('HMAC|SHA1') 报 Algo not support（code 401）
 * 用途：腾讯云 COS V5 签名（SignKey/Signature 均需 HMAC-SHA1），输入均为短字符串，纯 TS 实现性能无忧
 * 已用标准黄金向量验证（SHA1('abc')=a9993e36...，HMAC-SHA1 标准样例）
 */
import { util } from '@kit.ArkTS'

export class HmacSha1 {
  // HMAC-SHA1 十六进制（小写）
  static hex(key: string, data: string): string {
    const encoder = util.TextEncoder.create()
    const keyBytes = encoder.encodeInto(key)
    const dataBytes = encoder.encodeInto(data)
    // key > 64 字节先做 SHA1 压缩
    let keyBlock = keyBytes
    if (keyBlock.length > 64) {
      keyBlock = HmacSha1.sha1(keyBlock)
    }
    const ipad = new Uint8Array(64)
    const opad = new Uint8Array(64)
    for (let i = 0; i < 64; i++) {
      const kb = i < keyBlock.length ? keyBlock[i] : 0
      ipad[i] = kb ^ 0x36
      opad[i] = kb ^ 0x5c
    }
    // inner = SHA1(key^ipad || data)
    const inner = new Uint8Array(64 + dataBytes.length)
    inner.set(ipad)
    inner.set(dataBytes, 64)
    const innerHash = HmacSha1.sha1(inner)
    // outer = SHA1(key^opad || innerHash)
    const outer = new Uint8Array(84)
    outer.set(opad)
    outer.set(innerHash, 64)
    const result = HmacSha1.sha1(outer)
    return HmacSha1.bytesToHex(result)
  }

  // SHA1 摘要十六进制（小写）
  static sha1Hex(data: string): string {
    const encoder = util.TextEncoder.create()
    return HmacSha1.bytesToHex(HmacSha1.sha1(encoder.encodeInto(data)))
  }

  // ==================== 内部实现 ====================

  // 循环左移（32 位）
  private static rol(value: number, bits: number): number {
    return (value << bits) | (value >>> (32 - bits))
  }

  // SHA1（标准 FIPS 180-1）
  private static sha1(input: Uint8Array): Uint8Array {
    const ml = input.length
    const bitLenLow = (ml * 8) >>> 0
    // 补位：0x80 + 0... + 64bit 大端长度
    const paddedLen = (((ml + 8) >> 6) + 1) * 64
    const padded = new Uint8Array(paddedLen)
    padded.set(input)
    padded[ml] = 0x80
    const view = new DataView(padded.buffer)
    view.setUint32(paddedLen - 8, 0)           // 高 32 位（本场景长度 < 2^32 字节）
    view.setUint32(paddedLen - 4, bitLenLow)   // 低 32 位（bit 数）

    let h0 = 0x67452301
    let h1 = 0xEFCDAB89
    let h2 = 0x98BADCFE
    let h3 = 0x10325476
    let h4 = 0xC3D2E1F0
    const w = new Array<number>(80)

    for (let i = 0; i < paddedLen; i += 64) {
      for (let t = 0; t < 16; t++) {
        w[t] = view.getUint32(i + t * 4)
      }
      for (let t = 16; t < 80; t++) {
        w[t] = HmacSha1.rol(w[t - 3] ^ w[t - 8] ^ w[t - 14] ^ w[t - 16], 1)
      }
      let a = h0
      let b = h1
      let c = h2
      let d = h3
      let e = h4
      for (let t = 0; t < 80; t++) {
        let f: number
        let k: number
        if (t < 20) {
          f = (b & c) | (~b & d)
          k = 0x5A827999
        } else if (t < 40) {
          f = b ^ c ^ d
          k = 0x6ED9EBA1
        } else if (t < 60) {
          f = (b & c) | (b & d) | (c & d)
          k = 0x8F1BBCDC
        } else {
          f = b ^ c ^ d
          k = 0xCA62C1D6
        }
        const temp = (HmacSha1.rol(a, 5) + f + e + k + w[t]) >>> 0
        e = d
        d = c
        c = HmacSha1.rol(b, 30)
        b = a
        a = temp
      }
      h0 = (h0 + a) >>> 0
      h1 = (h1 + b) >>> 0
      h2 = (h2 + c) >>> 0
      h3 = (h3 + d) >>> 0
      h4 = (h4 + e) >>> 0
    }

    const out = new Uint8Array(20)
    const ov = new DataView(out.buffer)
    ov.setUint32(0, h0)
    ov.setUint32(4, h1)
    ov.setUint32(8, h2)
    ov.setUint32(12, h3)
    ov.setUint32(16, h4)
    return out
  }

  // 字节 → 十六进制（小写）
  private static bytesToHex(bytes: Uint8Array): string {
    let hex = ''
    for (let i = 0; i < bytes.length; i++) {
      hex += bytes[i].toString(16).padStart(2, '0')
    }
    return hex
  }
}
