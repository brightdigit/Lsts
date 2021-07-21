//
//  ContentView.swift
//  Lsts
//
//  Created by Leo Dion on 7/21/21.
//

import SwiftUI
import Combine
import LstsKit

struct ActivityIndicator: UIViewRepresentable {
    func makeUIView(context _: UIViewRepresentableContext<ActivityIndicator>) -> UIActivityIndicatorView {
        let view = UIActivityIndicatorView()
        view.startAnimating()
        return view
    }

    func updateUIView(_: UIActivityIndicatorView, context _: UIViewRepresentableContext<ActivityIndicator>) {}

    typealias UIViewType = UIActivityIndicatorView
}


extension JSONDecoder {
  func decode<SuccessType : Decodable>(
    _ type: SuccessType.Type,
    data: Data?,
    fromResponse response: URLResponse?,
    withError error: Error?,
    withResponse: ((URLResponse) -> Result<SuccessType, Error>)? = nil,
    otherwise: @autoclosure () -> Error = LstsError.empty
  ) -> Result<SuccessType, Error> {
    let httpResponse = response as? HTTPURLResponse
    let statusCode = httpResponse?.statusCode
    switch (error, statusCode, data, response) {
    case (.some(let error), _, _, _):
      return .failure(error)
    case (.none, .some(200..<300), .some(let data), _):
      return Result { try self.decode(type, from: data)}
    case (.none, .some(let statusCode), .some(let data), .some(let response)):
      if let errorResponse = try? self.decode(HTTPError.Response.self, from: data) {
        return .failure(HTTPError(statusCode: statusCode, response: errorResponse))
      } else if let withResponse = withResponse {
        return withResponse(response)
      } else {
        return .failure(otherwise())
      }
    case (.none, _, .none, .some(let response)):
      if let withResponse = withResponse {
        return withResponse(response)
      } else {
        return .failure(otherwise())
      }
    case (.none, .none, .some(let data), _):
      return Result { try self.decode(type, from: data)}
    case (.none, _, .none, .none):
      return .failure(otherwise())
    case (.none, .some(_), _, .none):
      return .failure(otherwise())
    }
  
//    switch () {
//
//    }
//    if let error = error {
//      return .failure(error)
//    } else if let response = response {
//      if let httpURLResponse = response as? HTTPURLResponse, let data = data {
//        self.decode(HTTPError.Response.self, from: data)
//      }
//    } else if let data = data {
//      return Result { try self.decode(type, from: data)}
//    } else if let response = response {
//      if let withResponse = withResponse {
//        return withResponse(response)
//      } else
//    }
//      return .failure(otherwise())
    
  }
  
  func decoder<SuccessType : Decodable>(
    for type: SuccessType.Type,
    fromResponse: ((URLResponse) -> Result<SuccessType, Error>)? = nil,
    completionHandler: @escaping ((Result<SuccessType, Error>) -> Void)
  ) -> ( (Data?, URLResponse?, Error?) -> Void) {
    return {
      completionHandler(
        self.decode(type, data: $0, fromResponse: $1, withError: $2, withResponse: fromResponse)
      )
    }
  }
}

extension Result {
  var error: Failure? {
    if case let .failure(error) = self {
      return error
    } else {
      return nil
    }
  }
}

extension LstsItem : Identifiable {
  
}

public struct LstsService {
  let session = URLSession.shared
  let decoder = JSONDecoder()
  let encoder = JSONEncoder()
  
  func list (_ completion: @escaping ((Result<[LstsItem], Error>) -> Void)) {
    let url = URL(string: "https://cdae8fbf15cd.ngrok.io/items")!
    session.dataTask(
      with: url,
      completionHandler: decoder.decoder(for: [LstsItem].self, completionHandler: completion)
    ).resume()
  }
  
  func create (_ item: LstsItemRequest, _ completion: @escaping ((Result<LstsItem, Error>) -> Void)) {
    let url = URL(string: "https://cdae8fbf15cd.ngrok.io/items")!
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    let data : Data
    do {
      data = try encoder.encode(item)
    } catch {
      completion(.failure(error))
      return
    }
    urlRequest.httpBody = data
    session.dataTask(with: urlRequest, completionHandler: decoder.decoder(for: LstsItem.self, completionHandler: completion)).resume()
  }
}
public class LstsObject : ObservableObject {
  @Published var itemsToRemove = [LstsItem]()
  @Published var newTitle = ""
  
  @Published var error: Error?
  @Published var items : [LstsItem]?
  
  let service = LstsService()
  
  public init () {
    
  }
  
  internal init(items: [LstsItem]?) {
    self.items = items
  }
  
  public func beginDelete (itemsAt indexSet: IndexSet) {
    if let items = self.items {
      itemsToRemove.append(contentsOf: indexSet.map{ items[$0] })
    }
  }
  
  public func beginCreate () {
    self.service.create(LstsItemRequest(title: newTitle)) { result in
      self.error = result.error
      self.refresh()
    }
  }
  
  public func refresh () {
    self.service.list { result in
      DispatchQueue.main.async {
        switch (result) {
        case .failure(let error):
          self.error = error
        case .success(let items):
          self.items = items
        }
      }
    }
  }
  
}

@available(iOS 14.0, *)
public struct ContentView: View {
  @EnvironmentObject var object : LstsObject
  @State var isEditing = false
  
  public init () {}
  public var body: some View {
    NavigationView{
      Group {
        if let error = self.object.error {
          Text(error.localizedDescription)
        } else if let items = self.object.items {
          List{
            ForEach(items) { item in
            Text(item.title)
            }.onDelete(perform: self.onDelete(at:))
          }
        } else {
          ActivityIndicator()
        }
      }
      .onAppear(perform: {
        self.object.refresh()
      })
      .sheet(isPresented: self.$isEditing, onDismiss: {
        self.object.beginCreate()
      }, content: {
        TextField("Title", text: self.$object.newTitle)
      })
      .navigationTitle("Lsts").navigationBarItems(trailing: Button("Add", action: {
        self.isEditing = true
      }))
    }
  }
  
  func onDelete(at indexSet: IndexSet) {
    self.object.beginDelete(itemsAt: indexSet)
  }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      ContentView().environmentObject(LstsObject(items: [
                                                  LstsItem(title: "Item #1"),
        LstsItem(title: "Item #2"),
        LstsItem(title: "Item #3"),
        LstsItem(title: "Item #4"),
        LstsItem(title: "Item #5"),
        LstsItem(title: "Item #6")
      ]))
      ContentView().environmentObject(LstsObject(items: nil))
    }
}
