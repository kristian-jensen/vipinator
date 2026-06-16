//
//  GeneralSettingsView.swift
//  Vipinator
//

import SwiftUI
import AppKit
import ServiceManagement
import KeyboardShortcuts

struct GeneralSettingsView: View {
    @State private var isOpenAtLogin: Bool = SMAppService.mainApp.status == .enabled
    @AppStorage(ReconnectAtStartup.defaultsKey) private var reconnectAtStartup = false
    @AppStorage(ReconnectAfterSleep.defaultsKey) private var reconnectAfterSleep = false
    
    var body: some View {
        Form {
            Section(header: Text("Startup")) {
                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Open at Login", isOn: $isOpenAtLogin.onChange(toggleOpenAtLogin))
                    Text("Launch Vipinator in the menu bar when you start your device")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Reconnect at Startup", isOn: $reconnectAtStartup)
                    Text("Reconnect to your most recently connected VPN when Vipinator launches")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Toggle("Reconnect After Sleep", isOn: $reconnectAfterSleep)
                    Text("Reconnect VPNs that were connected before sleep when your Mac wakes")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            
            Section(header: Text("Hotkeys"), footer: Text("Toggle the last VPN you connected to with a global keyboard shortcut")) {
                KeyboardShortcuts.Recorder("Toggle recent VPN", name: .toggleVPN)
            }
        }
        .formStyle(.grouped)
    }
    
    private func toggleOpenAtLogin() {
        do {
            if isOpenAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSSound.beep()
            isOpenAtLogin = SMAppService.mainApp.status == .enabled
            NSLog("OpenAtLogin toggle error: \(error.localizedDescription)")
        }
    }
}
