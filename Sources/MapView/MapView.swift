import SwiftUI
import MapKit
import CoreLocation
import Combine
import Logging

//extension MapView{
//  public func renderOverlay(callback: @escaping (MKMapView, MKOverlay) -> MKOverlayRenderer) -> MapView {
//    self.mapViewService.mapViewRendererForOverlay = callback
//    return self
//  }
//}

var logger = Logger(label: "MapView")

public struct MapView: UIViewRepresentable
{
  public typealias UIViewType = MKMapView
  //FIXME: mapService not deinit
  let mapViewService: MapViewService
  
  public init(mapService: MapViewService) {
    self.mapViewService = mapService
    
    logger.logLevel = .trace
    logger.trace("init")
  }
  
  public func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView(frame: UIScreen.main.bounds)
    mapViewService.setMapView(mapView: mapView)
    mapView.delegate = context.coordinator
    configureMapView(mapView: mapView)
    logger.trace("makeUIView")
    return mapView
  }
  
  private func configureMapView(mapView: MKMapView){
    mapView.setRegion(mapViewService.coordinateRegion, animated: true)
    mapView.showsUserLocation = mapViewService.showsUserLocation
    mapView.setUserTrackingMode(mapViewService.userTrackingMode, animated: true)
    mapView.isPitchEnabled = mapViewService.isPitchEnabled
    mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
    if mapViewService.showsUserLocation {
      let userButton = MKUserTrackingButton(mapView: mapView)
      mapView.addSubview(userButton)
    }
  }
  
  public static func dismantleUIView(_ view: MKMapView, coordinator: MapViewCoodinator) {
    view.removeAnnotations(view.annotations)
    view.removeOverlays(view.overlays)
    view.delegate = nil
    logger.trace("dismantle")
  }
  
  
  public func updateUIView(_ mapView: MKMapView, context: Context) {
    
  }
  
  public func makeCoordinator() -> MapViewCoodinator {
    logger.trace("makeCoordinator")
    return MapViewCoodinator(self)
  }
  
  
  public class MapViewCoodinator: NSObject, MKMapViewDelegate  {
    let parent: MapView
    
    init(_ parent: MapView) {
      self.parent = parent
    }
    
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
      parent.mapViewService.heading = mapView.camera.heading
      parent.mapViewService.coordinateRegion = mapView.region
      parent.mapViewService.centerAltitude = mapView.camera.altitude
      parent.mapViewService.mapViewDidChangeVisibleRegion?(mapView)
    }
    
    
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool){
      parent.mapViewService.mapIsUpdating = true
    }
    
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
      parent.mapViewService.mapIsUpdating = false
    }
    
    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
      parent.mapViewService.mapViewDidUpdateUserLocation?(mapView, userLocation)
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      parent.mapViewService.mapViewRendererForOverlay?(mapView, overlay) ?? MKOverlayRenderer()
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      parent.mapViewService.mapViewViewForAnnotation?(mapView, annotation)
    }
    
    public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
      parent.mapViewService.mapViewDidSelectView?(mapView, view)
    }
    
    public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
      parent.mapViewService.mapViewDidDeselectView?(mapView, view)
    }
    
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//      let view = mapView.view(for: mapView.userLocation)
//      view?.isEnabled = false
    }
  }
  
}
