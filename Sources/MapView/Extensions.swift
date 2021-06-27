//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 04.05.21.
//

import MapKit


//MARK: Hashable
extension MKCoordinateRegion: Hashable
{
  public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool
  {
    return lhs.center == rhs.center && lhs.span == rhs.span
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(center)
    hasher.combine(span)
  }
}

extension CLLocationCoordinate2D: Hashable {
  public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(latitude)
    hasher.combine(longitude)
  }
}

extension MKCoordinateSpan: Hashable {
  public static func == (lhs: MKCoordinateSpan, rhs: MKCoordinateSpan) -> Bool {
    return lhs.latitudeDelta == rhs.latitudeDelta && lhs.longitudeDelta == rhs.longitudeDelta
  }
  
  public func hash(into hasher: inout Hasher) {
    hasher.combine(latitudeDelta)
    hasher.combine(longitudeDelta)
  }
}

