//
//  ContentView.swift
//  Lsts
//
//  Created by Leo Dion on 7/21/21.
//

import SwiftUI
import Combine
import LstsKit

extension LstsItem : Identifiable {
  
}

public class LstsObject : ObservableObject {
  @Published var items : [LstsItem]?
  
  
  public init () {}
  internal init(items: [LstsItem]?) {
    self.items = items
  }
  
  public func beginRemove (itemsAt indexSet: IndexSet) {
    
  }
}

@available(iOS 14.0, *)
public struct ContentView: View {
  @EnvironmentObject var object : LstsObject
  
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
      }.navigationTitle("Lsts").navigationBarItems(trailing: Button("Add", action: {
        
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
