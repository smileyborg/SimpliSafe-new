//
//  GeofenceManager.swift
//  SimpliSafe
//
//  Created by Tyler Fox on 7/9/15.
//  Copyright (c) 2015 Tyler Fox. All rights reserved.
//

import CoreLocation

/** The possible states that location services can be in. */
public enum LocationServicesState {
    /** User has already granted this app permissions to access location services, and they are enabled and ready for use by this app. */
    case Available
    /** User has not yet responded to the dialog that grants this app permission to access location services. */
    case NotDetermined
    /** User has explicitly denied this app permission to access location services. (The user can enable permissions again for this app from the system Settings app.) */
    case Denied
    /** User does not have ability to enable location services (e.g. parental controls, corporate policy, etc). */
    case Restricted
    /** User has turned off location services device-wide (for all apps) from the system Settings app. */
    case Disabled
}

/**
Returns the current state of location services for this app.
*/
private func locationServicesState() -> LocationServicesState {
    if (!CLLocationManager.locationServicesEnabled()) {
        return .Disabled
    }
    else if (CLLocationManager.authorizationStatus() == .NotDetermined) {
        return .NotDetermined
    }
    else if (CLLocationManager.authorizationStatus() == .Denied) {
        return .Denied
    }
    else if (CLLocationManager.authorizationStatus() == .Restricted) {
        return .Restricted
    }
    
    return .Available
}

/**
A closure that is executed when the device exits or enters a geofence region.

:param: entered     If the device entered the geofence region this will be true;
                    if the device exited the geofence region this will be false.
*/
public typealias GeofenceBoundaryCrossedHandler = (entered: Bool) -> Void

public typealias LocationServicesPermissionCompletionHandler = (state: LocationServicesState) -> Void

/**
A class that manages a single geofence region.
*/
public class GeofenceManager: NSObject {
    private let locationManager = CLLocationManager()
    
    /// A closure that is executed whenever the geofence's boundary is crossed.
    private let boundaryCrossedHandler: GeofenceBoundaryCrossedHandler
    
    /**
    Designated initializer. Creates a new geofence manager.
    
    :param: handler     The handler to call whenever the device enters or exits the geofence region.
    */
    public init(handler: GeofenceBoundaryCrossedHandler) {
        boundaryCrossedHandler = handler
        super.init()
        locationManager.delegate = self
    }
    
    /// An array of completion handlers to call with the new location services permissions state
    /// once an update is received via the CLLocationManagerDelegate method.
    private var permissionCompletionHandlers = [LocationServicesPermissionCompletionHandler]()
    
    /**
    Requests permissions from the user to access location services (if needed), then asynchronously calls the provided
    completion handler once the permissions have been determined.
    
    :param: completion      The completion handler to execute asynchronously.
    */
    public func requestPermissions(completion: LocationServicesPermissionCompletionHandler) {
        permissionCompletionHandlers.append(completion)
        let state = locationServicesState()
        switch state {
        case .NotDetermined:
            locationManager.requestAlwaysAuthorization()
        default:
            callPermissionCompletionHandlers(state)
        }
    }
    
    /**
    Executes the completion handlers for all pending permission requests with the given location services state.
    
    :param: state   The current state of location services to pass into each completion handler.
    */
    private func callPermissionCompletionHandlers(state: LocationServicesState) {
        for completion in permissionCompletionHandlers {
            completion(state: state)
        }
        permissionCompletionHandlers.removeAll(keepCapacity: false)
    }
    
    /**
    Adds a new geofence. Any existing geofence will be removed before the new geofence is added.
    
    :param: region  The region to establish a geofence for.
    */
    public func addGeofence(region: CLCircularRegion) {
        removeGeofence()
        locationManager.startMonitoringForRegion(region)
    }
    
    /**
    Removes any existing geofence.
    */
    public func removeGeofence() {
        for regionObj in locationManager.monitoredRegions {
            if let region = regionObj as? CLRegion {
                locationManager.stopMonitoringForRegion(region)
            }
        }
    }
    
}

extension GeofenceManager: CLLocationManagerDelegate {
    public func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        switch status {
        case .AuthorizedAlways:
            callPermissionCompletionHandlers(.Available)
        case .Denied:
            callPermissionCompletionHandlers(.Denied)
        case .Restricted:
            callPermissionCompletionHandlers(.Restricted)
        case .NotDetermined:
            return; // don't care about this
        default:
            assertionFailure("Unexpected authorization status change: \(status)")
        }
    }
    
    public func locationManager(manager: CLLocationManager!, didEnterRegion region: CLRegion!) {
        boundaryCrossedHandler(entered: true)
    }
    
    public func locationManager(manager: CLLocationManager!, didExitRegion region: CLRegion!) {
        boundaryCrossedHandler(entered: false)
    }
    
    public func locationManager(manager: CLLocationManager!, monitoringDidFailForRegion region: CLRegion!, withError error: NSError!) {
        switch CLError(rawValue: error.code)! {
        case .RegionMonitoringDenied:
            print("Region monitoring denied!")
        case .RegionMonitoringFailure:
            print("Region monitoring failure!")
        case .RegionMonitoringSetupDelayed:
            print("Region monitoring setup delayed!")
        case .RegionMonitoringResponseDelayed:
            print("Region monitoring response delayed!")
        default:
            assertionFailure("Unexpected error: \(error)")
        }
    }
}
