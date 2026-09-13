import Foundation
import NearbyInteraction
import simd
import Combine

enum NIState: Equatable {
    case unsupported
    case idle
    case waitingForPeerToken
    case active
    case outOfRange
    case suspended
    case failed(String)
}

final class NearbyInteractionManager: NSObject, ObservableObject {
    @Published var isSupported: Bool = NISession.isSupported
    @Published var state: NIState = .idle
    @Published var distance: Float? = nil
    @Published var direction: simd_float3? = nil
    @Published var horizontalAngle: Float? = nil
    @Published var errorMessage: String? = nil
    
    private var session: NISession?
    private var peerToken: NIDiscoveryToken?
    
    override init() {
        super.init()
        if !NISession.isSupported {
            state = .unsupported
        }
    }
    
    /// Prepares a fresh NISession and returns the device's serialized discovery token to send to the peer.
    func prepareLocalToken() -> Data? {
        guard NISession.isSupported else {
            state = .unsupported
            return nil
        }
        
        // Invalidate any previous session
        session?.invalidate()
        session = NISession()
        session?.delegate = self
        state = .waitingForPeerToken
        
        guard let token = session?.discoveryToken else {
            errorMessage = "Failed to obtain local UWB discovery token."
            state = .failed(errorMessage ?? "")
            return nil
        }
        
        do {
            let tokenData = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
            return tokenData
        } catch {
            errorMessage = "Failed to encode discovery token: \(error.localizedDescription)"
            state = .failed(errorMessage ?? "")
            return nil
        }
    }
    
    /// Starts UWB ranging using the discovery token received from the peer.
    func startRanging(withPeerTokenData data: Data) {
        guard NISession.isSupported else {
            state = .unsupported
            return
        }
        
        do {
            guard let token = try NSKeyedUnarchiver.unarchivedObject(ofClass: NIDiscoveryToken.self, from: data) else {
                throw NSError(domain: "NearbyInteractionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid peer token."])
            }
            
            self.peerToken = token
            
            // Ensure session is initialized
            if session == nil {
                session = NISession()
                session?.delegate = self
            }
            
            let configuration = NINearbyPeerConfiguration(peerToken: token)
            session?.run(configuration)
            state = .active
            errorMessage = nil
        } catch {
            errorMessage = "Failed to start UWB session: \(error.localizedDescription)"
            state = .failed(errorMessage ?? "")
        }
    }
    
    func stop() {
        session?.invalidate()
        session = nil
        peerToken = nil
        distance = nil
        direction = nil
        horizontalAngle = nil
        if isSupported {
            state = .idle
        }
    }
    
    deinit {
        stop()
    }
}

// MARK: - NISessionDelegate
extension NearbyInteractionManager: NISessionDelegate {
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let object = nearbyObjects.first else { return }
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.distance = object.distance
            self.direction = object.direction
            #if os(iOS)
            if #available(iOS 16.0, *) {
                self.horizontalAngle = object.horizontalAngle
            }
            #endif
            self.state = .active
        }
    }
    
    func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.distance = nil
            self.direction = nil
            self.horizontalAngle = nil
            self.state = .outOfRange
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        DispatchQueue.main.async { [weak self] in
            self?.state = .suspended
        }
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, let peerToken = self.peerToken else { return }
            let config = NINearbyPeerConfiguration(peerToken: peerToken)
            self.session?.run(config)
            self.state = .active
        }
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.distance = nil
            self.direction = nil
            self.horizontalAngle = nil
            self.errorMessage = error.localizedDescription
            self.state = .failed(error.localizedDescription)
        }
    }
}
