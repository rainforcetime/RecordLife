// NowPage 业务逻辑类：viewmodel/NowViewModel.ets
import { common } from '@kit.AbilityKit'
import { fileIo, fileUri } from '@kit.CoreFileKit'
import { LifeRecord, TimelineYear, TimelineMonth, TimelineDay, TimelineData } from '../common/types'
import { TimeUtils } from '../common/utils/TimeUtils'
import { ImageGenerator } from '../utils/ImageGenerator'
import { RecordRepository } from '../repository/RecordRepository'

// 生活记录数据管理类
export class NowViewModel {
  private static instance: NowViewModel | null = null
  private context: common.UIAbilityContext | null = null
  
  // 记录数据
  private records: LifeRecord[] = []
  
  private constructor() {}
  
  // 获取单例实例
  static async getInstance(): Promise<NowViewModel> {
    if (!NowViewModel.instance) {
      NowViewModel.instance = new NowViewModel()
      await NowViewModel.instance.init()
    } else if (!NowViewModel.instance.context) {
      await NowViewModel.instance.init()
    }
    return NowViewModel.instance
  }
  
  // 初始化
  private async init(): Promise<void> {
    console.info('[NowViewModel] init 开始')
    
    // 最多重试3次，每次间隔100ms
    for (let retry = 0; retry < 3; retry++) {
      try {
        // 获取上下文
        let uiContext = AppStorage.get('uiContext') as common.UIAbilityContext
        if (!uiContext) {
          uiContext = AppStorage.get('context') as common.UIAbilityContext
        }
        
        if (!uiContext) {
          console.warn(`[NowViewModel] uiContext 不存在，重试 ${retry + 1}/3`)
          if (retry < 2) {
            await new Promise<void>(resolve => setTimeout(resolve, 100))
            continue
          }
          console.error('[NowViewModel] uiContext 获取失败，初始化终止')
          return
        }
        
        this.context = uiContext
        
        // 加载记录
        await this.loadRecords()
        console.info('[NowViewModel] 记录加载完成，数量: ' + this.records.length)
        return // 初始化成功，退出
      } catch (error) {
        console.error('[NowViewModel] init 失败: ' + JSON.stringify(error))
        if (retry < 2) {
          await new Promise<void>(resolve => setTimeout(resolve, 100))
        }
      }
    }
  }
  
  // 加载记录
  private async loadRecords(): Promise<void> {
    if (!this.context) {
      this.records = []
      return
    }
    
    try {
      const records = await RecordRepository.getRecords(this.context)
      if (records.length > 0) {
        this.records = records
        // 按时间戳降序排序（最新的在前）
        this.records.sort((a, b) => b.timestamp - a.timestamp)
      } else {
        this.records = []
        // 首次使用，初始化示例数据
        await this.initSampleData()
      }
    } catch (error) {
      console.error('[NowViewModel] 加载记录失败: ' + JSON.stringify(error))
      this.records = []
    }
  }
  
  // 初始化示例数据
  private async initSampleData(): Promise<void> {
    console.info('[NowViewModel] 初始化示例数据')
    
    if (!this.context) {
      console.error('[NowViewModel] context 未初始化，无法生成示例图片')
      return
    }
    
    const now = Date.now()
    const oneDayMs = 24 * 60 * 60 * 1000
    
    // 生成示例图片（纯色渐变）
    let sampleImagePath: string | null = null
    try {
      // 生成一张渐变色图片（蓝色到紫色渐变）
      sampleImagePath = await ImageGenerator.generateGradientImage(
        this.context,
        800,  // 宽度
        600,  // 高度
        0xFF4A90E2,  // 起始颜色：蓝色
        0xFF9B59B6,  // 结束颜色：紫色
        'sample_gradient.png'
      )
      
      if (sampleImagePath) {
        console.info('[NowViewModel] 示例图片生成成功: ' + sampleImagePath)
      } else {
        console.warn('[NowViewModel] 示例图片生成失败')
      }
    } catch (error) {
      console.error('[NowViewModel] 生成示例图片异常: ' + JSON.stringify(error))
    }
    
    const rm = this.context?.resourceManager
    const sampleRecords: LifeRecord[] = [
      {
        id: this.generateId(),
        timestamp: now,
        content: rm?.getStringByNameSync('sample_record_1') ?? '',
        tags: ['life', 'entertainment']
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs,
        content: rm?.getStringByNameSync('sample_record_2') ?? '',
        tags: ['life', 'study'],
        imagePaths: sampleImagePath ? [sampleImagePath] : undefined  // 添加示例图片
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 3,
        content: rm?.getStringByNameSync('sample_record_3') ?? '',
        tags: ['travel', 'food'],
        imagePaths: sampleImagePath ? [sampleImagePath,sampleImagePath,sampleImagePath,sampleImagePath] : undefined  // 添加示例图片
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 35,
        content: rm?.getStringByNameSync('sample_record_4') ?? '',
        tags: ['work', 'health']
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 365,
        content: rm?.getStringByNameSync('sample_record_5') ?? '',
        tags: ['family']
      },
      {
        id: this.generateId(),
        timestamp: now - oneDayMs * 365 * 2,
        content: rm?.getStringByNameSync('sample_record_6') ?? '',
        tags: ['life']
      }
    ]
    
    this.records = sampleRecords
    await this.saveRecords()
    console.info('[NowViewModel] 示例数据初始化完成')
  }
  
