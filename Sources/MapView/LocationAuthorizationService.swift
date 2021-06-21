//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 21.06.21.
//

import Foundation
import CoreLocation
import SwiftUI

@propertyWrapper
public class LocationAuthorizationService {
  
  private var context = Context()
  public init(){}
  
  public class Context: NSObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    public var status: CLAuthorizationStatus = .notDetermined
    public override init() {
      super.init()
      locationManager.delegate = self
      status = locationManager.authorizationStatus
    }
    
    public func requestAuthorization(authorizationStatus: CLAuthorizationStatus) {
      logger.debug("request")
      switch authorizationStatus {
      case .authorizedWhenInUse:
        locationManager.requestWhenInUseAuthorization()
      case .authorizedAlways:
        locationManager.requestAlwaysAuthorization()
      default:
        break
      }
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
      status = manager.authorizationStatus
    }
  }
  
  public var wrappedValue: Context {
    get {context}
  }
  
  public var projectedValue: Binding<CLAuthorizationStatus> {
    Binding<CLAuthorizationStatus> {
      self.context.status
    }
    set: { _ in }
  }
  
}
