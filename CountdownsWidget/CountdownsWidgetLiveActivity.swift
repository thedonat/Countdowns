//
//  CountdownsWidgetLiveActivity.swift
//  CountdownsWidget
//
//  Created by Burak Donat on 1/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct CountdownsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct CountdownsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountdownsWidgetAttributes.self) { context in
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

extension CountdownsWidgetAttributes {
    fileprivate static var preview: CountdownsWidgetAttributes {
        CountdownsWidgetAttributes(name: "World")
    }
}

extension CountdownsWidgetAttributes.ContentState {
    fileprivate static var smiley: CountdownsWidgetAttributes.ContentState {
        CountdownsWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: CountdownsWidgetAttributes.ContentState {
         CountdownsWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: CountdownsWidgetAttributes.preview) {
   CountdownsWidgetLiveActivity()
} contentStates: {
    CountdownsWidgetAttributes.ContentState.smiley
    CountdownsWidgetAttributes.ContentState.starEyes
}
