//
//  CountdownsWidgetLiveActivity.swift
//  CountdownsWidget
//
//  Created by Burak Donat on 1/14/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Activity Attributes
struct CountdownsWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var eventDate: Date
        var isEnded: Bool
    }

    // Fixed non-changing properties
    var eventId: String
    var eventName: String
    var categoryRawValue: String
    var categoryIcon: String
}

// MARK: - Helper Extensions for Widget
extension CountdownsWidgetAttributes {
    var categoryColor: Color {
        switch categoryRawValue {
        case "Event": return Color.purple
        case "Birthday": return Color(red: 1.0, green: 0.6, blue: 0.25)
        case "Travel": return Color.blue
        case "Wedding": return Color.red
        case "Holiday": return Color(red: 0.4, green: 0.3, blue: 0.2)
        case "Anniversary": return Color.pink.opacity(0.7)
        case "Family": return Color.green
        case "Payment": return Color.yellow
        default: return Color.purple
        }
    }
}

// MARK: - Live Activity Widget
struct CountdownsWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CountdownsWidgetAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            let startTime: String = {
                let formatter = DateFormatter()
                formatter.dateFormat = "HH:mm"
                return formatter.string(from: context.state.eventDate)
            }()
            let isEnded = context.state.isEnded || context.state.eventDate <= Date()
            
            return DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 2)
                        HStack(spacing: 10) {
                            Image(systemName: context.attributes.categoryIcon)
                                .font(.system(size: 28))
                                .foregroundColor(context.attributes.categoryColor)
                        }
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing, spacing: 0) {
                        Spacer()
                        if isEnded {
                            HStack {
                                Spacer(minLength: 0)
                                Text(startTime)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(context.attributes.categoryColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .layoutPriority(1)
                            }
                        } else {
                            HStack {
                                Spacer(minLength: 0)
                                Text(context.state.eventDate, style: .timer)
                                    .font(.system(size: 22, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(context.attributes.categoryColor)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.6)
                                    .layoutPriority(1)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(spacing: 0) {
                        Text(context.attributes.eventName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 12)
                    .padding(.vertical, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    VStack(spacing: 0) {
                        Spacer(minLength: 2)
                        HStack(spacing: 12) {
                            Text(LocalizedStringKey(context.attributes.categoryRawValue))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Spacer()
                            
                        if isEnded {
                                HStack(spacing: 6) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 14))
                                    Text("Started")
                                        .font(.system(size: 13, weight: .semibold))
                                }
                                .foregroundColor(context.attributes.categoryColor)
                            } else {
                                Text("Starting soon")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.7))
                            }
                        }
                        .padding(.horizontal, 8)
                        Spacer(minLength: 2)
                    }
                }
            } compactLeading: {
                // Compact leading - Icon
                Image(systemName: context.attributes.categoryIcon)
                    .font(.system(size: 14))
                    .foregroundColor(context.attributes.categoryColor)
            } compactTrailing: {
                // Compact trailing - Timer or Started time
                if context.state.isEnded {
                    HStack(spacing: 2) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 10))
                        Text(startTime)
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .monospacedDigit()
                    }
                    .foregroundColor(context.attributes.categoryColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(maxWidth: 44, alignment: .trailing)
                } else {
                    Text(context.state.eventDate, style: .timer)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(context.attributes.categoryColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .frame(maxWidth: 44, alignment: .trailing)
                }
            } minimal: {
                // Minimal - Icon with color indicating status
                Image(systemName: context.state.isEnded ? "play.circle.fill" : context.attributes.categoryIcon)
                    .font(.system(size: 12))
                    .foregroundColor(context.attributes.categoryColor)
            }
            .widgetURL(URL(string: "countdowns://event/\(context.attributes.eventId)"))
            .keylineTint(context.attributes.categoryColor)
        }
    }
}

// MARK: - Lock Screen View
struct LockScreenView: View {
    let context: ActivityViewContext<CountdownsWidgetAttributes>
    
    private var startTimeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: context.state.eventDate)
    }
    
    private var isEnded: Bool {
        context.state.isEnded || context.state.eventDate <= Date()
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Category Icon
            ZStack {
                Circle()
                    .fill(context.attributes.categoryColor.opacity(0.2))
                    .frame(width: 44, height: 44)
                
                Image(systemName: context.attributes.categoryIcon)
                    .font(.system(size: 20))
                    .foregroundColor(context.attributes.categoryColor)
            }

            // Event Info
            VStack(alignment: .leading, spacing: 2) {
                Text(context.attributes.eventName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
                
                Text(LocalizedStringKey(context.attributes.categoryRawValue))
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Countdown Timer or Started indicator - aligned to right edge
            Group {
            if isEnded {
                    HStack(spacing: 6) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(context.attributes.categoryColor)
                        
                    Text("Started \(startTimeString)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(context.attributes.categoryColor)
                    }
                } else {
                    VStack(alignment: .trailing) {
                        Text(context.state.eventDate, style: .timer)
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(context.attributes.categoryColor)
                            .contentTransition(.numericText())
                    }
                }
            }
        }
        .padding(.leading, 16)
        .padding(.trailing, 16)
        .padding(.vertical, 14)
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(.white)
    }
}

// MARK: - Previews
extension CountdownsWidgetAttributes {
    fileprivate static var preview: CountdownsWidgetAttributes {
        CountdownsWidgetAttributes(
            eventId: UUID().uuidString,
            eventName: "Team Meeting",
            categoryRawValue: "Event",
            categoryIcon: "calendar"
        )
    }
}

extension CountdownsWidgetAttributes.ContentState {
    fileprivate static var countdown: CountdownsWidgetAttributes.ContentState {
        CountdownsWidgetAttributes.ContentState(
            eventDate: Date().addingTimeInterval(30 * 60), // 30 minutes from now
            isEnded: false
        )
    }
    
    fileprivate static var ended: CountdownsWidgetAttributes.ContentState {
        CountdownsWidgetAttributes.ContentState(
            eventDate: Date(),
            isEnded: true
        )
    }
}

#Preview("Notification", as: .content, using: CountdownsWidgetAttributes.preview) {
    CountdownsWidgetLiveActivity()
} contentStates: {
    CountdownsWidgetAttributes.ContentState.countdown
    CountdownsWidgetAttributes.ContentState.ended
}
