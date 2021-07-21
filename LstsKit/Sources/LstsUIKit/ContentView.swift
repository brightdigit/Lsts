//
//  ContentView.swift
//  Lsts
//
//  Created by Leo Dion on 7/21/21.
//

import SwiftUI
import Combine
import LstsKit


extension JSONDecoder {
  func decode<SuccessType : Decodable>(
    _ type: SuccessType.Type,
    data: Data?,
    fromResponse response: HTTPURLResponse?,
    withError error: Error?,
    withResponse: ((HTTPURLResponse) -> Result<SuccessType, Error>)? = nil,
    otherwise: @autoclosure () -> Error = LstsError.empty
  ) -> Result<SuccessType, Error> {
    if let error = error {
      return .failure(error)
    } else if let data = data {
      return Result { try self.decode(type, from: data)}
    } else if let withResponse = withResponse, let response = response {
      return withResponse(response)
    } else {
      return .failure(otherwise())
    }
  }
}

extension LstsItem : Identifiable {
  
}

public struct LstsService {
  let session : URLSession
  
  func list (_ completion: @escaping ((Result<[LstsItem], Error>) -> Void)) {
    let url = URL(string: "http://localhost:8080/items")!
//    session.dataTask(with: url) { data, response, error in
//      <#code#>
//    }
//    session.dataTask(with: )
  }
}
public class LstsObject : ObservableObject {
  @Published var itemsToRemove = [LstsItem]()
  @Published var newTitle = ""
  
  @Published var items : [LstsItem]?
  
  public init () {
    
  }
  internal init(items: [LstsItem]?) {
    self.items = items
  }
  
  public func beginRemove (itemsAt indexSet: IndexSet) {
    if let items = self.items {
      itemsToRemove.append(contentsOf: indexSet.map{ items[$0] })
    }
  }
  
  public func beginAdd () {
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
        if let items = self.object.items {
          List{
            ForEach(items) { item in
            Text(item.title)
            }.onDelete(perform: self.onDelete(at:))
          }
        }
      }
      .sheet(isPresented: self.$isEditing, onDismiss: {
        
      }, content: {
        TextField("Title", text: self.$object.newTitle)
      })
      .navigationTitle("Lsts").navigationBarItems(trailing: Button("Add", action: {
        self.object.beginAdd()
      }))
    }
  }
  
  func onDelete(at indexSet: IndexSet) {
    self.object.beginRemove(itemsAt: indexSet)
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
    }
}
