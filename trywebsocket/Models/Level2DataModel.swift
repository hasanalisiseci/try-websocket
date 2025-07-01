//
//  Level2DataModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import Foundation

struct Level2Data: Codable {
    let type: String
    let productId: String
    let changes: [[String]]
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case productId = "product_id"
        case changes, time
    }
}
