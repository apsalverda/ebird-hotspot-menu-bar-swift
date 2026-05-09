import Foundation
import Combine

struct SavedLocation: Identifiable, Codable, Equatable {
    let id: String // this is the eBird location ID e.g. "L4686222"
    let name: String
}

class LocationStore: ObservableObject {
    static let shared = LocationStore()

    @Published var locations: [SavedLocation] = []
    @Published var defaultLocationID: String?
    @Published var currentLocationID: String?

    private let locationsKey = "savedLocations"
    private let defaultLocationKey = "defaultLocationID"
    private let lastUsedLocationKey = "lastUsedLocationID"

    init() {
        load()
    }

    // MARK: - Load
    func load() {
        if let data = UserDefaults.standard.data(forKey: locationsKey),
           let decoded = try? JSONDecoder().decode([SavedLocation].self, from: data) {
            locations = decoded
        }
        defaultLocationID = UserDefaults.standard.string(forKey: defaultLocationKey)
        let lastUsed = UserDefaults.standard.string(forKey: lastUsedLocationKey)
        currentLocationID = defaultLocationID ?? lastUsed ?? locations.first?.id
    }

    // MARK: - Save
    func save() {
        if let encoded = try? JSONEncoder().encode(locations) {
            UserDefaults.standard.set(encoded, forKey: locationsKey)
        }
        UserDefaults.standard.set(defaultLocationID, forKey: defaultLocationKey)
    }

    func saveLastUsed() {
        UserDefaults.standard.set(currentLocationID, forKey: lastUsedLocationKey)
    }

    // MARK: - Add
    func add(_ location: SavedLocation) -> Bool {
        guard locations.count < 10 else { return false }
        guard !locations.contains(where: { $0.id == location.id }) else { return false }
        locations.append(location)
        save()
        return true
    }

    // MARK: - Remove
    func remove(_ location: SavedLocation) {
        locations.removeAll { $0.id == location.id }
        if defaultLocationID == location.id {
            defaultLocationID = nil
        }
        if currentLocationID == location.id {
            currentLocationID = defaultLocationID ?? locations.first?.id
        }
        save()
    }

    // MARK: - Set default
    func setDefault(_ location: SavedLocation?) {
        defaultLocationID = location?.id
        save()
    }

    // MARK: - Current location
    var currentLocation: SavedLocation? {
        locations.first { $0.id == currentLocationID }
    }
}
