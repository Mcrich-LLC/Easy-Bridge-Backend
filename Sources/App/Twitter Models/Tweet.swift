//
//  Tweet.swift
//  brain-marks
//
//  Created by PRABALJIT WALIA     on 11/04/21.
//

import Foundation

struct Tweet: Codable, Hashable {
    let id: String
    let text: String
    let authorId: String?
}
