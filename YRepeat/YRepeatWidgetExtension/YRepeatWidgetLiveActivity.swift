//
//  YRepeatWidgetLiveActivity.swift
//  YRepeatWidget
//
//  Created by Dino Pelic on 24. 12. 2025..
//

import ActivityKit
import WidgetKit
import SwiftUI

struct YRepeatWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct YRepeatWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: YRepeatWidgetAttributes.self) { context in
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

extension YRepeatWidgetAttributes {
    fileprivate static var preview: YRepeatWidgetAttributes {
        YRepeatWidgetAttributes(name: "World")
    }
}

extension YRepeatWidgetAttributes.ContentState {
    fileprivate static var smiley: YRepeatWidgetAttributes.ContentState {
        YRepeatWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: YRepeatWidgetAttributes.ContentState {
         YRepeatWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: YRepeatWidgetAttributes.preview) {
   YRepeatWidgetLiveActivity()
} contentStates: {
    YRepeatWidgetAttributes.ContentState.smiley
    YRepeatWidgetAttributes.ContentState.starEyes
}
