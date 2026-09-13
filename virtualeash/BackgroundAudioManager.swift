import Foundation
import AVFoundation
import Combine

final class BackgroundAudioManager: ObservableObject {
    static let shared = BackgroundAudioManager()
    
    private var audioPlayer: AVAudioPlayer?
    @Published var isRunning: Bool = false
    
    private init() {}
    
    func start() {
        guard !isRunning else { return }
        
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try session.setActive(true)
            
            let silentData = createSilentWAVData()
            let player = try AVAudioPlayer(data: silentData)
            player.numberOfLoops = -1
            player.volume = 0.01
            player.prepareToPlay()
            player.play()
            
            self.audioPlayer = player
            self.isRunning = true
        } catch {
            print("Failed to start background audio: \(error.localizedDescription)")
        }
    }
    
    func stop() {
        audioPlayer?.stop()
        audioPlayer = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRunning = false
    }
    
    private func createSilentWAVData() -> Data {
        let sampleRate: Int32 = 8000
        let durationSeconds: Int = 2
        let numSamples = Int(sampleRate) * durationSeconds
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
        var audioFormat: Int16 = 1 // PCM
        data.append(Data(bytes: &audioFormat, count: 2))
        var numChannels: Int16 = 1 // Mono
        data.append(Data(bytes: &numChannels, count: 2))
        var sRate = sampleRate.littleEndian
        data.append(Data(bytes: &sRate, count: 4))
        var byteRate = (sampleRate * 2).littleEndian
        data.append(Data(bytes: &byteRate, count: 4))
        var blockAlign: Int16 = 2
        data.append(Data(bytes: &blockAlign, count: 2))
        var bitsPerSample: Int16 = 16
        data.append(Data(bytes: &bitsPerSample, count: 2))
        
        data.append(contentsOf: "data".utf8)
        var s2Size = Int32(subChunk2Size).littleEndian
        data.append(Data(bytes: &s2Size, count: 4))
        
        let silence = [UInt8](repeating: 0, count: subChunk2Size)
        data.append(contentsOf: silence)
        
        return data
    }
}