  // 保存记录
  private async saveRecords(): Promise<boolean> {
    // 如果 prefs 未初始化，尝试重新初始化
    if (!this.context) {
      console.warn('[NowViewModel] context 未初始化，尝试重新初始化')
      await this.init()
    }
    
    if (!this.context) {
      console.error('[NowViewModel] context 仍然未初始化，保存失败')
      return false
    }
    
    try {
      const success = await RecordRepository.saveRecords(this.context, this.records)
      if (success) {
        console.info('[NowViewModel] 记录保存成功，数量: ' + this.records.length)
      }
      return success
    } catch (error) {
      console.error('[NowViewModel] 保存记录失败: ' + JSON.stringify(error))
      return false
    }
  }
  
  // 获取所有记录
  getRecords(): LifeRecord[] {
    return this.records
  }
  
  // 添加记录
  async addRecord(content: string, imagePaths?: string[], tags?: string[]): Promise<LifeRecord | null> {
    const record: LifeRecord = {
      id: this.generateId(),
      timestamp: Date.now(),
      content: content,
      imagePaths: imagePaths,
      tags: tags
    }
    
    this.records.unshift(record) // 添加到开头
    const success = await this.saveRecords()
    
    if (success) {
      return record
    } else {
      // 保存失败，移除添加的记录
      this.records.shift()
      return null
    }
  }
  
