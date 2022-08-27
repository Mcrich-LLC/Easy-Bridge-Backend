import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello") { req async -> String in
        "Hello, world!"
    }
    
    app.get("update-bridges") { req async -> String in
        //Getting automatically called by IFTTT
        BridgeFetch.fetchTweets()
        return "Updating Database"
    }
    
    app.post("update-bridges") { req async -> HTTPStatus in
        BridgeFetch.fetchTweets()
        return .accepted
    }
    
    try app.register(collection: BridgeController())
}
