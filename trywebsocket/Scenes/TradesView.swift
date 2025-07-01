//
//  TradesView.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

// MARK: - Trades View
struct TradesView: View {
    let trades: [TradeHistory]
    
    var body: some View {
        VStack {
            HStack {
                Text("Time")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("Price")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("Size")
                    .font(.caption)
                    .fontWeight(.bold)
                Spacer()
                Text("Side")
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(.systemGray5))
            
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(trades) { trade in
                        HStack {
                            Text(timeFormatter.string(from: trade.time))
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(String(format: "$%.2f", trade.price))
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(String(format: "%.4f", trade.size))
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(trade.side.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(trade.side == "buy" ? .green : .red)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(trade.side == "buy" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    }
                }
            }
        }
    }
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter
    }()
}
