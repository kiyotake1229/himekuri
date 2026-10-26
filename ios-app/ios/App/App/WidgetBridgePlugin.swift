import Foundation
import Capacitor
import WidgetKit

/// Web 側（index.html の syncWidget / putImage）から呼ばれる橋渡し。
/// App Group の共有フォルダに JSON と写真を書き、ウィジェットを更新させる。
/// JS からは Capacitor.registerPlugin("WidgetBridge") で呼ぶ。
@objc(WidgetBridgePlugin)
public class WidgetBridgePlugin: CAPPlugin, CAPBridgedPlugin {
    public let identifier = "WidgetBridgePlugin"
    public let jsName = "WidgetBridge"
    public let pluginMethods: [CAPPluginMethod] = [
        CAPPluginMethod(name: "setData", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "saveImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "removeImage", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "clear", returnType: CAPPluginReturnPromise),
        CAPPluginMethod(name: "reload", returnType: CAPPluginReturnPromise)
    ]

    static let groupId = "group.work.ltv.himekuri"
    static let dataFile = "himekuri.json"

    private var container: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.groupId)
    }

    private func safeId(_ raw: String) -> String {
        let ok = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-")
        return String(raw.filter { ok.contains($0) })
    }

    @objc func setData(_ call: CAPPluginCall) {
        guard let json = call.getString("json") else { call.reject("json がありません"); return }
        guard let dir = container else { call.reject("App Group が使えません"); return }
        do {
            try json.data(using: .utf8)?.write(to: dir.appendingPathComponent(Self.dataFile), options: .atomic)
        } catch {
            call.reject("書き込みに失敗: \(error.localizedDescription)"); return
        }
        reloadWidgets()
        call.resolve()
    }

    @objc func saveImage(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let b64 = call.getString("base64") else { call.reject("id / base64 がありません"); return }
        guard let dir = container else { call.reject("App Group が使えません"); return }
        guard let data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters) else { call.reject("画像を復号できません"); return }
        do {
            try data.write(to: dir.appendingPathComponent("img_\(safeId(id)).jpg"), options: .atomic)
        } catch {
            call.reject("写真の保存に失敗: \(error.localizedDescription)"); return
        }
        call.resolve()
    }

    @objc func removeImage(_ call: CAPPluginCall) {
        guard let id = call.getString("id"), let dir = container else { call.resolve(); return }
        try? FileManager.default.removeItem(at: dir.appendingPathComponent("img_\(safeId(id)).jpg"))
        call.resolve()
    }

    @objc func clear(_ call: CAPPluginCall) {
        if let dir = container, let items = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) {
            for url in items where url.lastPathComponent == Self.dataFile || url.lastPathComponent.hasPrefix("img_") {
                try? FileManager.default.removeItem(at: url)
            }
        }
        reloadWidgets()
        call.resolve()
    }

    @objc func reload(_ call: CAPPluginCall) {
        reloadWidgets()
        call.resolve()
    }

    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