  // 更新记录
  async updateRecord(id: string, content: string, imagePaths?: string[], tags?: string[]): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === id)
    if (index === -1) {
      console.error('[NowViewModel] 未找到记录: ' + id)
      return false
    }
    
    const record = this.records[index]
    
    // 更新文字内容
    record.content = content
    
    // 更新标签
    if (tags !== undefined) {
      record.tags = tags.length > 0 ? tags : undefined
    }
    
    // 处理图片路径更新
    if (imagePaths !== undefined) {
      // 删除不再使用的图片文件
      if (record.imagePaths) {
        for (const oldPath of record.imagePaths) {
          // 如果新图片列表中不包含这张图片，则删除
          if (!imagePaths.includes(oldPath)) {
            try {
              const sandboxPath = this.uriToSandboxPath(oldPath)
              if (this.context && fileIo.accessSync(sandboxPath)) {
                fileIo.unlinkSync(sandboxPath)
                console.info('[NowViewModel] 图片文件已删除: ' + sandboxPath)
              }
            } catch (error) {
              console.error('[NowViewModel] 删除图片文件失败: ' + JSON.stringify(error))
            }
          }
        }
      }
      
      // 更新图片路径列表
      if (imagePaths.length === 0) {
        record.imagePaths = undefined
      } else {
        record.imagePaths = imagePaths
      }
    }
    
    return await this.saveRecords()
  }
  
  // 切换收藏/置顶状态
  async togglePin(id: string): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === id)
    if (index === -1) {
      console.error('[NowViewModel] 未找到记录: ' + id)
      return false
    }

    const record = this.records[index]
    record.isPinned = !record.isPinned
    console.info('[NowViewModel] 记录' + id + ' 收藏状态切换为: ' + record.isPinned)

    return await this.saveRecords()
  }

  // 获取所有收藏的记录
  getPinnedRecords(): LifeRecord[] {
    return this.records.filter(r => r.isPinned === true)
  }

  // 删除记录
  async deleteRecord(id: string): Promise<boolean> {
    const index = this.records.findIndex(r => r.id === id)
    if (index === -1) {
      console.error('[NowViewModel] 未找到记录: ' + id)
      return false
    }
    
    const record = this.records[index]
    
    // 如果有图片，删除所有图片文件
    if (record.imagePaths && record.imagePaths.length > 0) {
      for (const imagePath of record.imagePaths) {
        try {
          const sandboxPath = this.uriToSandboxPath(imagePath)
          if (this.context && fileIo.accessSync(sandboxPath)) {
            fileIo.unlinkSync(sandboxPath)
            console.info('[NowViewModel] 图片文件已删除: ' + sandboxPath)
          }
        } catch (error) {
          console.error('[NowViewModel] 删除图片文件失败: ' + JSON.stringify(error))
        }
      }
    }
    
    this.records.splice(index, 1)
    return await this.saveRecords()
  }
  
  // 构建时间线数据
  buildTimeline(): TimelineData {
    const now = TimeUtils.now()
    const currentYear = TimeUtils.getFullYear(now)
    const currentMonth = TimeUtils.getMonth(now)
    
    // 按年月日分组
    const yearMap = new Map<number, Map<number, Map<number, LifeRecord[]>>>()
    
    for (const record of this.records) {
      const date = new Date(record.timestamp)
      const year = date.getFullYear()
      const month = date.getMonth() + 1
      const day = date.getDate()
      
      if (!yearMap.has(year)) {
        yearMap.set(year, new Map<number, Map<number, LifeRecord[]>>())
      }
      
      const monthMap = yearMap.get(year)!
      if (!monthMap.has(month)) {
        monthMap.set(month, new Map<number, LifeRecord[]>())
      }
      
      const dayMap = monthMap.get(month)!
      if (!dayMap.has(day)) {
        dayMap.set(day, [])
      }
      
      dayMap.get(day)!.push(record)
    }
    
    // 构建时间线结构
    const years: TimelineYear[] = []
    const sortedYears = Array.from(yearMap.keys()).sort((a, b) => b - a) // 降序
    
    for (const year of sortedYears) {
      const monthMap = yearMap.get(year)!
      const months: TimelineMonth[] = []
      const sortedMonths = Array.from(monthMap.keys()).sort((a, b) => b - a)
      
      for (const month of sortedMonths) {
        const dayMap = monthMap.get(month)!
        const days: TimelineDay[] = []
        const sortedDays = Array.from(dayMap.keys()).sort((a, b) => b - a)
        
        for (const day of sortedDays) {
          const records = dayMap.get(day)!
          days.push({
            day: day,
            records: records,
            isExpanded: false // 默认折叠
          })
        }
        
        months.push({
          month: month,
          days: days,
          isExpanded: false // 默认折叠
        })
      }
      
      years.push({
        year: year,
        months: months,
        isExpanded: year === currentYear // 当前年份默认展开
      })
    }
    
    // 如果有当前年份，展开当前月份
    if (years.length > 0 && years[0].year === currentYear) {
      const currentYearNode = years[0]
      for (const monthNode of currentYearNode.months) {
        if (monthNode.month === currentMonth) {
          monthNode.isExpanded = true
          break
        }
      }
    }
    
    return { years: years }
  }
  
  // 保存图片到沙箱目录（返回 URI 格式）
  async saveImageToSandbox(sourceUri: string): Promise<string | null> {
    if (!this.context) {
      console.error('[NowViewModel] context 未初始化')
      return null
    }
    
    let sourceFile: fileIo.File | null = null
    try {
      // 打开源图片
      sourceFile = fileIo.openSync(sourceUri, fileIo.OpenMode.READ_ONLY)
      
      // 生成文件名
      const timestamp = Date.now()
      const fileName = `record_${timestamp}.jpg`
      const sandboxPath = `${this.context.filesDir}/records/${fileName}`
      
      // 确保目录存在
      const dirPath = `${this.context.filesDir}/records`
      if (!fileIo.accessSync(dirPath)) {
        fileIo.mkdirSync(dirPath)
      }
      
      // 复制文件
      fileIo.copyFileSync(sourceFile.fd, sandboxPath)
      console.info('[NowViewModel] 图片保存成功: ' + sandboxPath)
      
      // 返回 URI 格式（统一路径格式）
      const imageUri = fileUri.getUriFromPath(sandboxPath)
      console.info('[NowViewModel] 图片 URI: ' + imageUri)
      
      return imageUri
    } catch (error) {
      console.error('[NowViewModel] 保存图片失败: ' + JSON.stringify(error))
      return null
    } finally {
      if (sourceFile) {
        try {
          fileIo.closeSync(sourceFile)
        } catch (error) {
          console.error('[NowViewModel] 关闭文件失败: ' + JSON.stringify(error))
        }
      }
    }
  }
  
  // 获取图片 URI（用于显示）
  // 注：新记录已统一为 URI 格式，此方法保留用于兼容旧数据
  getImageUri(path: string): string {
    if (path.startsWith('file://')) {
      return path  // 已经是 URI 格式
    }
    try {
      return fileUri.getUriFromPath(path)  // 兼容旧的沙箱路径格式
    } catch (error) {
      console.error('[NowViewModel] 获取图片URI失败: ' + JSON.stringify(error))
      return path
    }
  }
  
  // 将 URI 转换为沙箱路径（用于文件操作）
  private uriToSandboxPath(uri: string): string {
    if (uri.startsWith('file://')) {
      // URI 格式: file://<bundleName>/data/storage/... 或 file:///data/storage/...
      let path = uri.substring(7)  // 移除 'file://'
      
      // 找到第一个 '/' 的位置，从那里开始截取路径
      const slashIndex = path.indexOf('/')
      if (slashIndex !== -1) {
        path = path.substring(slashIndex)
      }
      
      return path
    }
    return uri  // 已经是沙箱路径格式
  }
  
  // 生成唯一ID
  private generateId(): string {
    return Date.now().toString(36) + Math.random().toString(36).substring(2)
  }
  
  // 获取上下文
  getContext(): common.UIAbilityContext | null {
    return this.context
  }
}
