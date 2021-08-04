//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 04.05.21.
//

import MapKit
import Combine
import CoreLocation
import Logging
import SwiftUI


open class MapViewAnnotation: NSObject, MKAnnotation, Identifiable{
  public let id: String
  public var coordinate: CLLocationCoordinate2D
  public var title: String?
  public var subtitle: String?
  public init(id: String = UUID().uuidString,
              coordinate: CLLocationCoordinate2D,
              title: String? = nil,
              subtitle: String? = nil) {
    self.id = id
    self.coordinate = coordinate
    self.title = title
    self.subtitle = subtitle
  }
}

final public class MapViewPolyline: MKPolyline, MapViewOverlay{
  public internal(set) var id: String = UUID().uuidString
  public internal(set) var isSelectable: Bool = false
  public convenience init(id: String = UUID().uuidString,
                          coordinates: [CLLocationCoordinate2D],
                          isSelectable: Bool = false) {
    self.init(coordinates: coordinates, count: coordinates.count)
    self.id = id
    self.isSelectable = isSelectable
  }
  
  
}

public protocol MapViewOverlay: MKOverlay{
  var id: String { get }
  var isSelectable: Bool { get }
}


public final class MapViewService: NSObject, ObservableObject{
  //
  public let mapView: MKMapView = MKMapView(frame: UIScreen.main.bounds)
  //
  public typealias ViewForAnnotation = (MKMapView, MKAnnotation) -> MKAnnotationView?
  public typealias ViewDidChangeVisibleRegion = (MKMapView) -> ()
  public typealias RendererForOverlay = (MKMapView, MapViewOverlay) -> MKOverlayRenderer
  public typealias DidSelectView = (MKMapView, MKAnnotationView) -> ()
  public typealias DidDeselectView = (MKMapView, MKAnnotationView) -> ()
  public typealias DidSelectPolyline = (MKMapView, MKPolylineRenderer) -> ()
  public typealias DidDeselectPolyline = (MKMapView, MKPolylineRenderer) -> ()
  //
  @Published public var showsUserLocation = false
  @Published public var userTrackingMode: MKUserTrackingMode = .none
  @Published public var isPitchEnabled = false
  @Published public var heading: CLLocationDirection = 0
  @Published public var centerAltitude: CLLocationDistance = 0
  @Published public var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion()
  @Published public var mapType: MKMapType = MKMapType.standard
  //
  internal var mapViewDidChangeVisibleRegion: ViewDidChangeVisibleRegion?
  internal var mapViewDidUpdateUserLocation: ((MKMapView,MKUserLocation) -> ())?
  internal var mapViewViewForAnnotation: ViewForAnnotation?
  internal var mapViewRendererForOverlay: RendererForOverlay?
  internal var mapViewDidSelectView: DidSelectView?
  internal var mapViewDidDeselectView: DidDeselectView?
  internal var mapViewDidSelectPolyline: DidSelectPolyline?
  internal var mapViewDidDeselectPolyline: DidDeselectPolyline?
  internal var mapIsUpdating = false
  //
  private var lastCoordinateRegion: MKCoordinateRegion = MKCoordinateRegion()
  private var locationManager: CLLocationManager?
  private var tapGestureRecognizer: UITapGestureRecognizer
  private(set) var selectableOverlays: [String: MapViewOverlay] = [:]
  private var subscriptions = Set<AnyCancellable>()
  
  
  public override init() {
    logger.trace("init MapViewService")
    tapGestureRecognizer = UITapGestureRecognizer()
    super.init()
    mapView.delegate = self
    setBindings()
    tapGestureRecognizer.addTarget(self, action: #selector(self.handleTap(gr:)))
    tapGestureRecognizer.numberOfTapsRequired = 1
    tapGestureRecognizer.numberOfTouchesRequired = 1
    mapView.addGestureRecognizer(tapGestureRecognizer)
    
  }
  
  deinit {
    logger.debug("deinit MapService")
    subscriptions.removeAll()
    subscriptions = []
    mapView.gestureRecognizers?.forEach{ mapView.removeGestureRecognizer($0)}
    mapView.removeAnnotations(mapView.annotations)
    mapView.removeOverlays(mapView.overlays)
    mapView.delegate = nil
  }
  
  //TODO: Make delegate call and enum for auth type and completion callback
  public func requestAlwaysAuthorization(){
    locationManager = CLLocationManager()
    locationManager?.requestAlwaysAuthorization()
  }
  
  internal func setMapView(mapView: MKMapView){
    tapGestureRecognizer.addTarget(self, action: #selector(self.handleTap(gr:)))
    tapGestureRecognizer.numberOfTapsRequired = 1
    tapGestureRecognizer.numberOfTouchesRequired = 1
    mapView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  private func setBindings() {
    _showsUserLocation.projectedValue.sink { [weak self] value in
      self?.mapView.showsUserLocation = value
    }.store(in: &subscriptions)
    
    _userTrackingMode.projectedValue.sink { [weak self] value in
      self?.mapView.userTrackingMode = value
    }.store(in: &subscriptions)
    
    _isPitchEnabled.projectedValue.sink { [weak self] value in
      self?.mapView.isPitchEnabled = value
    }.store(in: &subscriptions)
    
    _coordinateRegion.projectedValue.sink { [weak self] region in
      guard self?.mapIsUpdating == false else { return }
      if region != self?.lastCoordinateRegion {
        self?.mapView.setRegion(region, animated: true)
        self?.lastCoordinateRegion = region
      }
    }.store(in: &subscriptions)
    
    _mapType.projectedValue.sink { [weak self] mapType in
      self?.mapView.mapType = mapType
    }.store(in: &subscriptions)
  }
}

//MARK: Handle Touch
extension MapViewService {
  
//  @objc func didTapOnMap(sender: UITapGestureRecognizer) {
//              let tapLocation = sender.location(in: mapView.map)
//              let coordinate = mapView.map.convert(tapLocation, toCoordinateFrom: mapView.map)
//              
//              selectedCoord = coordinate
//              getForecast()
//          }
  //FIXME: Better: use mapView.visibleMapRect.contains(MKMapRect) to check for overlay in "visibleRect"
  //FIXME: Save all overlays with isSelectable = true in Dictionary to faster iterate (an to not use mapView.overlays)
  @objc
  internal func handleTap(gr: UITapGestureRecognizer) {
    if gr.state == .ended {
      let point = gr.location(ofTouch: 0, in: mapView)
//      guard let mapView = mapView else { return }
      let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
      let mapPoint = MKMapPoint(coordinate)
      for overlay in selectableOverlays.values {
        
        if overlay is MKPolyline {
          if let renderer = mapView.renderer(for: overlay) as? MKPolylineRenderer{
            let polylineViewPoint = renderer.point(for: mapPoint)
            if renderer.path.contains(polylineViewPoint){
              mapViewDidSelectPolyline?(mapView, renderer)
            }
            else {
              mapViewDidDeselectPolyline?(mapView, renderer)
            }
          }
        }
      }
    }
  }
}

//MARK: Delegate Callbacks
extension MapViewService {
  public func setViewForAnnotation(callback: @escaping ViewForAnnotation){
    mapViewViewForAnnotation = callback
  }
  
  public func mapViewDidChangeVisibleRegion(callback: @escaping ViewDidChangeVisibleRegion) {
    mapViewDidChangeVisibleRegion = callback
  }
  
  public func mapViewRendererForOverlay(callback: @escaping RendererForOverlay) {
    mapViewRendererForOverlay = callback
  }
  
  public func mapViewDidSelectView(callback: @escaping DidSelectView) {
    mapViewDidSelectView = callback
  }
  
  public func mapViewDidDeselectView(callback: @escaping DidDeselectView) {
    mapViewDidDeselectView = callback
  }
  
  public func mapViewDidSelectPolyline(callback: @escaping DidSelectPolyline) {
    mapViewDidSelectPolyline = callback
  }
  
  public func mapViewDidDeselectPolyline(callback: @escaping DidDeselectPolyline) {
    mapViewDidDeselectPolyline = callback
  }
}

//MARK: Annotations
extension MapViewService {
  public func addAnnotation(_ annotation: MapViewAnnotation) {
    mapView.addAnnotation(annotation)
  }
  
  public func removeAnnotation(id: String) {
    let annotations = mapView.annotations.compactMap({$0 as? MapViewAnnotation})
    guard let annotation = annotations.first(where: {$0.id == id})
    else { return }
    mapView.removeAnnotation(annotation)
  }
  
  public func removeAnnotations(ids: [String]) {
    let annotations = mapView.annotations.compactMap({$0 as? MapViewAnnotation})
    let filteredAnnotations = annotations.filter{ ids.contains($0.id) }
    mapView.removeAnnotations(filteredAnnotations)
  }
  
  public func removeAllAnnotations() {
    mapView.removeAnnotations(mapView.annotations)
  }
}

//MARK: Overlays
extension MapViewService {
  public func addOverlay(_ overlay: MapViewOverlay) {
    if overlay.isSelectable {selectableOverlays[overlay.id] = overlay }
    mapView.addOverlay(overlay)
  }
    
  public func addOverlays(_ overlays: [MapViewOverlay]) {
    overlays
      .lazy
      .filter{$0.isSelectable}
      .forEach{ self.selectableOverlays[$0.id] = $0 }
    mapView.addOverlays(overlays)
  }
  
  public func removeOverlay(id: String) {
    guard let mapViewOverlays = mapView.overlays as? [MapViewOverlay],
          let overlayToRemove =  mapViewOverlays.first(where: {$0.id == id})
    else { return }
    if overlayToRemove.isSelectable { selectableOverlays.removeValue(forKey: overlayToRemove.id) }
    mapView.removeOverlay(overlayToRemove)
  }
  
  public func removeOverlays(ids: [String]) {
    guard let mapViewOverlays = mapView.overlays as? [MapViewOverlay] else { return }
    let overlaysToRemove = mapViewOverlays.filter({ ids.contains($0.id) })
    overlaysToRemove
      .lazy
      .filter{$0.isSelectable}
      .forEach{ self.selectableOverlays.removeValue(forKey: $0.id) }
    mapView.removeOverlays(overlaysToRemove)
  }
  
  public func removeAllOverlays() {
    selectableOverlays.removeAll()
    mapView.removeOverlays(mapView.overlays)
  }
}


//MARK: Delegate
extension MapViewService:  MKMapViewDelegate {
  public func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
    heading = mapView.camera.heading
    coordinateRegion = mapView.region
    centerAltitude = mapView.camera.altitude
    mapViewDidChangeVisibleRegion?(mapView)
  }
  
  
  public func mapView(_ mapView: MKMapView, regionWillChangeAnimated animated: Bool){
    mapIsUpdating = true
  }
  
  
  public func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool){
    mapIsUpdating = false
  }
  
  public func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
    mapViewDidUpdateUserLocation?(mapView, userLocation)
  }
  
