import SwiftUI
import UIKit

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("OnlyPaste")
                        .font(.title2.weight(.bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                }

                Section {
                    stepRow("1", "打开 设置 → 通用 → 键盘 → 键盘")
                    stepRow("2", "点「添加新键盘」→ 选择 OnlyPaste")
                    stepRow("3", "点进 OnlyPaste 键盘 → 打开「允许完全访问」")
                } header: {
                    Text("启用键盘")
                } footer: {
                    Text("没有「允许完全访问」，键盘读不到系统剪贴板，也就无法存入内容。")
                }

                Section {
                    Button {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    } label: {
                        Label("打开系统设置", systemImage: "gearshape")
                    }
                }
            }
        }
    }

    private func stepRow(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.caption.weight(.bold))
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.15), in: Circle())
            Text(text).font(.subheadline)
        }
    }
}
