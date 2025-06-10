import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

// MARK: - Minimal Test InsightsView
struct InsightsView_Test: View {
    @EnvironmentObject var meals: Meals
    @EnvironmentObject var userProfiles: UserProfiles
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Insights Test")
                Text("Meals count: \(meals.meals.count)")
            }
            .navigationTitle("Insights")
        }
    }
}

#Preview {
    InsightsView_Test()
        .environmentObject(Meals())
        .environmentObject(UserProfiles())
}
