// LocationManager.swift
// PawHaven
//
// Observable wrapper around CLLocationManager.
// Shared by PetMapViewModel (continuous map location) and
// ReviewPublishStep (one-shot pet location capture).

import CoreLocation
import Observation

@Observable
@MainActor
final class LocationManager: NSObject, CLLocationManagerDelegate {

    var location:    CLLocation?                      = nil
    var authStatus:  CLAuthorizationStatus            = .notDetermined

    private let clManager = CLLocationManager()

    override init() {
        super.init()
        clManager.delegate        = self
        clManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        authStatus                = clManager.authorizationStatus
    }

    // MARK: - Public API

    /// Request permission then kick off a single location fix.
    func requestPermissionAndLocation() {
        switch authStatus {
        case .notDetermined:
            clManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            clManager.requestLocation()
        default:
            break
        }
    }

    // MARK: - CLLocationManagerDelegate

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let loc = locations.last else { return }
        MainActor.assumeIsolated { self.location = loc }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        // Silently ignore — callers observe `location` for nil-ness
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didChangeAuthorization status: CLAuthorizationStatus
    ) {
        MainActor.assumeIsolated {
            self.authStatus = status
            if status == .authorizedWhenInUse || status == .authorizedAlways {
                self.clManager.requestLocation()
            }
        }
    }
}
