//
//  ChatMessageModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import Foundation

// MARK: - Data Models
struct TickerData: Codable, Identifiable {
    let id = UUID()
    let type: String
    let productId: String
    let price: String
    let open24h: String
    let volume24h: String
    let low24h: String
    let high24h: String
    let volume30d: String
    let bestBid: String
    let bestAsk: String
    let side: String
    let time: String
    let tradeId: Int
    let lastSize: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case productId = "product_id"
        case price
        case open24h = "open_24h"
        case volume24h = "volume_24h"
        case low24h = "low_24h"
        case high24h = "high_24h"
        case volume30d = "volume_30d"
        case bestBid = "best_bid"
        case bestAsk = "best_ask"
        case side
        case time
        case tradeId = "trade_id"
        case lastSize = "last_size"
    }
}
