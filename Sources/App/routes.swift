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
            BridgeFetch.fetchTweets()
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.post("force-update-bridges") { req async -> HTTPStatus in
        print("fetch tweet call")
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.fetchTweets()
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.get("start-stream") { req async -> HTTPStatus in
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.streamTweets()
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.post("start-stream") { req async -> HTTPStatus in
        if Secrets.authorizeToken(token: req.headers.bearerAuthorization?.token) {
            BridgeFetch.streamTweets()
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    try app.register(collection: BridgeController())
}
