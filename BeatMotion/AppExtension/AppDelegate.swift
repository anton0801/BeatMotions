import UIKit
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {
    
    private let eventStage = EventStage()
    
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        eventStage.attach(TempoObserver())
        eventStage.attach(CueObserver())
        eventStage.attach(PushObserver())
        eventStage.attach(TokenObserver())
        
        FirebaseApp.configure()
        
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        UIApplication.shared.registerForRemoteNotifications()
        
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = StudioConstants.trackerKey
        sdk.appleAppID = StudioConstants.appCode
        sdk.delegate = self
        sdk.deepLinkDelegate = self
        sdk.isDebug = false
        
        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            eventStage.fire(.pushReceived(remote))
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
        
        return true
    }
    
    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }
    
    @objc private func onActivation() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { [weak self] token, err in
            guard err == nil, let t = token else { return }
            self?.eventStage.fire(.tokenReceived(t))
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        eventStage.fire(.pushReceived(notification.request.content.userInfo))
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        eventStage.fire(.pushReceived(response.notification.request.content.userInfo))
        completionHandler()
    }
    
    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        eventStage.fire(.pushReceived(userInfo))
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        eventStage.fire(.attributionResolved(data))
    }
    
    func onConversionDataFail(_ error: Error) {
        eventStage.fire(.attributionResolved([
            "error": true,
            "error_desc": error.localizedDescription
        ]))
    }
    
    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        eventStage.fire(.deepLinkResolved(link.clickEvent))
    }
}

enum StageEvent {
    case attributionResolved([AnyHashable: Any])
    case deepLinkResolved([AnyHashable: Any])
    case pushReceived([AnyHashable: Any])
    case tokenReceived(String)
}

protocol StageObserver: AnyObject {
    func handle(_ event: StageEvent)
}

final class EventStage {
    
    private var observers: [StageObserver] = []
    
    func attach(_ observer: StageObserver) {
        observers.append(observer)
    }
    
    func fire(_ event: StageEvent) {
        for observer in observers {
            observer.handle(event)
        }
    }
}

final class TempoObserver: StageObserver {
    
    private var tempoBuffer: [AnyHashable: Any] = [:]
    private var cueBuffer: [AnyHashable: Any] = [:]
    private var fuseTimer: Timer?
    
    static let shared = TempoObserver()
    
    func handle(_ event: StageEvent) {
        switch event {
        case .attributionResolved(let data):
            tempoBuffer = data
            scheduleFuse()
            if !cueBuffer.isEmpty { performFuse() }
            
        case .deepLinkResolved(let data):
            guard !UserDefaults.standard.bool(forKey: StudioKey.primed) else { return }
            cueBuffer = data
            NotificationCenter.default.post(
                name: .init("deeplink_values"),
                object: nil,
                userInfo: ["deeplinksData": data]
            )
            fuseTimer?.invalidate()
            if !tempoBuffer.isEmpty { performFuse() }
            
        default:
            break
        }
    }
    
    private func scheduleFuse() {
        fuseTimer?.invalidate()
        fuseTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { [weak self] _ in
            self?.performFuse()
        }
    }
    
    private func performFuse() {
        var combined = tempoBuffer
        for (k, v) in cueBuffer {
            let prefixed = "deep_\(k)"
            if combined[prefixed] == nil {
                combined[prefixed] = v
            }
        }
        NotificationCenter.default.post(
            name: .init("ConversionDataReceived"),
            object: nil,
            userInfo: ["conversionData": combined]
        )
    }
}

final class CueObserver: StageObserver {
    func handle(_ event: StageEvent) {
        if case .deepLinkResolved = event {
            print("\(StudioConstants.logBeat) CueObserver: deeplink received")
        }
    }
}

final class PushObserver: StageObserver {
    
    func handle(_ event: StageEvent) {
        guard case .pushReceived(let payload) = event else { return }
        guard let url = extract(payload) else { return }
        
        UserDefaults.standard.set(url, forKey: StudioKey.pushURL)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            NotificationCenter.default.post(
                name: .init("LoadTempURL"),
                object: nil,
                userInfo: ["temp_url": url]
            )
        }
    }
    
    private func extract(_ payload: [AnyHashable: Any]) -> String? {
        if let direct = payload["url"] as? String { return direct }
        if let nested = payload["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let aps = payload["aps"] as? [String: Any],
           let nested = aps["data"] as? [String: Any],
           let url = nested["url"] as? String { return url }
        if let custom = payload["custom"] as? [String: Any],
           let url = custom["target_url"] as? String { return url }
        return nil
    }
}

final class TokenObserver: StageObserver {
    
    func handle(_ event: StageEvent) {
        guard case .tokenReceived(let token) = event else { return }
        UserDefaults.standard.set(token, forKey: StudioKey.fcm)
        UserDefaults.standard.set(token, forKey: StudioKey.push)
        UserDefaults(suiteName: StudioConstants.suiteStudio)?.set(token, forKey: "shared_fcm")
    }
}
