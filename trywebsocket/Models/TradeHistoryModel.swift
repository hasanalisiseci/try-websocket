//
//  TradeHistoryModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import Foundation

struct TradeHistory: Identifiable {
    let id = UUID()
    let price: Double
    let size: Double
    let side: String
    let time: Date
    let tradeId: Int
}
