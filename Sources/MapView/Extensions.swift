//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 04.05.21.
//

import MapKit

extension CLLocationCoordinate2D: Equatable {
  public static func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
  }
}


extension MKCoordinateRegion: Equatable
{
  public static func == (lhs: MKCoordinateRegion, rhs: MKCoordinateRegion) -> Bool
  {
    if lhs.center.latitude != rhs.center.latitude || lhs.center.longitude != rhs.center.longitude
    {
      return false
    }
    if lhs.span.latitudeDelta != rhs.span.latitudeDelta || lhs.span.longitudeDelta != rhs.span.longitudeDelta
    {
      return false
    }
    return true
  }
}

extension MKOverlay {
  public func toMapViewOverlay() -> MapViewOverlay {
    return MapViewOverlay(overlay: self)
  }
  
  public func toMapViewOverlay(id: String) -> MapViewOverlay {
    return MapViewOverlay(id: id, overlay: self)
  }
}

public extension MKMultiPoint {
    var coordinates: [CLLocationCoordinate2D] {
        var coords = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid,
                                              count: pointCount)

        getCoordinates(&coords, range: NSRange(location: 0, length: pointCount))

        return coords
    }
}
