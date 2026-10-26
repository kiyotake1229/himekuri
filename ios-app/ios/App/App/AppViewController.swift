import UIKit
import Capacitor

/// Main.storyboard から使う ViewController。
/// アプリ内で定義したプラグイン（WidgetBridge）を Capacitor に登録する。
class AppViewController: CAPBridgeViewController {
    override open func capacitorDidLoad() {
        bridge?.registerPluginInstance(WidgetBridgePlugin())
    }
}
