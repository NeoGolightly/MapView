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
  var mapService: MapViewService = MapViewService()
  init() {
    mapService.coordinateRegion = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude: 51.902579821250846,
                                                                                    longitude: 10.42653534194526),
                                                     span: MKCoordinateSpan(latitudeDelta: 0.01,
                                                                            longitudeDelta: 0.01))
    mapService.showsUserLocation = true
  }
}


struct MapTestView: View {
  @StateObject private var viewModel = TestViewModel()
  @Environment(\.presentationMode) var presentationMode
  var body: some View {
    VStack {
      MapView(mapService: viewModel.mapService)
      Text("\(viewModel.mapService.coordinateRegion.center.latitude), \(viewModel.mapService.coordinateRegion.center.longitude)")
    }
    .navigationBarTitle("Map", displayMode: .inline)
    .toolbar {
      ToolbarItem(placement: ToolbarItemPlacement.cancellationAction) {
        Button("Close") {
          presentationMode.wrappedValue.dismiss()
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
