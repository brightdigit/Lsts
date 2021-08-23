//
//  SwiftUIView.swift
//  
//
//  Created by Leo Dion on 8/16/21.
//

import SwiftUI
import Combine
import LstsKit

class HelloObject : ObservableObject {
  let baseURL = URL(string: "http://localhost:8080/hello")!
  @Published var person = Person()
  @Published var message : String = ""
  
  let encoder = JSONEncoder()
  
  var refreshTrigger = PassthroughSubject<Void, Never> ()
  
  init() {
    self.refreshTrigger.map{
      self.person
    }
    .compactMap{
      try? self.encoder.encode($0)
    }
    .map{ (body) -> URLRequest in
      var request = URLRequest(url: self.baseURL)
      request.httpBody = body
      request.addValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpMethod = "POST"
      return request
    }
    .flatMap{ request in
      URLSession.shared.dataTaskPublisher(for: request)
    }
    .map(\.data)
    .compactMap{
      String(data: $0, encoding: .utf8)
    }
    .replaceError(with: "")
    .receive(on: DispatchQueue.main)
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
        TextField("name", text: self.$object.person.name)
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
