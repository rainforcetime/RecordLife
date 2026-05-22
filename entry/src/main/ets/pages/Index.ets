// 主入口文件：MainPage.ets
import { HomePage } from './HomePage'
import { NowPage } from './NowPage'
import { AccountPage } from './AccountPage'

@Entry
@Component
struct MainPage {
  @State currentIndex: number = 0

  // 自定义TabBar图标组件
  @Builder
  TabBarBuilder(title: string, icon: Resource, index: number) {
    Column() {
      SymbolGlyph(icon)
        .fontSize(24)
        .fontColor([this.currentIndex === index ? '#007DFF' : '#999999'])
      
      Text(title)
        .fontSize(12)
        .fontColor(this.currentIndex === index ? '#007DFF' : '#999999')
        .margin({ top: 4 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
  }

  build() {
    Tabs({
      barPosition: BarPosition.End, // 导航栏在底部
      index: this.currentIndex
    }) {
      TabContent() {
        HomePage()
      }.tabBar(this.TabBarBuilder('首页', $r('sys.symbol.house'), 0))

      TabContent() {
        NowPage()
      }.tabBar(this.TabBarBuilder('现在', $r('sys.symbol.clock'), 1))

      TabContent() {
        AccountPage()
      }.tabBar(this.TabBarBuilder('我的', $r('sys.symbol.person'), 2))
    }
    .onChange((index: number) => {
      this.currentIndex = index
    })
  }
}
