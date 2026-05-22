import Foundation
import Combine
import AppsFlyerLib
import FirebaseCore
import FirebaseMessaging
import WebKit
import UIKit
import UserNotifications

// MARK: - HTTP Console Finder

final class HTTPConsoleFinder: ConsoleFinder {
    
    private let session: URLSession
    private let waitMarks: [Double] = [82.0, 164.0, 328.0]
    
    init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 90
        config.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        config.urlCache = nil
        self.session = URLSession(configuration: config)
    }
    
    func find(seed: [String: Any]) async throws -> String {
        guard let endpoint = URL(string: StudioConstants.backendSoundboard) else {
            throw MotionFault.packetGarbled(stage: "endpoint URL")
        }
        
        var body: [String: Any] = seed
        body["os"] = "iOS"
        body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        body["firebase_project_id"] = FirebaseApp.app()?.options.gcmSenderID
        body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        body["store_id"] = "id\(StudioConstants.appCode)"
        body["locale"] = Locale.preferredLanguages.first?.prefix(2).uppercased() ?? "EN"
        body["push_token"] = UserDefaults.standard.string(forKey: StudioKey.push)
            ?? Messaging.messaging().fcmToken
        
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(browserAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        var lastFault: Error?
        var attempts = 0
        
        for (idx, wait) in waitMarks.enumerated() {
            attempts += 1
            do {
                return try await singleShot(request)
            } catch let fault as MotionFault {
                if case .consoleRejected = fault {
                    throw fault
                }
                if case .feedbackLoop(let retryAfter) = fault {
                    try await Task.sleep(nanoseconds: UInt64(retryAfter * 1_000_000_000))
                    continue
                }
                lastFault = fault
                if idx < waitMarks.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            } catch {
                lastFault = error
                if idx < waitMarks.count - 1 {
                    try await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
                }
            }
        }
        
        if let lastFault = lastFault {
            throw lastFault
        }
        throw MotionFault.wireUnplugged(attempts: attempts)
    }
    
    private var browserAgent: String = WKWebView().value(forKey: "userAgent") as? String ?? ""
    
    private func singleShot(_ request: URLRequest) async throws -> String {
        let (data, response) = try await session.data(for: request)
        
        guard let http = response as? HTTPURLResponse else {
            throw MotionFault.wireUnplugged(attempts: 0)
        }
        
        if http.statusCode == 404 {
            throw MotionFault.consoleRejected(httpCode: 404)
        }
        
        guard (200...299).contains(http.statusCode) else {
            throw MotionFault.wireUnplugged(attempts: 0)
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MotionFault.packetGarbled(stage: "JSON parse")
        }
        
        guard let ok = json["ok"] as? Bool else {
            throw MotionFault.packetGarbled(stage: "missing 'ok'")
        }
        
        if !ok {
            throw MotionFault.consoleRejected(httpCode: 200)
        }
        
        guard let url = json["url"] as? String else {
            throw MotionFault.packetGarbled(stage: "missing 'url'")
        }
        
        return url
    }
}

final class FactoryBag {
    
    private var closures: [String: () -> Any] = [:]
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: T.self)
        closures[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: T.self)
        guard let factory = closures[key], let instance = factory() as? T else {
            fatalError("FactoryBag: no factory for \(key)")
        }
        return instance
    }
    
    static func production() -> FactoryBag {
        let bag = FactoryBag()
        
        let vault: StudioVault = PlistBlobVault()
        let probe: VoltageProbe = SupabaseVoltageProbe()
        let fetcher: AttributionFetcher = AppsFlyerAttributionFetcher()
        let finder: ConsoleFinder = HTTPConsoleFinder()
        let singer: ConsentSinger = NotificationConsentSinger()
        
        bag.register((StudioVault).self) { vault }
        bag.register((VoltageProbe).self) { probe }
        bag.register((AttributionFetcher).self) { fetcher }
        bag.register((ConsoleFinder).self) { finder }
        bag.register((ConsentSinger).self) { singer }
        
        return bag
    }
}
