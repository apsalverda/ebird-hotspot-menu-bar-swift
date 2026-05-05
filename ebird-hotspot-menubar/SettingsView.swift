import SwiftUI

struct SettingsView: View {
    @State private var apiKey: String = ""
    @State private var locationID: String = ""
    @State private var saved = false
    @AppStorage("showCounts") private var showCounts: Bool = true

    var body: some View {
        Form {
            Section {
                LabeledContent("API Key") {
                    SecureField("", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 125, maxWidth: 125)
                        .multilineTextAlignment(.leading)
                }
                LabeledContent("Location ID") {
                    TextField("", text: $locationID)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 125, maxWidth: 125)
                        .multilineTextAlignment(.leading)
                }
                LabeledContent("Show counts") {
                    Toggle("", isOn: $showCounts)
                        .labelsHidden()
                }
            } footer: {
                Text("Find your hotspot's location ID by going to the hotspot's website. It's the last part of the URL, for instance 'L4686222' in https://ebird.org/hotspot/L4686222 or 'L524399'")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section {
                // Placeholder for GPS-based location (future)
                LabeledContent("Auto-location") {
                    Text("Coming soon")
                        .foregroundColor(.secondary)
                }
            }

            HStack {
                Spacer()
                if saved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                Button("Save") {
                    KeychainHelper.apiKey = apiKey.isEmpty ? nil : apiKey
                    KeychainHelper.locationID = locationID.isEmpty ? nil : locationID
                    UserDefaults.standard.set(showCounts, forKey: "showCounts")
                    NotificationCenter.default.post(name: .settingsSaved, object: nil)
                    withAnimation { saved = true }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { saved = false }
                    }
                }                .buttonStyle(.borderedProminent)
            }
        }
        .formStyle(.grouped)
        .padding()
        .frame(width: 420)
        .onAppear {
            apiKey = KeychainHelper.apiKey ?? ""
            locationID = KeychainHelper.locationID ?? ""
        }
    }
}
