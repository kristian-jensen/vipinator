//
//  AppDelegate.swift
//  Vipinator
//
//  Created by Вячеслав Пуханов on 07.07.2024.
//

import Cocoa

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemManager: VPNStatusItemManager!
    private var menuManager: VPNMenuManager!
    private var networkObserver: NetworkConfigurationObserver!
    private var connectedVPNsBeforeSleep: [VPNConnection] = []

    func applicationDidFinishLaunching(_: Notification) {
        Task { @MainActor in
            statusItemManager = VPNStatusItemManager()
            menuManager = VPNMenuManager(statusItemManager: statusItemManager)
            networkObserver = NetworkConfigurationObserver(handler: handleNetworkConfigurationChange)
            observeSleepWakeNotifications()

            await menuManager.loadVPNConnections()
            menuManager.rebuildMenu()
            await VPNManager.connectLastUsedVPNOnLaunchIfNeeded()
            await menuManager.updateVPNStatuses()
        }
    }

    func applicationWillTerminate(_: Notification) {
        networkObserver.stopObserving()
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func handleNetworkConfigurationChange() {
        Task { @MainActor in
            await menuManager.updateVPNStatuses()
        }
    }

    private func observeSleepWakeNotifications() {
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWillSleep),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleDidWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    @objc private func handleWillSleep() {
        Task { @MainActor in
            do {
                connectedVPNsBeforeSleep = try await VPNManager.getConnectedVPNs()
            } catch {
                connectedVPNsBeforeSleep = []
                print("Error checking connected VPNs before sleep: \(error)")
            }
        }
    }

    @objc private func handleDidWake() {
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(5))
            await VPNManager.reconnectAfterWakeIfNeeded(connections: connectedVPNsBeforeSleep)
            connectedVPNsBeforeSleep = []
            await menuManager.updateVPNStatuses()
        }
    }
}
