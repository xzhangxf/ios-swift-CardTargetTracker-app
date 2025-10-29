//
//  ThemeManager.swift
//  ios-swift-CardTargetTracker-app
//
//  Created by Xufeng Zhang on 29/10/25.
//

import UIKit

enum AppTheme: Int, CaseIterable {
    case system = 0
    case light
    case dark

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    var interfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light:  return .light
        case .dark:   return .dark
        }
    }
}

final class ThemeManager {
    static let shared = ThemeManager()
    private init() {}

    private let key = "app.theme.selection"

    var current: AppTheme {
        get { AppTheme(rawValue: UserDefaults.standard.integer(forKey: key)) ?? .system }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: key) }
    }

    func apply(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = current.interfaceStyle
    }
}
