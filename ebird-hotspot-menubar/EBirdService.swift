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

class EBirdService: ObservableObject {
    @Published var observations: [BirdObservation] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func fetchRecentObservations() {
        guard let apiKey = KeychainHelper.apiKey, !apiKey.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "No API key set. Please open Settings." }
            return
        }
        guard let locationID = LocationStore.shared.currentLocationID, !locationID.isEmpty else {
            DispatchQueue.main.async { self.errorMessage = "No location set. Please open Settings." }
            return
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
