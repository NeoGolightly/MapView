//
//  ContentView.swift
//  MapViewExamples
//
//  Created by Michael Helmbrecht on 18.06.21.
//

import SwiftUI

struct ContentView: View {
  @State private var showMap = false
 
  var body: some View {
    Button("Show Map") {
      showMap.toggle()
    }
    .fullScreenCover(isPresented: $showMap, content: {
      NavigationView{
        MapTestView()
      }
    })
  }
}

struct ContentView_Previews: PreviewProvider {
  static var previews: some View {
    ContentView()
  }
}



