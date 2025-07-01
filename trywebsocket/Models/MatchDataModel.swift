//
//  MatchDataModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import Foundation

struct MatchData: Codable, Identifiable {
    let id = UUID()
    let type: String
    let tradeId: Int
    let makerOrderId: String
    let takerOrderId: String
    let side: String
    let size: String
    let price: String
    let productId: String
    let time: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case tradeId = "trade_id"
        case makerOrderId = "maker_order_id"
        case takerOrderId = "taker_order_id"
        case side, size, price
        case productId = "product_id"
        case time
    }
}
