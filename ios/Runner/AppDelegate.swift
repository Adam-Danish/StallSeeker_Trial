import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UIDocumentPickerDelegate {
  private var receiptSave: (directory: URL, result: FlutterResult)?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "stallseeker/receipt_download",
      binaryMessenger: engineBridge.applicationRegistrar.messenger())
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(FlutterError(code: "save_failed", message: "Receipt saver is unavailable.", details: nil))
        return
      }
      self.saveReceipt(call, result: result)
    }
  }

  private func saveReceipt(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "savePdf" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard receiptSave == nil,
          let args = call.arguments as? [String: Any],
          let bytes = args["bytes"] as? FlutterStandardTypedData,
          let filename = args["filename"] as? String,
          filename == (filename as NSString).lastPathComponent,
          filename.hasSuffix(".pdf"),
          let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }),
          var presenter = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "save_failed", message: "Could not open the file picker.", details: nil))
      return
    }
    while let presented = presenter.presentedViewController {
      presenter = presented
    }
    let directory = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString, isDirectory: true)
    let file = directory.appendingPathComponent(filename)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      try bytes.data.write(to: file, options: .atomic)
    } catch {
      try? FileManager.default.removeItem(at: directory)
      result(FlutterError(code: "save_failed", message: error.localizedDescription, details: nil))
      return
    }

    receiptSave = (directory, result)
    let picker: UIDocumentPickerViewController
    if #available(iOS 14.0, *) {
      picker = UIDocumentPickerViewController(forExporting: [file], asCopy: true)
    } else {
      picker = UIDocumentPickerViewController(url: file, in: .exportToService)
    }
    picker.delegate = self
    presenter.present(picker, animated: true)
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    finishReceiptSave(saved: !urls.isEmpty)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishReceiptSave(saved: false)
  }

  private func finishReceiptSave(saved: Bool) {
    guard let pending = receiptSave else { return }
    receiptSave = nil
    try? FileManager.default.removeItem(at: pending.directory)
    pending.result(saved)
  }
}
