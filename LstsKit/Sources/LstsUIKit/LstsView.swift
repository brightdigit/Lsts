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
  let baseURL = URL(string: "http://localhost:8080")!
  let session = URLSession.shared
  let decoder = JSONDecoder()
  let encoder = JSONEncoder()
  
  func list (_ completion: @escaping ((Result<[LstsItem], Error>) -> Void)) {
    let url = baseURL.appendingPathComponent("items")
    session.dataTask(
      with: url,
      completionHandler: decoder.decoder(for: [LstsItem].self, completionHandler: completion)
    ).resume()
  }
  
  func create (_ item: LstsItemRequest, _ completion: @escaping ((Result<LstsItem, Error>) -> Void)) {
    let url = baseURL.appendingPathComponent("items")
    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
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
  
  func removeItem(withID itemID: UUID, _ completion: @escaping ((Error?) -> Void)) {
    let url = baseURL.appendingPathComponent("items").appendingPathComponent(itemID.uuidString)
    var urlRequest = URLRequest(url: url)
    
    urlRequest.httpMethod = "DELETE"
    
    session.dataTask(with: urlRequest) { data, response, error in
      let resultError : Error?
      if let error = error {
        resultError = error
      } else if let response = response as? HTTPURLResponse {
        if response.statusCode / 100 == 2 {
          resultError = nil
        } else {
          let errorResponse : HTTPError.Response?
          if let data = data {
            errorResponse = try? self.decoder.decode(HTTPError.Response.self, from: data)
          } else {
            errorResponse = nil
          }
          let error : Error
          if let errorResponse = errorResponse {
            error = HTTPError(statusCode: response.statusCode, response: errorResponse)
          } else {
            error = LstsError.empty
          }
          resultError = error
        }
      } else {
        resultError = LstsError.empty
      }
      completion(resultError)
    }.resume()
    
  }
}
public class LstsObject : ObservableObject {
  @Published var itemsToRemove = [LstsItem]()
  @Published var itemToUpdate : LstsItem?
  
  @Published var newTitle = ""
  @Published var isCompleted : Bool = false
  
  @Published var error: Error?
  @Published var items : [LstsItem]?
  
  var refreshTrigger = PassthroughSubject<Void, Never>()
  var deleteTrigger = PassthroughSubject<Void, Never>()
  var cancellables = [AnyCancellable]()
  
  let service = LstsService()
  
  public init () {
    refreshTrigger.sink {
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
    }.store(in: &self.cancellables)
    
    
    let deletingPublisher = self.deleteTrigger.combineLatest(self.$itemsToRemove).map{$0.1}.filter{$0.count > 0}.map { items in
      //print(items)
      return items.map{ item in
        
        Future<Error?, Never> { completed in
          print(item.id)
          self.service.removeItem(withID: item.id) { error in
            completed(.success(error))
          }
        }
      }
    }.filter({ $0.count > 0 })
    .flatMap { publishers in
      Publishers.MergeMany(publishers).collect()
    }.map{
      $0.compactMap{$0}.first
    }
    
    //deletingPublisher.share().map{_ in [LstsItem]()}.assign(to: &self.$itemsToRemove)
    
    deletingPublisher.receive(on: DispatchQueue.main).sink { error in
      self.error = error
      
      self.itemsToRemove = []
      
      self.refreshTrigger.send()
    }.store(in: &self.cancellables)
    
    //deletingPublisher.share().map({_ in }).multicast(subject: self.refreshTrigger).connect().store(in: &self.cancellables)
  }
  
  internal init(items: [LstsItem]?) {
    self.items = items
  }
  
  public func beginDelete (itemsAt indexSet: IndexSet) {
    if let items = self.items {
      itemsToRemove.append(contentsOf: indexSet.map{ items[$0] })
      self.deleteTrigger.send()
    }
  }
  
  public func beginUpdate (item: LstsItem) {
    self.itemToUpdate = item
  }
  
  public func beginCreate () {
    self.service.create(LstsItemRequest(title: newTitle)) { result in
      DispatchQueue.main.async {
        self.error = result.error
      }
      self.refresh()
    }
    DispatchQueue.main.async {
      self.newTitle = ""
    }
  }
  
  public func refresh () {
    refreshTrigger.send()
    
  }
  
}

