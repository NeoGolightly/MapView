//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 26.06.21.
//

import Foundation
import Quick
import Nimble
import CoreLocation
import MapKit

@testable import MapView

class ExtentionSpec: QuickSpec {
  override func spec() {
    describe("MKCoordinateRegion, CLLocationCoordinate2D and MKCoordinateSpan"){
      let region1 = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 10, longitude: 50),
                                       span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
      let region2 = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 10, longitude: 50),
                                       span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.01))
      let region3 = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 10, longitude: 50),
                                       span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
      it("conforms to hasable protocol"){
        expect(region1.hashValue).toNot(equal(region2.hashValue))
        expect(region1.hashValue).to(equal(region3.hashValue))
      }
    }
  }
}
