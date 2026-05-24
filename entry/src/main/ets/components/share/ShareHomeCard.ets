// 分享首页卡片组件：components/share/ShareHomeCard.ets
// 专门用于生成首页分享图片的组件
import { TimeData } from '../../common/types'
import { ThemeColors, ThemeConfig } from '../../config/ThemeConfig'

@Component
export struct ShareHomeCard {
  @Prop birthDate: Date = new Date('1990-01-01T00:00:00Z')
  @Prop targetAge: number = 80
  @Prop timeData: TimeData = {
    years: 0,
    months: 0,
    days: 0,
    hours: 0,
    minutes: 0,
    seconds: 0
  }
  @Prop isRemainingMode: boolean = false
  @Prop isAccumulatedMode: boolean = true
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)
  
  build() {
    Column() {
      // 顶部标题栏
      Row() {
        // App Logo 和名称
        Row({ space: 8 }) {
          Text('⏱️')
            .fontSize(20)
          
          Column() {
            Text('活着')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#333333')
            
            Text(this.formatDateTime(new Date()))
              .fontSize(11)
              .fontColor('#999999')
          }
          .alignItems(HorizontalAlign.Start)
        }
        
        Blank()
        
        // 水印
        Text('RecordLife')
          .fontSize(10)
          .fontColor('#CCCCCC')
      }
      .width('100%')
      .padding({ left: 20, right: 20, top: 16, bottom: 12 })
      
      // 分隔线
      Divider()
        .color('#EEEEEE')
        .margin({ left: 20, right: 20 })
      
      // 内容区域
      Column() {
        // 目标年龄
        Row({ space: 8 }) {
          Text('🎯')
            .fontSize(14)
          
          Text(`目标年龄: ${this.targetAge}岁`)
            .fontSize(13)
            .fontColor('#666666')
        }
        .width('100%')
        .margin({ bottom: 16 })
        
        // 模式标签
        Row({ space: 8 }) {
          Text(this.isRemainingMode ? '⏳ 剩余时间' : '⏱️ 已存活时间')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor(this.isRemainingMode ? '#4CAF50' : '#F44336')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
          
          Text(this.isAccumulatedMode ? '累计模式' : '非累计模式')
            .fontSize(12)
            .fontColor('#FFFFFF')
            .backgroundColor('#2196F3')
            .padding({ left: 10, right: 10, top: 4, bottom: 4 })
            .borderRadius(12)
        }
        .width('100%')
        .margin({ bottom: 16 })
        
        // 时间数据展示
        Column() {
          // 第一行：年月日
          Row({ space: 8 }) {
            this.TimeItem(this.timeData.years, '年', this.isRemainingMode ? '#4CAF50' : '#F44336')
            this.TimeItem(this.timeData.months, '月', '#FFA726')
            this.TimeItem(this.timeData.days, '日', '#66BB6A')
          }
          .width('100%')
          .margin({ bottom: 8 })
          
          // 第二行：时
          Row({ space: 8 }) {
            this.TimeItem(this.timeData.hours, '小时', '#42A5F5')
          }
          .width('100%')
          // 第三行：分
          Row({ space: 8 }) {
            this.TimeItem(this.timeData.minutes, '分钟', '#AB47BC')
          }
          .width('100%')
          // 第四行：秒
          Row({ space: 8 }) {
            this.TimeItem(this.timeData.seconds, '秒', '#FFEE58')
          }
          .width('100%')
        }
        .width('100%')
      }
      .width('100%')
      .padding(20)
      .alignItems(HorizontalAlign.Start)
      
      // 底部水印
      Row() {
        Blank()
        
        Row({ space: 4 }) {
          Text('来自')
            .fontSize(10)
            .fontColor('#CCCCCC')
          
          Text('RecordLife')
            .fontSize(10)
            .fontColor('#007DFF')
            .fontWeight(FontWeight.Medium)
        }
      }
      .width('100%')
      .padding({ left: 20, right: 20, bottom: 16 })
    }
    .width(340)
    .backgroundColor('#FFFFFF')
    .borderRadius(4)
    .shadow({
      radius: 20,
      color: 'rgba(0, 0, 0, 0.15)',
      offsetX: 0,
      offsetY: 4
    })
  }
  
  // 时间项组件
  @Builder
  TimeItem(value: number, label: string, color: string) {
    Column() {
      Text(value.toString())
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .fontColor(color)
      
      Text(label)
        .fontSize(12)
        .fontColor('#999999')
        .margin({ top: 4 })
    }
    .layoutWeight(1)
    .padding(12)
    .backgroundColor('#F5F5F5')
    .borderRadius(8)
  }
  
  // 格式化出生日期
  private formatBirthDate(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    return `${year}-${month}-${day}`
  }
  
  // 格式化日期时间
  private formatDateTime(date: Date): string {
    const year = date.getFullYear()
    const month = (date.getMonth() + 1).toString().padStart(2, '0')
    const day = date.getDate().toString().padStart(2, '0')
    const hours = date.getHours().toString().padStart(2, '0')
    const minutes = date.getMinutes().toString().padStart(2, '0')
    
    return `${year}-${month}-${day} ${hours}:${minutes}`
  }
}
