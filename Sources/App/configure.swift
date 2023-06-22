import VaporCron
import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import FCM

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.databases.use(.postgres(configuration: SQLPostgresConfiguration(
        hostname: Environment.get("DATABASE_HOST") ?? "localhost",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "vapor_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "vapor_password",
        database: Environment.get("DATABASE_NAME") ?? "vapor_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    let corsConfiguration = CORSMiddleware.Configuration(
        allowedOrigin: .all,
        allowedMethods: [.GET, .POST, .PUT, .OPTIONS, .DELETE, .PATCH],
        allowedHeaders: [.accept, .authorization, .contentType, .origin, .xRequestedWith, .userAgent, .accessControlAllowOrigin],
        allowCredentials: true,
        exposedHeaders: [.accessControlAllowOrigin]
    )
    let cors = CORSMiddleware(configuration: corsConfiguration)
    // cors middleware should come before default error middleware using `at: .beginning`
    app.middleware.use(cors, at: .beginning)
    
    app.migrations.add(UpdateStatus())
    if app.environment == .development {
//        try app.autoRevert().wait()
        try app.autoMigrate().wait()
    }
    Utilities.environment = app.environment
    
    // register routes
    try routes(app)
    
    Task {
        if app.environment == .production {
            SystemNotifications.pushStartup()
        }
        FcmManager.shared.configure(app)
        BridgeFetch.fetchTweets(db: app.db)
        BridgeFetch.streamTweets(db: app.db)
    }
}
