import Foundation
import ActivityKit
import Combine

final class LiveActivityManager: ObservableObject {
    static let shared = LiveActivityManager()
    
    private var currentActivity: Activity<LeashActivityAttributes>?
    
    private init() {}
    
    func startActivity(role: String, peerName: String, distanceText: String, isAlarmTriggered: Bool, thresholdText: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        endActivity()
        
        let attributes = LeashActivityAttributes(initialRole: role)
        let initialContentState = LeashActivityAttributes.ContentState(
            distanceText: distanceText,
            isAlarmTriggered: isAlarmTriggered,
            peerName: peerName,
            roleText: role,
            alarmThresholdText: thresholdText
        )
        
        do {
            let activity = try Activity<LeashActivityAttributes>.request(
                attributes: attributes,
                content: .init(state: initialContentState, staleDate: nil),
                pushType: nil
            )
            self.currentActivity = activity
        } catch {
            print("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
    
    func update(distanceText: String, isAlarmTriggered: Bool, peerName: String, roleText: String, thresholdText: String) {
        guard let activity = currentActivity else { return }
        
        let updatedState = LeashActivityAttributes.ContentState(
            distanceText: distanceText,
            isAlarmTriggered: isAlarmTriggered,
            peerName: peerName,
            roleText: roleText,
            alarmThresholdText: thresholdText
        )
        
        Task {
            await activity.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func endActivity() {
        guard let activity = currentActivity else { return }
        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        self.currentActivity = nil
    }
}
