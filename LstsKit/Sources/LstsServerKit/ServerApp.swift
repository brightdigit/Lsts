import Vapor
import Fluent
import FluentPostgresDriver

public struct ServerApp {
  internal init(env: Environment) {
    self.env = env
    self.app = Application(env)
  }
  
  let env : Environment
  let app : Application
  

  public static func run () throws {
    var env = try Environment.detect()
    try LoggingSystem.bootstrap(from: &env)
    let server = ServerApp(env: env)
    try server.run()
  }
  
  func run () throws {
    defer { app.shutdown() }
    try self.configure()
    try app.run()
  }
  
  static let defaultPostgreSQLConfig = PostgresConfiguration(hostname: "localhost", username: "lsts")
  
  static func postgreSQLConfig(from environment: Environment.Type) -> PostgresConfiguration {
    guard let url = environment.get("DATABASE_URL") else {
      return defaultPostgreSQLConfig
    }
    return PostgresConfiguration(url: url)!
  }
  
  static func databaseConfiguration (from environment: Environment.Type) -> (DatabaseConfigurationFactory, DatabaseID) {
    return (.postgres(configuration: postgreSQLConfig(from: environment)), .psql)
  }
  
  public func configure() throws {
    
    /// Don't forget to start your database via **docker**:
    /// `docker run  --name fruta-pg -e POSTGRES_HOST_AUTH_METHOD=trust -d -p 5432:5432 postgres -c log_statement=all`
    /// `psql -h localhost -U postgres < ./setup.sql`
    let databaseConfiguration = Self.databaseConfiguration(from: Environment.self)
    
    self.app.databases.use(databaseConfiguration.0, as: databaseConfiguration.1)
    app.migrations.add([
      LstsItemMigration()
    ])
    try app.autoMigrate().wait()
    
    self.app.get("") { request in
      return "Hello World!"
    }
  }
}
