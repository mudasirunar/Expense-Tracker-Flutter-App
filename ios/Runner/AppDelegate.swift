import Flutter
import UIKit

@available(iOS 15.0, *)
class NativeThemeMenuPlatformView: NSObject, FlutterPlatformView {
  private let _view: UIView
  private let _button: UIButton
  private let _channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    binaryMessenger messenger: FlutterBinaryMessenger
  ) {
    _channel = FlutterMethodChannel(
      name: "com.mudasir.expensetracker/native_theme_menu_\(viewId)",
      binaryMessenger: messenger
    )
    _view = UIView(frame: frame)
    _button = UIButton(type: .system)
    _button.translatesAutoresizingMaskIntoConstraints = false
    _view.addSubview(_button)

    NSLayoutConstraint.activate([
      _button.topAnchor.constraint(equalTo: _view.topAnchor),
      _button.bottomAnchor.constraint(equalTo: _view.bottomAnchor),
      _button.leadingAnchor.constraint(equalTo: _view.leadingAnchor),
      _button.trailingAnchor.constraint(equalTo: _view.trailingAnchor),
    ])

    super.init()

    setupButton(with: args as? [String: Any])

    _channel.setMethodCallHandler { [weak self] (call, result) in
      if call.method == "updateMode" {
        if let params = call.arguments as? [String: Any] {
          self?.setupButton(with: params)
          result(nil)
        } else {
          result(FlutterError(code: "INVALID_ARGS", message: nil, details: nil))
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }
  }

  func view() -> UIView {
    return _view
  }

  private func setupButton(with args: [String: Any]?) {
    let currentMode = args?["currentMode"] as? String ?? "system"
    let isDark = args?["isDark"] as? Bool ?? false

    switch currentMode {
    case "light":
      _view.overrideUserInterfaceStyle = .light
      _button.overrideUserInterfaceStyle = .light
    case "dark":
      _view.overrideUserInterfaceStyle = .dark
      _button.overrideUserInterfaceStyle = .dark
    default:
      _view.overrideUserInterfaceStyle = .unspecified
      _button.overrideUserInterfaceStyle = .unspecified
    }

    var config: UIButton.Configuration
    if #available(iOS 26.0, *) {
      config = UIButton.Configuration.glass()
    } else {
      config = UIButton.Configuration.tinted()
    }
    config.cornerStyle = .capsule
    config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 10, bottom: 4, trailing: 10)

    let systemColor = UIColor.systemBlue
    let orangeColor = UIColor.systemOrange
    let indigoColor = UIColor.systemIndigo

    switch currentMode {
    case "light":
      config.title = "Light"
      config.image = UIImage(systemName: "sun.max.fill")?.withTintColor(orangeColor, renderingMode: .alwaysOriginal)
    case "dark":
      config.title = "Dark"
      config.image = UIImage(systemName: "moon.fill")?.withTintColor(indigoColor, renderingMode: .alwaysOriginal)
    default:
      config.title = "System"
      config.image = UIImage(systemName: "iphone")?.withTintColor(systemColor, renderingMode: .alwaysOriginal)
    }

    config.imagePadding = 5
    config.imagePlacement = .leading
    config.baseForegroundColor = isDark ? .white : .black

    _button.configuration = config
    _button.showsMenuAsPrimaryAction = true

    let isSystem = currentMode == "system"
    let isLight = currentMode == "light"
    let isDarkSelected = currentMode == "dark"

    let systemAction = UIAction(
      title: isSystem ? "System Default  ✓" : "System Default",
      image: UIImage(systemName: isSystem ? "iphone.badge.checkmark" : "iphone")?.withTintColor(systemColor, renderingMode: .alwaysOriginal)
    ) { [weak self] _ in
      self?._channel.invokeMethod("onThemeSelected", arguments: "system")
    }

    let lightAction = UIAction(
      title: isLight ? "Light  ✓" : "Light",
      image: UIImage(systemName: isLight ? "sun.max.fill" : "sun.max")?.withTintColor(orangeColor, renderingMode: .alwaysOriginal)
    ) { [weak self] _ in
      self?._channel.invokeMethod("onThemeSelected", arguments: "light")
    }

    let darkAction = UIAction(
      title: isDarkSelected ? "Dark  ✓" : "Dark",
      image: UIImage(systemName: isDarkSelected ? "moon.fill" : "moon")?.withTintColor(indigoColor, renderingMode: .alwaysOriginal)
    ) { [weak self] _ in
      self?._channel.invokeMethod("onThemeSelected", arguments: "dark")
    }

    let themeMenu = UIMenu(
      title: "",
      children: [systemAction, lightAction, darkAction]
    )

    _button.menu = themeMenu
  }
}

@available(iOS 15.0, *)
class NativeThemeMenuFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return NativeThemeMenuPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      binaryMessenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var isPluginRegistered = false

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    registerNativeThemePluginIfNeeded(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    registerNativeThemePluginIfNeeded(with: engineBridge.pluginRegistry)
  }

  private func registerNativeThemePluginIfNeeded(with registry: FlutterPluginRegistry) {
    guard !isPluginRegistered else { return }
    if #available(iOS 15.0, *) {
      if let registrar = registry.registrar(forPlugin: "NativeThemeMenuPlugin") {
        isPluginRegistered = true
        let factory = NativeThemeMenuFactory(messenger: registrar.messenger())
        registrar.register(factory, withId: "com.mudasir.expensetracker/native_theme_menu")
      }
    }
  }
}
