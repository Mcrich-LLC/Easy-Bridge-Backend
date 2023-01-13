import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("force-update-bridges") { req async -> HTTPStatus in
        print("fetch tweets")
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.fetchTweets(db: req.db)
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.post("force-update-bridges") { req async -> HTTPStatus in
        print("fetch tweet call")
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.fetchTweets(db: req.db)
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.get("start-stream") { req async -> HTTPStatus in
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.streamTweets(db: req.db)
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.post("start-stream") { req async -> HTTPStatus in
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.streamTweets(db: req.db)
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.get("bridgesjson") { req async -> String in
        let (data, response) = try! await URLSession.shared.data(from: URL(string: "http://localhost:8080/bridges")!)
        guard let response = response as? HTTPURLResponse else {
            return "{}"
        }
        guard (200 ... 299) ~= response.statusCode else {
            print("❌ Status code is \(response.statusCode)")
            return "{}"
        }
        let array = String(data: data, encoding: .utf8)
        return "{\(array ?? "")}"
    }
    
    try app.register(collection: BridgeController())
}
