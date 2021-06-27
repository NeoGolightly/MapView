//
//  MapTestView.swift
//  MapViewExamples
//
//  Created by Michael Helmbrecht on 21.06.21.
//

import SwiftUI
import MapView
import MapKit
import CoreLocation

class TestViewModel: ObservableObject {
  @Published var mapService: MapViewService = MapViewService()
  @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.902579821250846,
                                                                            longitude: 10.42653534194526),
                                             span: MKCoordinateSpan(latitudeDelta: 0.01,
                                                                    longitudeDelta: 0.01))
  init() {
    mapService.coordinateRegion = region
    mapService.showsUserLocation = true
//    mapService.userTrackingMode = .followWithHeading
    DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
      self.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.802579821250846,
                                                                                      longitude: 10.42653534194526),
                                                       span: MKCoordinateSpan(latitudeDelta: 0.01,
                                                                              longitudeDelta: 0.01))
    }
  }
  
  func update() {
    region = mapService.coordinateRegion
  }
}


struct MapTestView: View {
  @StateObject private var viewModel = TestViewModel()
  @Environment(\.presentationMode) var presentationMode
  var body: some View {
    let _ = print("update body")
    VStack {
      MapView(mapService: viewModel.mapService)
      Text("\(viewModel.region.center.latitude), \(viewModel.region.center.longitude)")
    }
    .navigationBarTitle("Map", displayMode: .inline)
    .toolbar {
      ToolbarItem(placement: ToolbarItemPlacement.cancellationAction) {
        Button("Close") {
          presentationMode.wrappedValue.dismiss()
        }
      }
      
      ToolbarItem(placement: ToolbarItemPlacement.primaryAction) {
        Button("Update") {
          viewModel.update()
        }
      }
    }
  }
}

struct MapTestView_Previews: PreviewProvider {
    static var previews: some View {
        MapTestView()
    }
}
