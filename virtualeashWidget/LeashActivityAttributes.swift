import Foundation
import ActivityKit

public struct LeashActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var distanceText: String
        public var isAlarmTriggered: Bool
        public var peerName: String
        public var roleText: String
        public var alarmThresholdText: String
        
        public init(distanceText: String, isAlarmTriggered: Bool, peerName: String, roleText: String, alarmThresholdText: String) {
            self.distanceText = distanceText
            self.isAlarmTriggered = isAlarmTriggered
            self.peerName = peerName
            self.roleText = roleText
            self.alarmThresholdText = alarmThresholdText
        }
    }
    
    public var initialRole: String
    
    public init(initialRole: String) {
        self.initialRole = initialRole
    }
}
