import Foundation
import AudioToolbox
import AVFoundation
import UIKit
import Combine

final class LeashAlarmManager: ObservableObject {
    @Published var isAlarmTriggered: Bool = false
    @Published var alarmSettings: LeashAlarmSettings = LeashAlarmSettings(
        isEnabled: false,
        thresholdMeters: 3.0,
        allowSubToViewSettings: true,
        vibrationAlertsEnabled: true,
        soundAlertsEnabled: true
    )
    
    private var alertTimer: Timer?
    private var currentRole: LeashRole?
    private var alertAudioPlayer: AVAudioPlayer?
    
    init() {
        prepareAlertSound()
    }
    
    func updateSettings(_ settings: LeashAlarmSettings) {
        self.alarmSettings = settings
    }
    
    func update(distance: Float?, role: LeashRole?) {
        self.currentRole = role
        
        guard let dist = distance, let role = role, alarmSettings.isEnabled else {
            setTriggered(false)
            return
        }
        
        if dist > alarmSettings.thresholdMeters {
            setTriggered(true)
        } else {
            setTriggered(false)
        }
    }
    
    private func setTriggered(_ triggered: Bool) {
        if triggered != isAlarmTriggered {
            isAlarmTriggered = triggered
            if triggered {
                startAlerts()
            } else {
                stopAlerts()
            }
        }
    }
    
    private func startAlerts() {
        stopAlerts()
        guard let role = currentRole else { return }
        
        switch role {
        case .sub:
            triggerSubAlert()
            alertTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
                self?.triggerSubAlert()
            }
            if let timer = alertTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
            
        case .dom:
            triggerDomAlert()
            alertTimer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
                self?.triggerDomAlert()
            }
            if let timer = alertTimer {
                RunLoop.main.add(timer, forMode: .common)
            }
        }
    }
    
    private func stopAlerts() {
        alertTimer?.invalidate()
        alertTimer = nil
        alertAudioPlayer?.stop()
    }
    
    private func triggerSubAlert() {
        if alarmSettings.vibrationAlertsEnabled {
            AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
            AudioServicesPlaySystemSound(1352)
            let feedback = UINotificationFeedbackGenerator()
            feedback.prepare()
            feedback.notificationOccurred(.error)
        }
        
        if alarmSettings.soundAlertsEnabled {
            playLoudAlarmTone()
        }
    }
    
    private func triggerDomAlert() {
        if alarmSettings.vibrationAlertsEnabled {
            let impact = UIImpactFeedbackGenerator(style: .medium)
            impact.prepare()
            impact.impactOccurred()
        }
    }
    
    private func prepareAlertSound() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            
            let toneData = createAlarmToneWAVData()
            let player = try AVAudioPlayer(data: toneData)
            player.volume = 1.0
            player.prepareToPlay()
            self.alertAudioPlayer = player
        } catch {
            print("Failed to prepare alert sound: \(error.localizedDescription)")
        }
    }
    
    private func playLoudAlarmTone() {
        if alertAudioPlayer == nil {
            prepareAlertSound()
        }
        alertAudioPlayer?.currentTime = 0
        alertAudioPlayer?.play()
    }
    
    private func createAlarmToneWAVData() -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 0.25
        let frequency: Double = 880.0
        let numSamples = Int(sampleRate * duration)
        let subChunk2Size = numSamples * 2
        let chunkSize = 36 + subChunk2Size
        
        var data = Data()
        data.append(contentsOf: "RIFF".utf8)
        var cSize = Int32(chunkSize).littleEndian
        data.append(Data(bytes: &cSize, count: 4))
        data.append(contentsOf: "WAVE".utf8)
        
        data.append(contentsOf: "fmt ".utf8)
        var sub1Size: Int32 = 16
        data.append(Data(bytes: &sub1Size, count: 4))
        var audioFormat: Int16 = 1
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: Int16 = 1
        data.append(Data(bytes: &numChannels, count: 2))
        var sRate = Int32(sampleRate).littleEndian
        data.append(Data(bytes: &sRate, count: 4))
        var byteRate = Int32(sampleRate * 2).littleEndian
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: Int16 = 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: Int16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))
        
        data.append(contentsOf: "data".utf8)
        var s2Size = Int32(subChunk2Size).littleEndian
        data.append(Data(bytes: &s2Size, count: 4))
        
        for i in 0..<numSamples {
            let t = Double(i) / sampleRate
            let angle = 2.0 * .pi * frequency * t
            let sampleVal = sin(angle)
            let intSample = Int16(max(-32767, min(32767, sampleVal * 32000)))
            var littleEndianSample = intSample.littleEndian
            data.append(Data(bytes: &littleEndianSample, count: 2))
        }
        
        return data
    }
    
    func stop() {
        setTriggered(false)
        stopAlerts()
    }
    
    deinit {
        stop()
    }
}
