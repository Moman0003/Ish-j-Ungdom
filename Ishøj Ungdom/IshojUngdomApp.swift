//
//  IshojUngdomApp.swift
//  IshojUngdom
//
//  App entry point - initialiserer Firebase og styrer auth state
//

import SwiftUI
import FirebaseCore

// AppDelegate til at initialisere Firebase ved app-start
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@main
struct IshojUngdomApp: App {
    // Tilknyt AppDelegate til SwiftUI lifecycle
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // Auth ViewModel deles på tværs af hele app'en
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some Scene {
        WindowGroup {
            // Root view tjekker om brugeren er logget ind
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
