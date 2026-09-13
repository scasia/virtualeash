import Foundation
import SwiftUI
import Combine
import simd
import MultipeerConnectivity

enum DistanceUnit: String, CaseIterable {
    case meters = "Meters"
    case feet = "Feet"
}

@MainActor
final class LeashViewModel: ObservableObject {
    @Published var selectedRole: LeashRole? = nil
    @Published var unit: DistanceUnit = .meters
    @Published var hapticsEnabled: Bool = true
    
    @ObservedObject var multipeerManager = MultipeerSessionManager()
    @ObservedObject var nearbyManager = NearbyInteractionManager()
    @ObservedObject var alarmManager = LeashAlarmManager()
    
    private var cancellables = Set<AnyCancellable>()
    private var lastHapticDistance: Float? = nil
    
    init() {
        setupBindings()
        
        if multipeerManager.isAutoPairEnabled, let saved = multipeerManager.role {
            self.selectedRole = saved
            _ = multipeerManager.autoStartIfPaired()
        }
    }
    
    private func setupBindings() {
        multipeerManager.onPeerConnected = { [weak self] peerID in
            guard let self = self else { return }
            
            BackgroundAudioManager.shared.start()
            
            if let tokenData = self.nearbyManager.prepareLocalToken() {
                try? self.multipeerManager.send(message: .uwbToken(tokenData))
            }
            
            if self.selectedRole == .dom {
                try? self.multipeerManager.send(message: .alarmSettings(self.alarmManager.alarmSettings))
            }
            
            LiveActivityManager.shared.startActivity(
                role: self.selectedRole?.shortTitle ?? "Leash",
                peerName: peerID.displayName,
                distanceText: "--",
                isAlarmTriggered: false,
                thresholdText: String(format: "%.1fm", self.alarmManager.alarmSettings.thresholdMeters)
            )
        }
        
        multipeerManager.onMessageReceived = { [weak self] message, peerID in
            guard let self = self else { return }
            switch message {
            case .uwbToken(let data):
                self.nearbyManager.startRanging(withPeerTokenData: data)
            case .alarmSettings(let settings):
                if self.selectedRole == .sub {
                    self.alarmManager.updateSettings(settings)
                    self.alarmManager.update(distance: self.nearbyManager.distance, role: self.selectedRole)
                    self.handleDistanceUpdate()
                    self.objectWillChange.send()
                }
            case .trainingTool(let action):
                if self.selectedRole == .sub {
                    switch action {
                    case .badStart:
                        LeashTrainingManager.shared.handleBadStart()
                    case .badStop:
                        LeashTrainingManager.shared.handleBadStop()
                    case .clicker:
                        LeashTrainingManager.shared.handleClicker()
                    }
                }
            }
        }
        
        multipeerManager.onPeerDisconnected = { [weak self] peerID in
            guard let self = self else { return }
            self.nearbyManager.stop()
            self.alarmManager.stop()
            LiveActivityManager.shared.endActivity()
        }
        
        multipeerManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
            
        nearbyManager.objectWillChange
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.handleDistanceUpdate()
                self.objectWillChange.send()
            }
            .store(in: &cancellables)
            
