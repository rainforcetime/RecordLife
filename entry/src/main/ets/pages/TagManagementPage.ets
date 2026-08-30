// 个性化管理页面（标签/心情/模板，页面化替代弹窗，个性化管理 UI 优化）
import { ThemeColors, ThemeConfig } from '../config/ThemeConfig'
import { TagListSection } from '../components/personalization/TagListSection'
import { MoodManageSection } from '../components/personalization/MoodManageSection'
import { TemplateManageSection } from '../components/personalization/TemplateManageSection'

@Entry
@Component
struct TagManagementPage {
  @StorageLink('themeColors') themeColors: ThemeColors = ThemeConfig.getColors(false)

  // 管理分页（0=标签 1=心情 2=模板）
  @State private currentTab: number = 0
  private swiperController: SwiperController = new SwiperController()

  // 将十六进制颜色转换为 rgba 格式
  private hexToRgba(hex: string, alpha: number): string {
    const r = parseInt(hex.slice(1, 3), 16)
    const g = parseInt(hex.slice(3, 5), 16)
    const b = parseInt(hex.slice(5, 7), 16)
    return `rgba(${r}, ${g}, ${b}, ${alpha})`
  }

  build() {
    Column() {
      // 标题栏
      Row() {
        // 返回按钮（44×44 点击区 + 图标 24，与其他子页一致）
        Column() {
          SymbolGlyph($r('sys.symbol.chevron_left'))
            .fontSize(24)
            .fontColor([this.themeColors.textPrimary])
        }
        .width(44)
        .height(44)
        .justifyContent(FlexAlign.Center)
        .onClick(() => {
          this.getUIContext().getRouter().back()
        })

        Text($r('app.string.personalization_management'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.themeColors.textPrimary)
          .margin({ left: 8 })
      }
      .width('100%')
      .height(52)
      .padding({ left: 16, right: 16 })
      .alignItems(VerticalAlign.Center)

      // Tab 分段控件（iOS 分段控件风格；点击切换并联动 Swiper）
      Row() {
        this.TabItem($r('app.string.tag_tab'), 0)
        this.TabItem($r('app.string.mood_tab'), 1)
        this.TabItem($r('app.string.template_tab'), 2)
      }
      .width('100%')
      .padding(4)
      .backgroundColor(this.themeColors.background)
      .borderRadius(12)
      .margin({ left: 20, right: 20, top: 8, bottom: 14 })

      // 内容区（左右滑动切换页签，与分段控件联动）
      Swiper(this.swiperController) {
        Scroll() {
          Column() {
            TagListSection()
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
        .align(Alignment.Top)

        Scroll() {
          Column() {
            MoodManageSection()
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
        .align(Alignment.Top)

        Scroll() {
          Column() {
            TemplateManageSection()
          }
          .width('100%')
          .padding({ left: 20, right: 20 })
        }
        .scrollBar(BarState.Off)
        .width('100%')
        .height('100%')
        .align(Alignment.Top)
      }
      .index(this.currentTab)
      .loop(false)
      .indicator(false)
      .onChange((index: number) => {
        this.currentTab = index
      })
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.themeColors.background)
  }

  @Builder
  TabItem(label: ResourceStr, tabIndex: number) {
    Text(label)
      .fontSize(14)
      .fontColor(this.currentTab === tabIndex ? this.themeColors.primary : this.themeColors.textSecondary)
      .fontWeight(this.currentTab === tabIndex ? FontWeight.Medium : FontWeight.Normal)
      .textAlign(TextAlign.Center)
      .height(32)
      .layoutWeight(1)
      .borderRadius(8)
      .backgroundColor(this.currentTab === tabIndex ? this.hexToRgba(this.themeColors.primary, 0.12) : 'transparent')
      .onClick(() => {
        this.currentTab = tabIndex
        this.swiperController.changeIndex(tabIndex)  // 点击分段同步 Swiper
      })
  }
}
