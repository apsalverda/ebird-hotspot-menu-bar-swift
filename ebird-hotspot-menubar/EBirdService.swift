import Foundation
import Combine

struct BirdObservation: Identifiable, Decodable {
    let id = UUID()
    let speciesCode: String
    let comName: String
    let sciName: String
    let locName: String
    let obsDt: String
    let howMany: Int?

    enum CodingKeys: String, CodingKey {
        case speciesCode, comName, sciName, locName, obsDt, howMany
    }
}

struct CachedObservations {
    let observations: [BirdObservation]
    let timestamp: Date
}

class EBirdService: ObservableObject {
    @Published var observations: [BirdObservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var lastFetched: Date?

    private var cache: [String: CachedObservations] = [:]
    private var cacheExpiry: TimeInterval {
        let minutes = UserDefaults.standard.integer(forKey: "cacheExpiryMinutes")
        return TimeInterval((minutes > 0 ? minutes : 30) * 60)
    }

    func fetchRecentObservations(forceRefresh: Bool = false) {
        guard let apiKey = KeychainHelper.apiKey, !apiKey.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "No API key set. Please open Settings." }
            return
        }
        guard let locationID = LocationStore.shared.currentLocationID, !locationID.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "No location set. Please open Settings." }
            return
        }

        // Check cache
        if !forceRefresh, let cached = cache[locationID] {
            let age = Date().timeIntervalSince(cached.timestamp)
            if age < cacheExpiry {
                DispatchQueue.main.async {
                    self.observations = cached.observations
                    self.lastFetched = cached.timestamp
                    self.errorMessage = nil
                }
                return
            }
        }

        DispatchQueue.main.async {
            self.observations = []
            self.isLoading = true
            self.errorMessage = nil
        }

        let urlString = "https://api.ebird.org/v2/data/obs/\(locationID)/recent"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.errorMessage = "Invalid location ID." }
            return
        }

        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-eBirdApiToken")

        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    return
                }
                guard let data = data else {
                    self.errorMessage = "No data received."
                    return
                }
                do {
                    let decoded = try JSONDecoder().decode([BirdObservation].self, from: data)
                    self.observations = decoded
                    if decoded.isEmpty {
                        self.errorMessage = "No observations found for this location."
                    } else {
                        let now = Date()
                        self.cache[locationID] = CachedObservations(observations: decoded, timestamp: now)
                        self.lastFetched = now
                    }
                } catch {
                    self.errorMessage = "Failed to decode response."
                }
            }
        }.resume()
    }

    // MARK: - Fetch location name only
    func fetchLocationName(locationID: String, completion: @escaping (String?) -> Void) {
        guard let apiKey = KeychainHelper.apiKey, !apiKey.isEmpty else {
            completion(nil)
            return
        }
        let urlString = "https://api.ebird.org/v2/data/obs/\(locationID)/recent?maxResults=1"
        guard let url = URL(string: urlString) else {
            completion(nil)
            return
        }
        var request = URLRequest(url: url)
        request.setValue(apiKey, forHTTPHeaderField: "X-eBirdApiToken")

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                DispatchQueue.main.async { completion(nil) }
                return
            }
            let decoded = try? JSONDecoder().decode([BirdObservation].self, from: data)
            DispatchQueue.main.async {
                completion(decoded?.first?.locName)
            }
        }.resume()
    }
}
