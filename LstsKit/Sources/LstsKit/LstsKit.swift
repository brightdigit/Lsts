import Foundation

public struct LstsItem {
  public init(id: UUID? = nil, title: String, completedAt: Date? = nil) {
    self.id = id ?? UUID()
    self.title = title
    self.completedAt = completedAt
  }
  
  public let id : UUID
  public let title : String
  public let completedAt: Date?
}
