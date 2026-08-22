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
        .fontColor([this.currentIndex === index ? this.themeColors.primary : this.themeColors.textTertiary])
      
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? this.themeColors.primary : this.themeColors.textTertiary)
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
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
    })
  }
}
