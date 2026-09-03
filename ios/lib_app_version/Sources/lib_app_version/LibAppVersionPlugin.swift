import Flutter
import UIKit

/// Native side of `lib_app_version`.
///
/// Methods:
///  - `getAppInfo`   -> [version, buildNumber, packageName, installSource]
///  - `openUrl(url)` -> true when iOS could open the URL
public class LibAppVersionPlugin: NSObject, FlutterPlugin {
  private static let channelName = "lib_app_version"

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let instance = LibAppVersionPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getAppInfo":
      result(Self.appInfo())
    case "openUrl":
      guard let args = call.arguments as? [String: Any],
            let urlString = args["url"] as? String,
            let url = URL(string: urlString) else {
        result(FlutterError(code: "INVALID_ARGUMENT", message: "Missing or invalid 'url' argument", details: nil))
        return
      }
      Self.open(url) { opened in result(opened) }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func appInfo() -> [String: Any] {
    let info = Bundle.main.infoDictionary ?? [:]
    return [
      "version": info["CFBundleShortVersionString"] as? String ?? "",
      "buildNumber": info["CFBundleVersion"] as? String ?? "",
      "packageName": Bundle.main.bundleIdentifier ?? "",
      "installSource": installSource(),
    ]
  }

  /// Distribution channel heuristic used by most iOS apps:
  ///  - Simulator: compile-time check.
  ///  - Xcode / Ad Hoc / Enterprise builds ship an `embedded.mobileprovision`;
  ///    App Store and TestFlight builds are re-signed by Apple and do not.
  ///  - TestFlight builds carry a *sandbox* receipt, App Store builds a production one.
  static func installSource() -> String {
    #if targetEnvironment(simulator)
    return "simulator"
    #else
    if Bundle.main.path(forResource: "embedded", ofType: "mobileprovision") != nil {
      return "development"
    }
    guard let receiptURL = Bundle.main.appStoreReceiptURL else {
      return "unknown"
    }
    return receiptURL.lastPathComponent == "sandboxReceipt" ? "testflight" : "appstore"
    #endif
  }

  private static func open(_ url: URL, completion: @escaping (Bool) -> Void) {
    DispatchQueue.main.async {
      UIApplication.shared.open(url, options: [:]) { success in
        completion(success)
      }
    }
  }
}