        alarmManager.objectWillChange
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }
    
    private func handleDistanceUpdate() {
        let dist = nearbyManager.distance
        alarmManager.update(distance: dist, role: selectedRole)
        triggerHapticsIfNeeded()
        
        if let peer = connectedPeerName {
            let thresholdDisplay: String
            if selectedRole == .sub && !alarmManager.alarmSettings.allowSubToViewSettings {
                thresholdDisplay = "Private"
            } else {
                thresholdDisplay = String(format: "%.1fm", alarmManager.alarmSettings.thresholdMeters)
            }
            
            LiveActivityManager.shared.update(
                distanceText: formattedDistance,
                isAlarmTriggered: alarmManager.isAlarmTriggered,
                peerName: peer,
                roleText: selectedRole?.shortTitle ?? "Leash",
                thresholdText: thresholdDisplay
            )
        }
    }
    
    // MARK: - User Actions
    
    func selectRole(_ role: LeashRole) {
        self.selectedRole = role
        multipeerManager.start(role: role)
    }
    
    func disconnect() {
        multipeerManager.stop()
        nearbyManager.stop()
        alarmManager.stop()
        BackgroundAudioManager.shared.stop()
        LiveActivityManager.shared.endActivity()
        selectedRole = nil
        lastHapticDistance = nil
    }
    
    func unpair() {
        multipeerManager.unpair()
        nearbyManager.stop()
        alarmManager.stop()
        BackgroundAudioManager.shared.stop()
        LiveActivityManager.shared.endActivity()
        selectedRole = nil
        lastHapticDistance = nil
    }
    
    func toggleUnit() {
        unit = (unit == .meters) ? .feet : .meters
    }
    
    // MARK: - Dom-Only Alarm Controls
    
    func setAlarmEnabled(_ enabled: Bool) {
        guard selectedRole == .dom else { return }
        var settings = alarmManager.alarmSettings
        settings.isEnabled = enabled
        alarmManager.updateSettings(settings)
        alarmManager.update(distance: nearbyManager.distance, role: selectedRole)
        try? multipeerManager.send(message: .alarmSettings(settings))
    }
    
    func setAlarmThreshold(_ threshold: Float) {
        guard selectedRole == .dom else { return }
        var settings = alarmManager.alarmSettings
        settings.thresholdMeters = threshold
        alarmManager.updateSettings(settings)
        alarmManager.update(distance: nearbyManager.distance, role: selectedRole)
        try? multipeerManager.send(message: .alarmSettings(settings))
    }
    
    func setAllowSubToViewSettings(_ allowed: Bool) {
        guard selectedRole == .dom else { return }
        var settings = alarmManager.alarmSettings
        settings.allowSubToViewSettings = allowed
        alarmManager.updateSettings(settings)
        try? multipeerManager.send(message: .alarmSettings(settings))
    }
    
    func setVibrationAlertsEnabled(_ enabled: Bool) {
        guard selectedRole == .dom else { return }
        var settings = alarmManager.alarmSettings
        settings.vibrationAlertsEnabled = enabled
        alarmManager.updateSettings(settings)
        try? multipeerManager.send(message: .alarmSettings(settings))
    }
    
    func setSoundAlertsEnabled(_ enabled: Bool) {
        guard selectedRole == .dom else { return }
        var settings = alarmManager.alarmSettings
        settings.soundAlertsEnabled = enabled
        alarmManager.updateSettings(settings)
        try? multipeerManager.send(message: .alarmSettings(settings))
    }
    
    func setTrainingToolsEnabled(_ enabled: Bool) {
        guard selectedRole == .dom else { return }
        var settings = alarmManager.alarmSettings
        settings.trainingToolsEnabled = enabled
        alarmManager.updateSettings(settings)
        try? multipeerManager.send(message: .alarmSettings(settings))
    }
    
    func sendTrainingToolAction(_ action: TrainingToolAction) {
        guard selectedRole == .dom else { return }
        
        switch action {
        case .badStart:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .badStop:
            break
        case .clicker:
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
        }
        
        try? multipeerManager.send(message: .trainingTool(action), mode: .unreliable)
    }
    
    // MARK: - Computed Properties for UI
    
    var isUWBSupported: Bool {
        nearbyManager.isSupported
    }
    
    var connectedPeerName: String? {
        multipeerManager.connectedPeer?.displayName
    }
    
    var distance: Float? {
        nearbyManager.distance
    }
    
    var distanceValueString: String {
        guard let dist = distance else { return "--" }
        switch unit {
        case .meters:
            return String(format: "%.1f", dist)
        case .feet:
            let feet = dist * 3.28084
            return String(format: "%.1f", feet)
        }
    }
    
    var distanceUnitString: String {
        guard distance != nil else { return "" }
        switch unit {
        case .meters:
            return "m"
        case .feet:
            return "ft"
        }
    }
    
    var formattedDistance: String {
        guard distance != nil else { return "--" }
        return "\(distanceValueString) \(distanceUnitString)"
    }
    
    var directionAngleDegrees: Double? {
        if let angle = nearbyManager.horizontalAngle {
            return Double(angle) * 180.0 / .pi
        }
        if let dir = nearbyManager.direction {
            let rad = atan2(Double(dir.x), Double(-dir.z))
            return rad * 180.0 / .pi
        }
        return nil
    }
    
    var hasLineOfSight: Bool {
        nearbyManager.direction != nil || nearbyManager.horizontalAngle != nil
    }
    
    var isAlarmTriggered: Bool {
        alarmManager.isAlarmTriggered
    }
    
    var alarmSettings: LeashAlarmSettings {
        alarmManager.alarmSettings
    }
    
    var statusTitle: String {
        if isAlarmTriggered {
            return selectedRole == .sub ? "OUT OF BOUNDS!" : "LEASH ALARM TRIGGERED"
        }
        
        guard let role = selectedRole else {
            return "Choose Your Role"
        }
        
        switch multipeerManager.connectionState {
        case .idle:
            return "Ready"
        case .searchingOrAdvertising:
            return role == .dom ? "Waiting for Sub..." : "Searching for Dom..."
        case .connecting(let peer):
            return "Connecting to \(peer)..."
        case .connected(let peer):
            if nearbyManager.state == .active {
                return "Leash Active"
            } else if nearbyManager.state == .waitingForPeerToken {
                return "Syncing UWB Tokens..."
            } else if nearbyManager.state == .outOfRange {
                return "Out of Range"
            } else {
                return "Connected to \(peer)"
            }
        case .disconnected:
            return "Disconnected"
        case .error(let msg):
            return "Connection Error"
        }
    }
    
    var statusSubtitle: String {
        if isAlarmTriggered {
            if selectedRole == .sub {
                return "You exceeded the maximum distance of \(String(format: "%.1f", alarmSettings.thresholdMeters))m. Return closer to Dom!"
            } else {
                return "Sub has strayed beyond \(String(format: "%.1f", alarmSettings.thresholdMeters))m!"
            }
        }
        
        guard let role = selectedRole else {
            return "Select whether this iPhone will act as the Host (Dom) or Guest (Sub)."
        }
        
        switch multipeerManager.connectionState {
        case .idle:
            return "Select a role to start."
        case .searchingOrAdvertising:
            return role == .dom
                ? "Broadcasting as Dom. Waiting for Sub to reconnect..."
                : "Scanning for Dom host on local Wi-Fi / Bluetooth..."
        case .connecting(let peer):
            return "Handshaking with \(peer)..."
        case .connected(let peer):
            if nearbyManager.state == .active {
                return "UWB ranging active with \(peer)."
            } else if nearbyManager.state == .waitingForPeerToken {
                return "Exchanging Ultra-Wideband encryption tokens..."
            } else if nearbyManager.state == .outOfRange {
                return "Peer is too far or line of sight is obstructed."
            } else {
                return "Paired via MultipeerConnectivity."
            }
        case .disconnected:
            return "Peer device disconnected. Auto-reconnecting..."
        case .error(let msg):
            return msg
        }
    }
    
    var proximityColor: Color {
        if isAlarmTriggered {
            return .red
        }
        guard let dist = distance else { return .secondary }
        if dist < 1.0 {
            return .green
        } else if dist < 3.0 {
            return .blue
        } else if dist < 6.0 {
            return .orange
        } else {
            return .red
        }
    }
    
    private func triggerHapticsIfNeeded() {
        guard hapticsEnabled, let current = distance, !isAlarmTriggered else { return }
        if let last = lastHapticDistance {
            if abs(current - last) >= 0.5 {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
                lastHapticDistance = current
            }
        } else {
            lastHapticDistance = current
        }
    }
}
