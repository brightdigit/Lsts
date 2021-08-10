import Fluent
import Vapor
import Foundation

struct LstsItemMigration: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    database.schema(LstsItemModel.schema)
      .id()
      .field("title", .string, .required)
      .field("completedAt", .datetime)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema(LstsItemModel.schema).delete()
  }
}
