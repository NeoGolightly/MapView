//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 24.06.21.
//

import Quick
import Nimble
import CoreLocation
import MapKit

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
    
    let overlay = MapViewPolyline(coordinates: coordinates, isSelectable: true)
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
    
    Nimble.AsyncDefaults.timeout = .seconds(4)
    
    describe("adding") {
      context("an overlay") {
        let overlayCount = mapViewService.mapView.overlays.count
        let selectableOverlaysCount = mapViewService.selectableOverlays.count
        
        it("should be added to the MKMapView overlays and call the render delegate") {
         
          mapViewService.mapViewRendererForOverlay { mapView, returnOverlay in
            return MKOverlayRenderer(overlay: returnOverlay)
            
          }
          
          mapViewService.addOverlay(overlay)
          expect(mapViewService.mapView.overlays.count).to(equal(overlayCount + 1))
          expect(mapViewService.mapView.renderer(for: overlay)?.overlay as? MapViewPolyline).toEventually(equal(overlay))
        }
        
        it("should be added to the isSelectable dictionary") {
          expect(mapViewService.selectableOverlays.count).to(equal(selectableOverlaysCount + 1))
          expect(mapViewService.selectableOverlays[overlay.id] as? MapViewPolyline).to(equal(overlay))
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
        let overlayCount = mapViewService.mapView.overlays.count
        let selectableOverlaysCount = mapViewService.selectableOverlays.count
        let selectableOverlaysCountFromArray = overlays.filter{ $0.isSelectable }
        
        it("should be added to the MKMapView overlays") {
          mapViewService.addOverlays(overlays)
          expect{ mapViewService.mapView.overlays.count }.to(equal(overlayCount + overlays.count))
        }
        
        it("should be added to the isSelectable dictionary") {
          expect(mapViewService.selectableOverlays.count).to(equal(selectableOverlaysCount + selectableOverlaysCountFromArray.count))
          expect(Array(mapViewService.selectableOverlays.values) as? [MapViewPolyline]).to(contain(selectableOverlaysCountFromArray))
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
    
    describe("removing all overlays") {
      it("should remove all selectable overlays and all overlays in mapView"){
        mapViewService.removeAllOverlays()
        expect(mapViewService.selectableOverlays.count).to(equal(0))
        expect(mapViewService.mapView.overlays.count).to(equal(0))
      }
    }
  }
}
