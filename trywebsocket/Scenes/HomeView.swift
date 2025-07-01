//
//  ContentView.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var webSocketManager = WSManagerStarScream()
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header - Connection Status
                ConnectionHeaderView(webSocketManager: webSocketManager)
                
                // Product Selector
                productSelector
                
                // Price Info
                priceInfoSection
                
                // Tab Selection
                tabSelector
                
                // Tab Content
                TabView(selection: $selectedTab) {
                    OrderBookView(orderBook: webSocketManager.orderBook)
                        .tag(0)
                    
                    TradesView(trades: webSocketManager.recentTrades)
                        .tag(1)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("Coinbase Pro Live")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            webSocketManager.connect()
        }
        .onDisappear {
            webSocketManager.disconnect()
        }
    }
    
    private var productSelector: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(webSocketManager.availableProducts, id: \.self) { product in
                    Button(product) {
                        webSocketManager.changeProduct(product)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .background(webSocketManager.selectedProduct == product ? Color.blue.opacity(0.2) : Color.clear)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal)
        }
        .padding(.vertical, 8)
    }
    
    private var priceInfoSection: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(webSocketManager.selectedProduct)
                        .font(.headline)
                        .fontWeight(.bold)
                    
                    Text(webSocketManager.currentPrice)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(webSocketManager.priceChange24h)
                        .font(.subheadline)
                        .foregroundColor(webSocketManager.priceChange24h.hasPrefix("-") ? .red : .green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    HStack {
                        Text("24h Vol:")
                        Text(webSocketManager.volume24h)
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Bid:")
                        Text(webSocketManager.bestBid)
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    
                    HStack {
                        Text("Ask:")
                        Text(webSocketManager.bestAsk)
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
    }
    
    private var tabSelector: some View {
        HStack {
            Button("Order Book") {
                selectedTab = 0
            }
            .fontWeight(selectedTab == 0 ? .bold : .regular)
            .foregroundColor(selectedTab == 0 ? .blue : .secondary)
            
            Spacer()
            
            Button("Recent Trades") {
                selectedTab = 1
            }
            .fontWeight(selectedTab == 1 ? .bold : .regular)
            .foregroundColor(selectedTab == 1 ? .blue : .secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}
