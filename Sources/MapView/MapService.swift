//
//  File.swift
//  
//
//  Created by Michael Helmbrecht on 04.05.21.
//

import MapKit
import Combine

public final class MapService: ObservableObject{
  //
  public typealias ViewForAnnotation = (MKMapView, MKAnnotation) -> MKAnnotationView?
  public typealias ViewDidChangeVisibleRegion = (MKMapView) -> ()
  public typealias RendererForOverlay = (MKMapView, MKOverlay) -> MKOverlayRenderer
  //
  @Published public var showsUserLocation = false
  @Published public var userTrackingMode: MKUserTrackingMode = .none
  @Published public var isPitchEnabled = false
  @Published public var heading: CLLocationDirection = 0
  @Published public var coordinateRegion: MKCoordinateRegion = MKCoordinateRegion()
  //
  internal var mapViewDidChangeVisibleRegion: ViewDidChangeVisibleRegion?
  internal var mapViewDidUpdateUserLocation: ((MKMapView,MKUserLocation) -> ())?
  internal var mapViewViewForAnnotation: ViewForAnnotation?
  internal var mapViewRendererForOverlay: RendererForOverlay?
  internal var mapIsUpdating = false
  //
  private var lastCoordinateRegion: MKCoordinateRegion = MKCoordinateRegion()
  private var mapView: MKMapView?
  private var overlays: [MapViewOverlay] = []
  private var subscriptions = Set<AnyCancellable>()
  
  public init() {
    setBindings()
  }
  
  deinit {
    subscriptions.removeAll()
    subscriptions = []
  }
  
  public func setMapView(mapView: MKMapView){
    self.mapView = mapView
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
