//
//  ContentView.swift
//  MapViewExamples
//
//  Created by Michael Helmbrecht on 18.06.21.
//

import SwiftUI
import MapView
import MapKit
import CoreLocation

class TestViewModel: ObservableObject {
  var mapService: MapViewService = MapViewService()
}

struct ContentView: View {
  @StateObject private var viewModel = TestViewModel()
  
  var body: some View {
    MapView(mapService: viewModel.mapService)
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}
