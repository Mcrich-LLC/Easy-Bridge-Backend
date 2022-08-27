import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("update-bridges") { req async -> HTTPStatus in
        //Getting automatically called by IFTTT
        if req.headers.bearerAuthorization?.token == Secrets.editBearerToken {
            BridgeFetch.fetchTweets()
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    app.post("update-bridges") { req async -> HTTPStatus in
        //Getting automatically called by IFTTT
        if req.headers.bearerAuthorization?.token == Secrets.editBearerToken {
            BridgeFetch.fetchTweets()
            return .accepted
        } else {
            return .forbidden
        }
    }
    
    try app.register(collection: BridgeController())
}
