import SwiftUI
import MapKit
import CoreLocation
import Combine

open class MapViewAnnotation: NSObject, MKAnnotation, Identifiable{
  public let id: String
  public var coordinate: CLLocationCoordinate2D
  public init(id: String = UUID().uuidString,
              coordinate: CLLocationCoordinate2D) {
    self.id = id
    self.coordinate = coordinate
  }
}

open class MapViewOverlay: Identifiable{
  public let id: String
  public var overlay: MKOverlay
  public init(id: String = UUID().uuidString,
              overlay: MKOverlay) {
    self.id = id
    self.overlay = overlay
  }
}


public struct MapView: UIViewRepresentable
{
  public typealias UIViewType = MKMapView
  @ObservedObject public var mapService: MapService
  
  public init(mapService: ObservedObject<MapService>) {
    self._mapService = mapService
//    print("MapView init")
  }
  
  public func makeUIView(context: Context) -> MKMapView {
    let mapView = MKMapView(frame: UIScreen.main.bounds)
    mapService.setMapView(mapView: mapView)
    mapView.delegate = context.coordinator
    configureMapView(mapView: mapView)
    print("makeMapView")
    return mapView
  }
  
  private func configureMapView(mapView: MKMapView){
    mapView.setRegion(mapService.coordinateRegion, animated: true)
    mapView.showsUserLocation = mapService.showsUserLocation
    mapView.setUserTrackingMode(mapService.userTrackingMode, animated: true)
    mapView.isPitchEnabled = mapService.isPitchEnabled
    mapView.pointOfInterestFilter = MKPointOfInterestFilter(including: [])
    if mapService.showsUserLocation {
      let userButton = MKUserTrackingButton(mapView: mapView)
      mapView.addSubview(userButton)
    }
  }
  
  public static func dismantleUIView(_ view: MKMapView, coordinator: MapViewCoodinator) {
    view.removeAnnotations(view.annotations)
    view.removeOverlays(view.overlays)
    view.delegate = nil
    print("dismantleMapView")
  }
  
  
  public func updateUIView(_ mapView: MKMapView, context: Context) {
    
  }
  
  public func makeCoordinator() -> MapViewCoodinator {
    print("Coordinator")
    return MapViewCoodinator(self)
  }
  
  
  public class MapViewCoodinator: NSObject, MKMapViewDelegate  {
    let parent: MapView
    
    init(_ parent: MapView) {
      self.parent = parent
    }
    
    public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
      parent.mapService.heading = mapView.camera.heading
      parent.mapService.coordinateRegion = mapView.region
      parent.mapService.mapViewDidChangeVisibleRegion?(mapView)
    }
    
    
    public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool){
      parent.mapService.mapIsUpdating = true
    }
    
    
    public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
      parent.mapService.mapIsUpdating = false
    }
    
    public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
      parent.mapService.mapViewDidUpdateUserLocation?(mapView, userLocation)
    }
    
    public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
      parent.mapService.mapViewRendererForOverlay?(mapView, overlay) ?? MKOverlayRenderer()
    }
    
    public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
      return parent.mapService.mapViewViewForAnnotation?(mapView, annotation)
    }
    
    
    public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//      let view = mapView.view(for: mapView.userLocation)
//      view?.isEnabled = false
    }
  }
  
}
