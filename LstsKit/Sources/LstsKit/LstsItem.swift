import Foundation

public struct HTTPError : Error, LocalizedError {
  public init(statusCode: Int, response: HTTPError.Response) {
    self.statusCode = statusCode
    self.response = response
  }
  
  let statusCode : Int
  let response : Response
  
  public struct Response : Codable {
    let reason: String
  }
  
  public var errorDescription: String? {
    return "HTTP Error: \(self.statusCode)\n\(self.response.reason)"
  }
}

public enum LstsError : Error {
  case empty
  
}


public struct LstsItem : Codable {
  
  public init(id: UUID? = nil, title: String, completedAt: Date? = nil) {
    self.id = id ?? UUID()
    self.title = title
    self.completedAt = completedAt
  }
  
  public let id : UUID
  public let title : String
  public let completedAt: Date?
}

public struct LstsItemRequest : Codable {
  public init(title: String, completedAt: Date? = nil) {
    self.title = title
    self.completedAt = completedAt
  }
  
  public let title : String
  public let completedAt: Date?
}
