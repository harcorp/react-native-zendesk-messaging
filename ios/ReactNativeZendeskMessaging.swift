import ZendeskSDKMessaging
import ZendeskSDK
import React

@objc(ZendeskMessaging)
open class ZendeskMessaging: RCTEventEmitter {
    
    public static var emitter: RCTEventEmitter!
    var isInitialized = false

      override init() {
        super.init()
          ZendeskMessaging.emitter = self
      }
    
    open override func supportedEvents() -> [String] {
        ["unreadMessageCountChanged", "authenticationFailed"]      // etc.
      }
    
  @objc
    public override static func requiresMainQueueSetup() -> Bool {
    return true
  }

  @objc
  func initialize(_ channelKey:String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    Zendesk.initialize(withChannelKey: channelKey,
                      messagingFactory: DefaultMessagingFactory()) { result in
      if case let .failure(error) = result {
        reject("error","\(error)",nil)
        print("Messaging did not initialize.\nError: \(error.localizedDescription)")
      } else {
          if (!self.isInitialized) {
              Zendesk.instance?.addEventObserver(self) { event in
                  switch event {
                  case .unreadMessageCountChanged(let unreadCount):
                      ZendeskMessaging.emitter.sendEvent(withName: "unreadMessageCountChanged", body: unreadCount)
                    break
                  case .authenticationFailed(let error as NSError):
                      print("Authentication error received: \(error)")
                      print("Domain: \(error.domain)")
                      print("Error code: \(error.code)")
                      print("Localized Description: \(error.localizedDescription)")
                      break
                  @unknown default:
                      break
                  }
              }
              self.isInitialized = true
          }
        resolve("success")
      }
    }
  }

  @objc
  func showMessaging() {
    DispatchQueue.main.async {
      guard let zendeskController = Zendesk.instance?.messaging?.messagingViewController() else {
        return }
      let viewController = RCTPresentedViewController();
      viewController?.present(zendeskController, animated: true) {
        print("Messaging have shown")
      }
    }
  }

  @objc
  func loginUser(_ token:String, resolver resolve: @escaping RCTPromiseResolveBlock, rejecter reject: @escaping RCTPromiseRejectBlock) {
    Zendesk.instance?.loginUser(with: token) { result in
      switch result {
      case .success(let user):
          print(user)
          let serializableUser = RNZendeskUser(user)
          resolve(serializableUser.asDictionary())
      case .failure(let error):
          reject("error","\(error)",nil)
      }
    }
  }

  @objc
  func logoutUser(_ resolve: @escaping RCTPromiseResolveBlock,
                        rejecter reject: @escaping RCTPromiseRejectBlock) {
    Zendesk.instance?.logoutUser { result in
      switch result {
      case .success:
          resolve("success")
      case .failure(let error):
          reject("error","\(error)",nil)
      }
    }
  }

  @objc
  func updatePushNotificationToken(_ deviceToken:String,
    resolver resolve: @escaping RCTPromiseResolveBlock,
    rejecter reject: @escaping RCTPromiseRejectBlock
  ){
    do{
      try PushNotifications.updatePushNotificationToken(Data(deviceToken.utf8))
      resolve("success");
    } catch {
      reject("error","\(error)",nil)
    }
  }
}
