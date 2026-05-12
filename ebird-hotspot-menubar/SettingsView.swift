import SwiftUI

struct SettingsView: View {
    @ObservedObject private var locationStore = LocationStore.shared
    @State private var apiKey: String = ""
    @State private var newLocationID: String = ""
    @State private var isFetchingName = false
    @State private var fetchError: String?
    @State private var saved = false
    @AppStorage("showCounts") private var showCounts: Bool = true

    var body: some View {
        Form {
            // API Key
            Section {
                LabeledContent("API Key") {
                    SecureField("", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                        .frame(minWidth: 125, maxWidth: 125)
                        .multilineTextAlignment(.leading)
                }
            } footer: {
                Text("Find your personal eBird API key at https://ebird.org/api/keygen")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Locations
            Section("Locations (max 10)") {
                if locationStore.locations.isEmpty {
                    Text("No locations added yet.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                ForEach(locationStore.locations) { location in
                    HStack {
                        Button {
                            if locationStore.defaultLocationID == location.id {
                                locationStore.setDefault(nil)
                            } else {
                                locationStore.setDefault(location)
                            }
                        } label: {
                            Image(systemName: locationStore.defaultLocationID == location.id ? "star.fill" : "star")
                                .foregroundColor(locationStore.defaultLocationID == location.id ? .yellow : .secondary)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading) {
                            Text(location.name)
                                .font(.body)
                            HStack(spacing: 4) {
                                Text(location.id)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                if let url = URL(string: "https://ebird.org/hotspot/\(location.id)") {
                                    Link(destination: url) {
                                        Image(systemName: "link")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        
                        Spacer()

                        Button {
                            locationStore.remove(location)
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.vertical, 2)
                }

                if locationStore.defaultLocationID == nil {
                    Text("App will remember last used location. Tap ★ to set a default")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("★ Marks the default location shown on startup")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if locationStore.locations.count < 10 {
                    HStack {
                        TextField("ID or URL", text: $newLocationID)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: 250)
                        
                        if isFetchingName {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Button("Add") {
                                addLocation()
                            }
                            .disabled(newLocationID.isEmpty)
                        }
                    }

                    if let error = fetchError {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                
                Text("Find your hotspot's location ID by going to the hotspot's website. It's the last part of the URL, for instance 'L4686222' in https://ebird.org/hotspot/L4686222. You can also paste the entire URL")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Show counts
            Section {
                LabeledContent("Show counts") {
                    Toggle("", isOn: $showCounts)
                        .labelsHidden()
                }
            }

            // Save button
            HStack {
                Spacer()
                if saved {
                    Label("Saved", systemImage: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .transition(.opacity)
                }
                Button("Save") {
                    KeychainHelper.apiKey = apiKey.isEmpty ? nil : apiKey
                    if locationStore.currentLocationID == nil {
                        locationStore.currentLocationID = locationStore.locations.first?.id
                    }
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
        }
    }

    private func addLocation() {
        var id = newLocationID.trimmingCharacters(in: .whitespaces)
        
        // Extract location ID from full URL if needed
        if id.contains("ebird.org/hotspot/") {
            if let range = id.range(of: "ebird.org/hotspot/") {
                id = String(id[range.upperBound...])
                    .components(separatedBy: CharacterSet(charactersIn: "/?&#"))
                    .first ?? ""
            }
        }
        
        guard !id.isEmpty else { return }
        isFetchingName = true
        fetchError = nil

        let service = EBirdService()
        service.fetchLocationName(locationID: id) { name in
            isFetchingName = false
            guard let name = name else {
                fetchError = "Invalid ID or no data."
                return
            }
            let location = SavedLocation(id: id, name: name)
            if !locationStore.add(location) {
                fetchError = "Location already added or limit reached."
            } else {
                newLocationID = ""
                if locationStore.locations.count == 1 {
                    locationStore.currentLocationID = id
                }
            }
        }
    }
}
