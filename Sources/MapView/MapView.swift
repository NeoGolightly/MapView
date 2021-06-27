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

public struct MapViewServiceEnvironmentKey: EnvironmentKey {
    static var defaultValue: MapViewService = .init()
}

public extension EnvironmentValues {
    var mapViewService: MapViewService {
        get { self[MapViewServiceEnvironmentKey.self] }
//        set { self[ChartStyleEnvironmentKey.self] = newValue }
    }
}


var logger: Logger {
  var logger = Logger(label: "MapView")
  logger.logLevel = .trace
  return logger
}

public struct MapView: UIViewRepresentable
{
  
  //FIXME: mapService not deinit
  @State private var mapViewService: MapViewService
  
  public init(mapService: MapViewService) {
    self.mapViewService = mapService
    logger.trace("init MapView")

  }
  
  public func makeUIView(context: Context) -> MKMapView {
    let mapView = mapViewService.mapView
    configureMapView(mapView: mapView)
    logger.trace("makeUIView")
    return mapView
  }
  
  private func regionChanged(to value: MKCoordinateRegion) {
    logger.debug("region changed")
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
    
  public func updateUIView(_ mapView: MKMapView, context: Context) {
    logger.trace("update MapView")
//    mapViewService.mapView.setRegion(region, animated: true)
  }
}
