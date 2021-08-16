//
//  SwiftUIView.swift
//  
//
//  Created by Leo Dion on 8/16/21.
//

import SwiftUI
import Combine

class HelloObject : ObservableObject {
  let baseURL = URL(string: "http://localhost:8080/hello/")!
  @Published var name : String = ""
  @Published var message : String = ""
  
  var refreshTrigger = PassthroughSubject<Void, Never> ()
  
  init() {
    self.refreshTrigger.map{
      self.name
    }
    .compactMap{    self.baseURL.appendingPathComponent($0)}
    .flatMap(
      URLSession.shared.dataTaskPublisher
    )
    .map(\.data)
    .compactMap{String(data: $0, encoding: .utf8)}
    .replaceError(with: "")
    .receive(on: DispatchQueue.main)
      .print()
      .assign(to: &self.$message)
  }
  
  func refresh () {
    self.refreshTrigger.send(())
  }
}

struct HelloView: View {
  @EnvironmentObject var object : HelloObject
  
    var body: some View {
      VStack{
        TextField("name", text: self.$object.name)
        Button("Send", action: self.object.refresh)
        Text(self.object.message)
      }.padding(16.0)
    }
}

struct HelloView_Previews: PreviewProvider {
    static var previews: some View {
      HelloView().environmentObject(HelloObject())
    }
}
