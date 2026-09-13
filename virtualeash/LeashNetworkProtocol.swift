import Foundation

enum TrainingToolAction: String, Codable {
    case badStart
    case badStop
    case clicker
}

struct LeashAlarmSettings: Codable, Equatable {
    var isEnabled: Bool = false
    var thresholdMeters: Float = 3.0
    var allowSubToViewSettings: Bool = true
    var vibrationAlertsEnabled: Bool = true
    var soundAlertsEnabled: Bool = true
    var trainingToolsEnabled: Bool = false
}

enum LeashNetworkMessage: Codable {
    case uwbToken(Data)
    case alarmSettings(LeashAlarmSettings)
    case trainingTool(TrainingToolAction)
    
    func encode() throws -> Data {
        let encoder = JSONEncoder()
        return try encoder.encode(self)
    }
    
    static func decode(from data: Data) throws -> LeashNetworkMessage {
        let decoder = JSONDecoder()
        return try decoder.decode(LeashNetworkMessage.self, from: data)
    }
}
