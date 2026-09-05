// 主入口文件：MainPage.ets
import { HomePage } from './HomePage'
import { NowPage } from './NowPage'
import { AccountPage } from './AccountPage'
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 自定义TabBar图标组件
  @Builder
  TabBarBuilder(title: ResourceStr, icon: Resource, index: number) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.currentIndex === index ? this.themeColors.primary : this.themeColors.textSecondary])
      
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? this.themeColors.primary : this.themeColors.textSecondary)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  // 页面显示时：消费桌面卡片「快速记录」标记，切到「此刻」页由 NowPage 打开新建弹窗
  onPageShow() {
    const cardQuickRecord = AppStorage.get('cardQuickRecord') as boolean | undefined
    if (cardQuickRecord === true) {
      this.currentIndex = 1
    }
    // 首页可见性广播：驱动 HomePage 每秒定时器启停（云测功耗：不可见时停止动效）
    this.syncHomeVisible()
  }

  // 页面离开（退后台/切页）：首页定时器应停止
  onPageHide() {
    AppStorage.setOrCreate('homeVisible', false)
  }

  aboutToAppear() {
    AppStorage.setOrCreate('homeVisible', this.currentIndex === 0)
  }

  // 首页（Tab 0）可见与否 → AppStorage，HomePage @StorageLink 响应启停定时器
  private syncHomeVisible(): void {
    AppStorage.setOrCreate('homeVisible', this.currentIndex === 0)
  }

  build() {
    Tabs({
      barPosition: BarPosition.End,
      index: this.currentIndex
    }) {
      TabContent() {
        HomePage()
      }.tabBar(this.TabBarBuilder($r('app.string.tab_home'), $r('sys.symbol.house'), 0))

      TabContent() {
        NowPage()
      }.tabBar(this.TabBarBuilder($r('app.string.tab_now'), $r('sys.symbol.clock'), 1))

      TabContent() {
        AccountPage()
      }.tabBar(this.TabBarBuilder($r('app.string.tab_account'), $r('sys.symbol.person'), 2))
    }
    .onChange((index: number) => {
      this.currentIndex = index
      this.syncHomeVisible()
    })
  }
}
