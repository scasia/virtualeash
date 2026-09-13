import Foundation
import UIKit
import AudioToolbox
import AVFoundation
import Combine

@MainActor
final class LeashTrainingManager: ObservableObject {
    static let shared = LeashTrainingManager()
    
    private var badVibrationTimer: Timer?
    private var clickAudioPlayer: AVAudioPlayer?
    private let rigidFeedback = UIImpactFeedbackGenerator(style: .rigid)
    private let heavyFeedback = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationFeedback = UINotificationFeedbackGenerator()
    
    init() {
        prepareClickSound()
        rigidFeedback.prepare()
        heavyFeedback.prepare()
        notificationFeedback.prepare()
    }
    
    func handleBadStart() {
        stopBadVibration()
        triggerAggressiveVibration()
        
        let timer = Timer(timeInterval: 0.18, repeats: true) { [weak self] _ in
            self?.triggerAggressiveVibration()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.badVibrationTimer = timer
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 12.0) { [weak self] in
            self?.stopBadVibration()
        }
    }
    
    func handleBadStop() {
        stopBadVibration()
    }
    
    private func stopBadVibration() {
        badVibrationTimer?.invalidate()
        badVibrationTimer = nil
    }
    
    private func triggerAggressiveVibration() {
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        AudioServicesPlaySystemSound(1352)
        notificationFeedback.notificationOccurred(.error)
        notificationFeedback.prepare()
    }
    
    func handleClicker() {
        rigidFeedback.impactOccurred(intensity: 1.0)
        rigidFeedback.prepare()
        AudioServicesPlaySystemSound(1104)
        
        if clickAudioPlayer == nil {
            prepareClickSound()
        }
        clickAudioPlayer?.currentTime = 0
        clickAudioPlayer?.play()
    }
    
    private func prepareClickSound() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            
            let wavData = createClickerWAVData()
            let player = try AVAudioPlayer(data: wavData)
            player.volume = 1.0
            player.prepareToPlay()
            self.clickAudioPlayer = player
        } catch {
            print("Failed to prepare clicker sound: \(error.localizedDescription)")
        }
    }
    
    private func createClickerWAVData() -> Data {
        let sampleRate: Double = 44100
        let duration: Double = 0.02
        let frequency: Double = 2800.0
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
            let decay = exp(-t * 260.0)
            let sampleVal = sin(2.0 * .pi * frequency * t) * decay
            let intSample = Int16(max(-32767, min(32767, sampleVal * 32000)))
            var littleEndianSample = intSample.littleEndian
            data.append(Data(bytes: &littleEndianSample, count: 2))
        }
        
        return data
    }
}
