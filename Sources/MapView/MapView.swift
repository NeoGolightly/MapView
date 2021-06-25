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

struct MapViewServiceEnvironmentKey: EnvironmentKey {
    static var defaultValue: MapViewService = .init()
}

extension EnvironmentValues {
    var mapViewService: MapViewService {
        get { self[MapViewServiceEnvironmentKey.self] }
//        set { self[ChartStyleEnvironmentKey.self] = newValue }
    }
}


var logger = Logger(label: "MapView")

public struct MapView: UIViewRepresentable
{
  
  public typealias UIViewType = MKMapView
  
  //FIXME: mapService not deinit
  @State var mapViewService: MapViewService
  public init(mapService: MapViewService) {
    self.mapViewService = mapService
    logger.logLevel = .trace
    logger.trace("init")
  }
  
  public func makeUIView(context: Context) -> MKMapView {
    let mapView = mapViewService.mapView
//    mapView.delegate = context.coordinator
    
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
  
  public static func dismantleUIView(_ view: MKMapView, coordinator: Void) {
    view.removeAnnotations(view.annotations)
    view.removeOverlays(view.overlays)
    view.delegate = nil
    logger.trace("dismantle")
  }
  
  
  public func updateUIView(_ mapView: MKMapView, context: Context) {
    
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
      print("overlay: \(overlay)")
      guard let overlay = overlay as? MapViewOverlay else { return MKOverlayRenderer() }
      
      return parent.mapViewService.mapViewRendererForOverlay?(mapView, overlay) ?? MKOverlayRenderer()
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
