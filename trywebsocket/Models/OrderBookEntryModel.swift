//
//  OrderBookEntryModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import Foundation

struct OrderBookEntry: Identifiable, Equatable {
    let id = UUID()
    let price: Double
    let size: Double
    let side: String // "buy" or "sell"
}
