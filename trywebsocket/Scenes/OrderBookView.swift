//
//  OrderBookView.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

// MARK: - Order Book View
struct OrderBookView: View {
    let orderBook: [OrderBookEntry]
    
    var body: some View {
        VStack {
            HStack {
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
                    ForEach(orderBook) { entry in
                        HStack {
                            Text(String(format: "$%.2f", entry.price))
                                .font(.caption)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Text(String(format: "%.4f", entry.size))
                                .font(.caption)
                            
                            Spacer()
                            
                            Text(entry.side.uppercased())
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(entry.side == "buy" ? .green : .red)
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 4)
                        .background(entry.side == "buy" ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
                    }
                }
            }
        }
    }
}