  public func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    guard let overlay = overlay as? MapViewOverlay else { fatalError("overlay is not type of MapViewOverlay") }
    return mapViewRendererForOverlay?(mapView, overlay) ?? MKOverlayRenderer()
  }
  
  public func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
    mapViewViewForAnnotation?(mapView, annotation)
  }
  
  public func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
    mapViewDidSelectView?(mapView, view)
  }
  
  public func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
    mapViewDidDeselectView?(mapView, view)
  }
  
  public func mapView(_ mapView: MKMapView, didAdd views: [MKAnnotationView]) {
//      let view = mapView.view(for: mapView.userLocation)
//      view?.isEnabled = false
  }
}


//MARK: Helper
extension MapViewService {
  public func calculateDegreeAngle(startCoordinate: CLLocationCoordinate2D,
                                   centerCoordinate: CLLocationCoordinate2D,
                                   destinationCoordinate: CLLocationCoordinate2D) -> Double {
    let centerPoint = mapView.convert(centerCoordinate, toPointTo: mapView)
    let startPoint = mapView.convert(startCoordinate, toPointTo: mapView)
    let destinationPoint = mapView.convert(destinationCoordinate, toPointTo: mapView)
    
    let result = Self.angleBetweenThreePoints(center: centerPoint, firstPoint: startPoint, secondPoint: destinationPoint)
    return Measurement(value: result, unit: UnitAngle.radians).converted(to: UnitAngle.degrees).value
  }
  
  static func angleBetweenThreePoints(center: CGPoint, firstPoint: CGPoint, secondPoint: CGPoint) -> Double {
    let firstAngle = atan2(firstPoint.y - center.y, firstPoint.x - center.x)
    let secondAnlge = atan2(secondPoint.y - center.y, secondPoint.x - center.x)
    var angleDiff = firstAngle - secondAnlge
    
    if angleDiff < 0 {
      angleDiff *= -1
    }
    
    return Double(angleDiff)
  }
}
