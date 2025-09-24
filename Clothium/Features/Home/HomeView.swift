import SwiftUI

struct HomeView: View {
    var user: AuthUser

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Добро пожаловать, \(user.email)")
                    .font(.title2.bold())
                Text("Это домашний экран Clothium")
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("Clothium")
        }
    }
}

#Preview {
    HomeView(user: .init(id: "1", email: "demo@clothium.app"))
}


