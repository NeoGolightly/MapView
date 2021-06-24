//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 24.06.21.
//

import Quick
import Nimble
import CoreLocation
@testable import MapView

class OverlaySpec: QuickSpec {
  override func spec() {
    let mapViewService = MapViewService()
    let coordinates: [CLLocationCoordinate2D] = [
      CLLocationCoordinate2D(latitude: 51.910608203069245, longitude: 10.423789822413294),
      CLLocationCoordinate2D(latitude: 51.910557249786535, longitude: 10.423887634602812),
      CLLocationCoordinate2D(latitude: 51.91057468117923, longitude: 10.424154987920831),
      CLLocationCoordinate2D(latitude: 51.910513000836204, longitude: 10.42460709759683),
      CLLocationCoordinate2D(latitude: 51.91032259576357, longitude: 10.425376553537554),
      CLLocationCoordinate2D(latitude: 51.91029443719642, longitude: 10.425583045997838),
      CLLocationCoordinate2D(latitude: 51.9101227655659, longitude: 10.425708466787947),
    ]
    let overlay = MapViewPolyline(coordinates: coordinates)
    let overlays = [
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates),
      MapViewPolyline(coordinates: coordinates)
    ]
    
    describe("adding") {
      context("an overlay") {
        it("should be added to the MKMapView overlays") {
          let overlayCount = mapViewService.mapView.overlays.count
          mapViewService.addOverlay(overlay)
          expect{ mapViewService.mapView.overlays.count }.to(equal(overlayCount + 1))
        }
      }
    }
    
    describe("removing") {
      context("an overlay") {
        it("should be removed from the MKMapView overlays") {
          let overlayCount = mapViewService.mapView.overlays.count
          mapViewService.removeOverlay(id: overlay.id)
          expect{ mapViewService.mapView.overlays.count }.to(equal(overlayCount - 1))
        }
      }
    }
    
    describe("adding") {
      context("overlays") {
        it("should be added to the MKMapView overlays") {
          let overlayCount = mapViewService.mapView.overlays.count
          mapViewService.addOverlays(overlays)
          expect{ mapViewService.mapView.overlays.count }.to(equal(overlayCount + overlays.count))
        }
      }
    }
    
    describe("removing") {
      context("overlays") {
        it("should be removed from the MKMapView overlays") {
          let overlayCount = mapViewService.mapView.overlays.count
          
          let toRemoveOverlays = [
            overlays[0],
            overlays[2],
            overlays[4]
          ]
          mapViewService.removeOverlays(ids: toRemoveOverlays.map{$0.id})
          expect{ mapViewService.mapView.overlays.count }.to(equal(overlayCount - toRemoveOverlays.count))
        }
      }
    }
  }
}
