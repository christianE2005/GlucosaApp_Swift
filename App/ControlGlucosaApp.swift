//
//  ControlGlucosaApp.swift
//  ControlGlucosa
//
//  Created by Alumno on 07/06/25.
//

import SwiftUI
import Combine
import Foundation

@main
struct ControlGlucosaApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(UserProfiles()) // Provide the UserProfiles environment object
                .environmentObject(Meals()) // Provide the Meals environment object
        }
    }
}
