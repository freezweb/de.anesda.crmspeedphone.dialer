import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    guard let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "SpeedPhoneDialer") else {
      return
    }
    let channel = FlutterMethodChannel(
      name: "de.anesda.crmspeedphone.dialer/call",
      binaryMessenger: registrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "startCall",
            let arguments = call.arguments as? [String: Any],
            let phone = arguments["phone"] as? String,
            phone.range(of: "^\\+?[0-9]{5,20}$", options: .regularExpression) != nil,
            let url = URL(string: "tel:\(phone)") else {
        result(FlutterError(code: "INVALID_PHONE", message: "Die Telefonnummer ist ungültig.", details: nil))
        return
      }
      DispatchQueue.main.async {
        UIApplication.shared.open(url, options: [:]) { success in
          success ? result(nil) : result(FlutterError(code: "CALL_FAILED", message: "Die Telefon-App konnte nicht geöffnet werden.", details: nil))
        }
      }
    }
  }
}
