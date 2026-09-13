import Foundation
import MultipeerConnectivity
import Combine
import UIKit

enum LeashRole: String, CaseIterable, Identifiable {
    case dom = "Dom (Host)"
    case sub = "Sub (Guest)"
    
    var id: String { rawValue }
    
    var shortTitle: String {
        switch self {
        case .dom: return "Dom"
        case .sub: return "Sub"
        }
    }
    
    var description: String {
        switch self {
        case .dom:
            return "Hosts the session. Advertises and waits for Sub to connect."
        case .sub:
            return "Searches for nearby Dom devices and connects automatically."
        }
    }
}

enum MultipeerConnectionState: Equatable {
    case idle
    case searchingOrAdvertising(role: LeashRole)
    case connecting(peerName: String)
    case connected(peerName: String)
    case disconnected
    case error(String)
}

final class MultipeerSessionManager: NSObject, ObservableObject {
    static let serviceType = "virtual-leash"
    
    // UserDefaults Keys for Persistent Pairing
    private let kSavedRole = "virtualeash.savedRole"
    private let kSavedPeerName = "virtualeash.savedPeerName"
    private let kIsAutoPairEnabled = "virtualeash.isAutoPairEnabled"
    
    @Published var connectionState: MultipeerConnectionState = .idle
    @Published var connectedPeer: MCPeerID? = nil
    @Published var role: LeashRole? = nil
    @Published var savedPeerName: String? = nil
    @Published var isAutoPairEnabled: Bool = false
    
    private let myPeerID: MCPeerID
    private var session: MCSession?
    private var advertiser: MCNearbyServiceAdvertiser?
    private var browser: MCNearbyServiceBrowser?
    
    var onPeerConnected: ((MCPeerID) -> Void)?
    var onPeerDisconnected: ((MCPeerID) -> Void)?
    var onMessageReceived: ((LeashNetworkMessage, MCPeerID) -> Void)?
    
    override init() {
        let deviceName = UIDevice.current.name
        self.myPeerID = MCPeerID(displayName: deviceName)
        super.init()
        loadPersistence()
    }
    
    // MARK: - Persistence
    
    private func loadPersistence() {
        let defaults = UserDefaults.standard
        self.isAutoPairEnabled = defaults.bool(forKey: kIsAutoPairEnabled)
        self.savedPeerName = defaults.string(forKey: kSavedPeerName)
        if let rawRole = defaults.string(forKey: kSavedRole), let loadedRole = LeashRole(rawValue: rawRole) {
            self.role = loadedRole
        }
    }
    
    func autoStartIfPaired() -> Bool {
        guard isAutoPairEnabled, let savedRole = role else { return false }
        start(role: savedRole)
        return true
    }
    
    private func savePairing(peerName: String, role: LeashRole) {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: kIsAutoPairEnabled)
        defaults.set(peerName, forKey: kSavedPeerName)
        defaults.set(role.rawValue, forKey: kSavedRole)
        self.isAutoPairEnabled = true
        self.savedPeerName = peerName
    }
    
    func unpair() {
        stop()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: kIsAutoPairEnabled)
        defaults.removeObject(forKey: kSavedPeerName)
        defaults.removeObject(forKey: kSavedRole)
        self.isAutoPairEnabled = false
        self.savedPeerName = nil
        self.role = nil
        self.connectionState = .idle
    }
    
    // MARK: - Lifecycle
    
    func start(role: LeashRole) {
        stop()
        self.role = role
        
        let newSession = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .none)
        newSession.delegate = self
        self.session = newSession
        
        DispatchQueue.main.async {
            self.connectionState = .searchingOrAdvertising(role: role)
        }
        
        switch role {
        case .dom:
            var info: [String: String] = ["role": "dom"]
            if let saved = savedPeerName {
                info["targetPeer"] = saved
            }
            let adv = MCNearbyServiceAdvertiser(
                peer: myPeerID,
                discoveryInfo: info,
                serviceType: Self.serviceType
            )
            adv.delegate = self
            self.advertiser = adv
            adv.startAdvertisingPeer()
            
        case .sub:
            let brw = MCNearbyServiceBrowser(
                peer: myPeerID,
                serviceType: Self.serviceType
            )
            brw.delegate = self
            self.browser = brw
            brw.startBrowsingForPeers()
        }
    }
    
    func send(message: LeashNetworkMessage, mode: MCSessionSendDataMode = .reliable) throws {
        guard let session = session, let peer = connectedPeer else {
            throw NSError(domain: "MultipeerSessionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No peer connected."])
        }
        let data = try message.encode()
        try session.send(data, toPeers: [peer], with: mode)
    }
    
    func stop() {
        advertiser?.stopAdvertisingPeer()
        advertiser?.delegate = nil
        advertiser = nil
        
        browser?.stopBrowsingForPeers()
        browser?.delegate = nil
        browser = nil
        
        session?.disconnect()
        session?.delegate = nil
        session = nil
        
        connectedPeer = nil
        connectionState = .idle
    }
    
    deinit {
        stop()
    }
}

// MARK: - MCSessionDelegate
extension MultipeerSessionManager: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            switch state {
            case .connecting:
                self.connectionState = .connecting(peerName: peerID.displayName)
            case .connected:
                self.connectedPeer = peerID
                self.connectionState = .connected(peerName: peerID.displayName)
                if let currentRole = self.role {
                    self.savePairing(peerName: peerID.displayName, role: currentRole)
                }
                self.onPeerConnected?(peerID)
            case .notConnected:
                if self.connectedPeer == peerID {
                    self.connectedPeer = nil
                    self.connectionState = .disconnected
                    self.onPeerDisconnected?(peerID)
                    
                    if self.isAutoPairEnabled, let currentRole = self.role {
                        self.start(role: currentRole)
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            do {
                let message = try LeashNetworkMessage.decode(from: data)
                self.onMessageReceived?(message, peerID)
            } catch {
                self.onMessageReceived?(.uwbToken(data), peerID)
            }
        }
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerSessionManager: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        guard let currentSession = self.session else {
            invitationHandler(false, nil)
            return
        }
        
        invitationHandler(true, currentSession)
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .error("Advertising error: \(error.localizedDescription)")
        }
    }
}

extension MultipeerSessionManager: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        guard let currentSession = self.session, self.connectedPeer == nil else { return }
        
        if let saved = savedPeerName {
            if peerID.displayName == saved {
                DispatchQueue.main.async { [weak self] in
                    self?.connectionState = .connecting(peerName: peerID.displayName)
                }
                browser.invitePeer(peerID, to: currentSession, withContext: nil, timeout: 15)
            }
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.connectionState = .connecting(peerName: peerID.displayName)
            }
            browser.invitePeer(peerID, to: currentSession, withContext: nil, timeout: 15)
        }
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
    
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        DispatchQueue.main.async { [weak self] in
            self?.connectionState = .error("Browsing error: \(error.localizedDescription)")
        }
    }
}
