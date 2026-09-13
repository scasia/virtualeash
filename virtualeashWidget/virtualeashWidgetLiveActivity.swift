import WidgetKit
import SwiftUI
import ActivityKit

struct virtualeashWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LeashActivityAttributes.self) { context in
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(context.state.isAlarmTriggered ? Color.red.opacity(0.2) : Color.purple.opacity(0.15))
                        .frame(width: 48, height: 48)
                    Image(systemName: context.state.isAlarmTriggered ? "exclamationmark.triangle.fill" : "link.circle.fill")
                        .font(.title2)
                        .foregroundColor(context.state.isAlarmTriggered ? .red : .purple)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text(context.state.roleText)
                            .font(.caption.bold())
                            .foregroundColor(context.state.isAlarmTriggered ? .red : .purple)
                        Text("•")
                            .foregroundColor(.secondary)
                        Text(context.state.peerName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Text(context.state.distanceText)
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundColor(context.state.isAlarmTriggered ? .red : .primary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    if context.state.isAlarmTriggered {
                        Text("TOO FAR")
                            .font(.caption.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    } else {
                        Text("Limit: \(context.state.alarmThresholdText)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .activityBackgroundTint(Color(uiColor: .secondarySystemBackground))
            
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    HStack {
                        Image(systemName: context.state.isAlarmTriggered ? "exclamationmark.triangle.fill" : "antenna.radiowaves.left.and.right")
                            .foregroundColor(context.state.isAlarmTriggered ? .red : .purple)
                        Text(context.state.roleText)
                            .font(.caption.bold())
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(context.state.peerName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Text(context.state.distanceText)
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(context.state.isAlarmTriggered ? .red : .primary)
                        Spacer()
                        if context.state.isAlarmTriggered {
                            Text("RETURN TO DOM!")
                                .font(.headline.bold())
                                .foregroundColor(.red)
                        } else {
                            Text("Max Limit: \(context.state.alarmThresholdText)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal)
                }
            } compactLeading: {
                Image(systemName: context.state.isAlarmTriggered ? "exclamationmark.triangle.fill" : "link")
                    .foregroundColor(context.state.isAlarmTriggered ? .red : .purple)
            } compactTrailing: {
                Text(context.state.distanceText)
                    .font(.caption.bold())
                    .foregroundColor(context.state.isAlarmTriggered ? .red : .primary)
            } minimal: {
                Image(systemName: context.state.isAlarmTriggered ? "exclamationmark.triangle.fill" : "link")
                    .foregroundColor(context.state.isAlarmTriggered ? .red : .purple)
            }
        }
    }
}

@main
struct virtualeashWidgetBundle: WidgetBundle {
    var body: some Widget {
        virtualeashWidgetLiveActivity()
    }
}
