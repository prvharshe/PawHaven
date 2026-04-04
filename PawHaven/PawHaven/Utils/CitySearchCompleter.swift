// CitySearchCompleter.swift
// PawHaven
//
// Wraps MKLocalSearchCompleter to provide city name autocomplete.
// Used in the AddPet flow's location step.

import MapKit
import Observation

@Observable
@MainActor
final class CitySearchCompleter: NSObject, MKLocalSearchCompleterDelegate {

    var suggestions: [CitySearchResult] = []

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate    = self
        completer.resultTypes = .address
    }

    func update(query: String) {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else {
            suggestions = []
            return
        }
        completer.queryFragment = query
    }

    func clear() {
        suggestions = []
        completer.queryFragment = ""
    }

    // MARK: - MKLocalSearchCompleterDelegate

    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let results = completer.results
            .filter { result in
                // Skip street-level results (titles starting with a digit are usually addresses)
                !(result.title.first?.isNumber ?? false)
            }
            .prefix(5)
            .map { CitySearchResult(title: $0.title, subtitle: $0.subtitle) }

        MainActor.assumeIsolated { self.suggestions = Array(results) }
    }

    nonisolated func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        MainActor.assumeIsolated { self.suggestions = [] }
    }
}

struct CitySearchResult: Identifiable {
    let id      = UUID()
    let title:    String   // e.g. "Bangalore"
    let subtitle: String   // e.g. "Karnataka, India"

    /// The plain city name to store — title only, no region suffix.
    var cityName: String { title }
}
