//
//  RSS Model.swift
//  
//
//  Created by Morris Richman on 6/20/23.
//

import Foundation

struct RssModel: Codable {
    let items: [RssItem]
}
        
struct RssItem: Codable {
    let title: String
}
