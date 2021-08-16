import Vapor

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
  
  public func configure() throws {
    try self.app.register(collection: HelloWorldController())
  }
}
