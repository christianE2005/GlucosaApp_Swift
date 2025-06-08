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

// Remove this ContentView - it's already defined in ContentView.swift
// struct ContentView: View {
//     var body: some View {
//         VStack {
//             Text("Hello, ControlGlucosa!")
//                 .font(.largeTitle)
//                 .padding()
//             
//             Text("Glucose Control App")
//                 .font(.subheadline)
//                 .foregroundColor(.secondary)
//         }
//     }
// }