public struct EditorView : View {
  internal init(existingItem: LstsItem, onSave: @escaping (LstsItem) -> Void) {
    self.id = existingItem.id
    self.originalCompletedAt = existingItem.completedAt
    self.onSave = onSave
    self._title = .init(initialValue:  existingItem.title)
    self._isCompleted = .init(initialValue: existingItem.completedAt != nil)
    
  }
  
  let id : UUID
  let originalCompletedAt: Date?
  @State var title : String
  @State var isCompleted : Bool
  
  var onSave : (LstsItem) -> Void
  
  public var updatedCompletedAt: Date? {
    switch (originalCompletedAt, isCompleted) {
    case (.none, true):
      return Date()
    case (_, false):
      return nil
    case (.some(let date), true):
      return date
    }
  }
  public var body : some View {
    NavigationView{
    Form{
      Section{
        TextField("Title", text: self.$title)
        Toggle("Is Completed", isOn: self.$isCompleted)
      }
      
    }.navigationTitle("New Item").navigationBarTitleDisplayMode(.inline)
    .navigationBarItems( trailing: Button("Save") {
      self.onSave(LstsItem(id: id, title: title, completedAt: self.updatedCompletedAt))
    })
    }
    
  }
}

public struct ModalView : View {
  internal init(title: Binding<String>, isCompleted : Binding<Bool>, isEditing: Binding<Bool>, onSave: @escaping () -> Void) {
    self._title = title
    self._isCompleted = isCompleted
    self._isEditing = isEditing
    self.onSave = onSave
  }
  
  @Binding var title : String
  @Binding var isCompleted : Bool
  @Binding var isEditing : Bool
  
  var onSave : () -> Void
  public var body : some View {
    NavigationView{
    Form{
      Section{
        TextField("Title", text: self.$title)
        Toggle("Is Completed", isOn: self.$isCompleted)
      }
      
    }.navigationTitle("New Item").navigationBarTitleDisplayMode(.inline)
    .navigationBarItems(leading:Button("Cancel") {
      DispatchQueue.main.async {
        self.isEditing = false
        
      }
    } , trailing: Button("Save") {
      self.onSave()
      DispatchQueue.main.async {
        self.isEditing = false
        
      }
    })
    }
    
  }
}

@available(iOS 14.0, *)
public struct LstsView: View {
  @EnvironmentObject var object : LstsObject
  @State var isCreating : Bool
  @State var isEditing : Bool
  
  public init (isCreating: Bool = false) {
    self.isCreating = isCreating
    self.isEditing = false
  }
  public var body: some View {

    NavigationView{
      
      Group {
        if let error = self.object.error {
          Text(error.localizedDescription)
        } else if let items = self.object.items {
          List{
            ForEach(items) { item in
              NavigationLink(item.title, destination: EditorView(existingItem: item, onSave: self.object.beginUpdate), isActive: self.$isEditing)
              
            
            }.onDelete(perform: self.onDelete(at:))
          }
        } else {
          ActivityIndicator()
        }
      }
        
      
      .navigationTitle("Lsts").navigationBarItems(trailing: Button("Add", action: {
        DispatchQueue.main.async {
          self.isCreating = true
          
        }
      }))
    }.sheet(isPresented: self.$isEditing, content: { ModalView(title: self.$object.newTitle, isCompleted: self.$object.isCompleted, isEditing: self.$isCreating, onSave: self.object.beginCreate)
    }).onAppear(perform:
      self.object.refresh
    )
   
      

    
  }
  
  func onDelete(at indexSet: IndexSet) {
    self.object.beginDelete(itemsAt: indexSet)
  }
}

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
      LstsView(isCreating: true).environmentObject(LstsObject(items: [
                                                  LstsItem(title: "Item #1"),
        LstsItem(title: "Item #2"),
        LstsItem(title: "Item #3"),
        LstsItem(title: "Item #4"),
        LstsItem(title: "Item #5"),
        LstsItem(title: "Item #6")
      ]))
      LstsView().environmentObject(LstsObject(items: [
                                                  LstsItem(title: "Item #1"),
        LstsItem(title: "Item #2"),
        LstsItem(title: "Item #3"),
        LstsItem(title: "Item #4"),
        LstsItem(title: "Item #5"),
        LstsItem(title: "Item #6")
      ]))
      LstsView().environmentObject(LstsObject(items: nil))
    }
}
