//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CoreStore
import Defaults
import Logging
import Pulse
import PulseLogHandler
import SwiftUI

@main
struct SwiftfinApp: App {

    @Environment(\.scenePhase) var scenePhase

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate

    init() {

        // Defaults
        Task {
            for await newValue in Defaults.updates(.accentColor) {
                UIApplication.shared.setAccentColor(newValue.uiColor)
                UIApplication.shared.setNavigationBackButtonAccentColor(newValue.uiColor)
            }
        }

        Task {
            for await newValue in Defaults.updates(.appAppearance) {
                UIApplication.shared.setAppearance(newValue.style)
            }
        }

        // Logging
        LoggingSystem.bootstrap { label in

            var loggers: [LogHandler] = [PersistentLogHandler(label: label).withLogLevel(.trace)]

            #if DEBUG
            loggers.append(SwiftfinConsoleLogger())
            #endif

            return MultiplexLogHandler(loggers)
        }

        CoreStoreDefaults.dataStack = SwiftfinStore.dataStack
        CoreStoreDefaults.logger = SwiftfinCorestoreLogger()

        // Sometimes the tab bar won't appear properly on push, always have material background
        UITabBar.appearance().scrollEdgeAppearance = UITabBarAppearance(idiom: .unspecified)
    }

    var body: some Scene {
        WindowGroup {
            PreferenceUIHostingControllerView {
                MainCoordinator()
                    .view()
                    .supportedOrientations(.portrait)
            }
            .ignoresSafeArea()
            .onOpenURL { url in
                AppURLHandler.shared.processDeepLink(url: url)
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    Notifications[.didEnterActivePhase].post()
                } else if newPhase == .inactive {
                    Notifications[.didEnterInactivePhase].post()
                } else if newPhase == .background {
                    Notifications[.didEnterBackgroundPhase].post()
                }
            }
        }
    }
}

extension UINavigationController {

    // Remove back button text
    override open func viewWillLayoutSubviews() {
        navigationBar.topItem?.backButtonDisplayMode = .minimal
    }
}
