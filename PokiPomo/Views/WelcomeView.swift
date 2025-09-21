import SwiftUI

struct WelcomeView: View {
    var onStart: () -> Void
    @State private var showDistractionDrop = false

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 200, height: 200)
                    .overlay {
                        Text("Poki Mascot")
                            .font(.headline)
                            .foregroundStyle(.blue)
                    }

                Text("Welcome to PokiPomo")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Partner with Poki to build mindful focus habits and celebrate your progress along the way.")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
            }

            NavigationLink(isActive: $showDistractionDrop) {
                DistractionDropView {
                    showDistractionDrop = false
                    onStart()
                }
            } label: {
                EmptyView()
            }
            .hidden()

            Button(action: { showDistractionDrop = true }) {
                Text("Start Your Journey")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)

            Spacer(minLength: 24)
        }
        .padding()
        .navigationTitle("Welcome")
    }
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            WelcomeView {}
        }
    }
}
