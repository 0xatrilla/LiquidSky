import SwiftUI
import WidgetKit

@main
struct LiquidSkyWidgetsBundle: WidgetBundle {
  var body: some Widget {
    FollowerCountWidget()
    RecentNotificationWidget()
    FeedUpdatesWidget()
  }
}
