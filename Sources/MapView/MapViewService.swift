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

public final class MapViewService: ObservableObject{
  //
  public typealias ViewForAnnotation = (MKMapView, MKAnnotation) -> MKAnnotationView?
  public typealias ViewDidChangeVisibleRegion = (MKMapView) -> ()
  public typealias RendererForOverlay = (MKMapView, MKOverlay) -> MKOverlayRenderer
  public typealias DidSelectView = (MKMapView, MKAnnotationView) -> ()
  public typealias DidDeselectView = (MKMapView, MKAnnotationView) -> ()
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
  internal var mapIsUpdating = false
  //
  private var lastCoordinateRegion: MKCoordinateRegion = MKCoordinateRegion()
  private weak var mapView: MKMapView?
  private var overlays: [MapViewOverlay] = []
  private var locationManager: CLLocationManager?
  private var tapGestureRecognizer: UITapGestureRecognizer
  private var subscriptions = Set<AnyCancellable>()
  
  public init() {
    tapGestureRecognizer = UITapGestureRecognizer()

    setBindings()
  }
  
  deinit {
    print("deinit MapService")
    subscriptions.removeAll()
    subscriptions = []
    mapView?.gestureRecognizers?.forEach{ mapView?.removeGestureRecognizer($0)}
  }
  
  @objc
  internal func handleTap(gr: UITapGestureRecognizer) {
    
    if gr.state == .ended {
      let point = gr.location(ofTouch: 0, in: mapView)
      guard let mapView = mapView else { return }
      let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
      let mapPoint = MKMapPoint(coordinate)
      for overlay in mapView.overlays {
        if overlay is MKPolyline {
          if let renderer = mapView.renderer(for: overlay) as? MKPolylineRenderer{
            let polylineViewPoint = renderer.point(for: mapPoint)
            if renderer.path.boundingBoxOfPath.contains(polylineViewPoint){
              print("It's a path!!")
              renderer.strokeColor = .init(red: 1, green: 0, blue: 0, alpha: 0.4)
            }
            else {
              renderer.strokeColor = .init(red: 0, green: 1, blue: 0, alpha: 0.4)
            }
          }
        }
      }
    }
  }
  
  //TODO: Make delegate call and enum for auth type and completion callback
  public func requestAlwaysAuthorization(){
    locationManager = CLLocationManager()
    locationManager?.requestAlwaysAuthorization()
  }
  
  internal func setMapView(mapView: MKMapView){
    self.mapView = mapView
    tapGestureRecognizer.addTarget(self, action: #selector(self.handleTap(gr:)))
    tapGestureRecognizer.numberOfTapsRequired = 1
    tapGestureRecognizer.numberOfTouchesRequired = 1
    mapView.addGestureRecognizer(tapGestureRecognizer)
  }
  
  internal func removeMapView() {
    self.mapView = nil
    mapView?.gestureRecognizers?.forEach{ mapView?.removeGestureRecognizer($0)}
  }
  
  public func setViewForAnnotation(setup: @escaping ViewForAnnotation){
    mapViewViewForAnnotation = setup
  }
  
  public func mapViewDidChangeVisibleRegion(setup: @escaping ViewDidChangeVisibleRegion) {
    mapViewDidChangeVisibleRegion = setup
  }
  
  public func mapViewRendererForOverlay(setup: @escaping RendererForOverlay) {
    mapViewRendererForOverlay = setup
  }
  
  public func mapViewDidSelectView(setup: @escaping DidSelectView) {
    mapViewDidSelectView = setup
  }
  
  public func mapViewDidDeselectView(setup: @escaping DidDeselectView) {
    mapViewDidDeselectView = setup
  }
  
  private func setBindings() {
    _showsUserLocation.projectedValue.sink { [weak self] value in
      self?.mapView?.showsUserLocation = value
    }.store(in: &subscriptions)
    
    _userTrackingMode.projectedValue.sink { [weak self] value in
      self?.mapView?.userTrackingMode = value
    }.store(in: &subscriptions)
    
    _isPitchEnabled.projectedValue.sink { [weak self] value in
      self?.mapView?.isPitchEnabled = value
    }.store(in: &subscriptions)
    
    _coordinateRegion.projectedValue.sink { [weak self] region in
      guard self?.mapIsUpdating == false else { return }
      if region != self?.lastCoordinateRegion {
        self?.mapView?.setRegion(region, animated: true)
        self?.lastCoordinateRegion = region
      }
    }.store(in: &subscriptions)
    
    _mapType.projectedValue.sink { [weak self] mapType in
      self?.mapView?.mapType = mapType
    }.store(in: &subscriptions)
  }
  
  public func addAnnotation(_ annotation: MapViewAnnotation) {
    mapView?.addAnnotation(annotation)
  }
  
  public func removeAnnotation(id: String) {
    guard let annotations = mapView?.annotations.compactMap({$0 as? MapViewAnnotation}),
          let annotation = annotations.first(where: {$0.id == id})
    else { return }
    mapView?.removeAnnotation(annotation)
  }
  
  public func removeAnnotations(ids: [String]) {
    guard let annotations = mapView?.annotations.compactMap({$0 as? MapViewAnnotation}) else { return }
    let filteredAnnotations = annotations.filter{ ids.contains($0.id) }
    mapView?.removeAnnotations(filteredAnnotations)
  }
  
  public func removeAllAnnotations() {
    guard let mapView = mapView else { return }
    mapView.removeAnnotations(mapView.annotations)
  }
  
  public func addOverlay(_ overlay: MapViewOverlay) {
    overlays.append(overlay)
    mapView?.addOverlay(overlay.overlay)
  }
    
  public func addOverlays(_ overlays: [MapViewOverlay]) {
    self.overlays.append(contentsOf: overlays)
    mapView?.addOverlays(overlays.map{$0.overlay})
  }
  
  public func removeOverlay(id: String) {
    guard let overlayIdx = overlays.firstIndex(where: {$0.id == id}) else { return }
    let overlay = overlays.remove(at: overlayIdx)
    mapView?.removeOverlay(overlay.overlay)
  }
  
  public func removeOverlays(ids: [String]) {
    let toRemoveOverlays = overlays.filter({ ids.contains($0.id) })
    overlays.removeAll(where: { ids.contains($0.id) })
    mapView?.removeOverlays(toRemoveOverlays.map{$0.overlay})
  }
  
  public func removeAllOverlays() {
    guard let mapView = mapView else { return }
    overlays.removeAll()
    mapView.removeOverlays(mapView.overlays)
  }
}