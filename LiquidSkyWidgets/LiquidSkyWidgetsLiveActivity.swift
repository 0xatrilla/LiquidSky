//
//  LiquidSkyWidgetsLiveActivity.swift
//  LiquidSkyWidgets
//
//  Created by Callum Matthews on 28/08/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiquidSkyWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LiquidSkyWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiquidSkyWidgetsAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LiquidSkyWidgetsAttributes {
    fileprivate static var preview: LiquidSkyWidgetsAttributes {
        LiquidSkyWidgetsAttributes(name: "World")
    }
}

extension LiquidSkyWidgetsAttributes.ContentState {
    fileprivate static var smiley: LiquidSkyWidgetsAttributes.ContentState {
        LiquidSkyWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LiquidSkyWidgetsAttributes.ContentState {
         LiquidSkyWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LiquidSkyWidgetsAttributes.preview) {
   LiquidSkyWidgetsLiveActivity()
} contentStates: {
    LiquidSkyWidgetsAttributes.ContentState.smiley
    LiquidSkyWidgetsAttributes.ContentState.starEyes
}
