//
//  WebSocketManager.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

class CoinbaseWebSocketManager: NSObject, ObservableObject {
    @Published var currentPrice: String = "Bekleniyor..."
    @Published var priceChange24h: String = "0.00%"
    @Published var volume24h: String = "0"
    @Published var bestBid: String = "0"
    @Published var bestAsk: String = "0"
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var orderBook: [OrderBookEntry] = []
    @Published var recentTrades: [TradeHistory] = []
    @Published var selectedProduct: String = "BTC-USD"
    
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession = URLSession(configuration: .default)
    private var orderBookBids: [String: Double] = [:]
    private var orderBookAsks: [String: Double] = [:]
    
    let availableProducts = ["BTC-USD", "ETH-USD", "ADA-USD", "SOL-USD", "DOGE-USD"]

    
    func connect() {
        disconnect()
        
        // Coinbase Pro WebSocket URL'i
        guard let url = URL(string: "wss://ws-feed.exchange.coinbase.com") else {
            connectionStatus = .error("Geçersiz URL")
            return
        }
        
        connectionStatus = .connecting
        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        
        // Subscription mesajı gönder
        subscribeToFeeds()
        listen()
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        connectionStatus = .disconnected
    }
    
    func changeProduct(_ newProduct: String) {
        selectedProduct = newProduct
        currentPrice = "Bekleniyor..."
        orderBook.removeAll()
        recentTrades.removeAll()
        orderBookBids.removeAll()
        orderBookAsks.removeAll()
        
        if connectionStatus == .connected {
            subscribeToFeeds()
        }
    }
    
    private func subscribeToFeeds() {
        // Önce mevcut subscription'ları iptal et
        let unsubscribeMessage: [String: Any] = [
            "type": "unsubscribe",
            "channels": [
                [
                    "name": "ticker",
                    "product_ids": availableProducts
                ],
                [
                    "name": "level2",
                    "product_ids": availableProducts
                ],
                [
                    "name": "matches",
                    "product_ids": availableProducts
                ]
            ]
        ]
        
        sendMessage(unsubscribeMessage)
        
        // Yeni product için subscribe ol
        let subscribeMessage: [String: Any] = [
            "type": "subscribe",
            "channels": [
                [
                    "name": "ticker",
                    "product_ids": [selectedProduct]
                ],
                [
                    "name": "level2",
                    "product_ids": [selectedProduct]
                ],
                [
                    "name": "matches",
                    "product_ids": [selectedProduct]
                ]
            ]
        ]
        
        sendMessage(subscribeMessage)
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard let webSocketTask = webSocketTask,
              let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else {
            return
        }
        
        let wsMessage = URLSessionWebSocketTask.Message.string(jsonString)
        webSocketTask.send(wsMessage) { error in
            if let error = error {
                DispatchQueue.main.async {
                    self.connectionStatus = .error("Mesaj gönderme hatası: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func listen() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                DispatchQueue.main.async {
                    self?.connectionStatus = .connected
                    
                    switch message {
                    case .string(let text):
                        self?.processMessage(text)
                    case .data(let data):
                        if let text = String(data: data, encoding: .utf8) {
                            self?.processMessage(text)
                        }
                    @unknown default:
                        break
                    }
                }
                
                self?.listen() // Bir sonraki mesajı dinle
                
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.connectionStatus = .error(error.localizedDescription)
                }
            }
        }
    }
    
    private func processMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        // JSON'u parse et ve type'a göre işle
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let type = json["type"] as? String {
            
            switch type {
            case "ticker":
                processTicker(data)
            case "l2update":
                processLevel2Update(data)
            case "match":
                processMatch(data)
            case "subscriptions":
                print("Subscription confirmed for \(selectedProduct)")
            default:
                break
            }
        }
    }
    
    private func processTicker(_ data: Data) {
        if let ticker = try? JSONDecoder().decode(TickerData.self, from: data),
           ticker.productId == selectedProduct {
            
            let priceDouble = Double(ticker.price) ?? 0
            let openDouble = Double(ticker.open24h) ?? 0
            let change = ((priceDouble - openDouble) / openDouble) * 100
            
            self.currentPrice = formatPrice(ticker.price)
            self.priceChange24h = String(format: "%.2f%%", change)
            self.volume24h = formatVolume(ticker.volume24h)
            self.bestBid = formatPrice(ticker.bestBid)
            self.bestAsk = formatPrice(ticker.bestAsk)
        }
    }
    
    private func processLevel2Update(_ data: Data) {
        if let level2 = try? JSONDecoder().decode(Level2Data.self, from: data),
           level2.productId == selectedProduct {
            
            for change in level2.changes {
                guard change.count >= 3,
                      let price = Double(change[1]),
                      let size = Double(change[2]) else { continue }
                
                let side = change[0]
                let priceKey = change[1]
                
                if side == "buy" {
                    if size == 0 {
                        orderBookBids.removeValue(forKey: priceKey)
                    } else {
                        orderBookBids[priceKey] = size
                    }
                } else if side == "sell" {
                    if size == 0 {
                        orderBookAsks.removeValue(forKey: priceKey)
                    } else {
                        orderBookAsks[priceKey] = size
                    }
                }
            }
            
            updateOrderBook()
        }
    }
    
    private func processMatch(_ data: Data) {
        if let match = try? JSONDecoder().decode(MatchData.self, from: data),
           match.productId == selectedProduct {
            
            let trade = TradeHistory(
                price: Double(match.price) ?? 0,
                size: Double(match.size) ?? 0,
                side: match.side,
                time: ISO8601DateFormatter().date(from: match.time) ?? Date(),
                tradeId: match.tradeId
            )
            
            recentTrades.insert(trade, at: 0)
            if recentTrades.count > 50 {
                recentTrades = Array(recentTrades.prefix(50))
            }
        }
    }
    
    private func updateOrderBook() {
        var newOrderBook: [OrderBookEntry] = []
        
        // En iyi bid'ler (en yüksek fiyattan başlayarak)
        let sortedBids = orderBookBids.sorted { Double($0.key) ?? 0 > Double($1.key) ?? 0 }
        for (priceStr, size) in sortedBids.prefix(10) {
            if let price = Double(priceStr) {
                newOrderBook.append(OrderBookEntry(price: price, size: size, side: "buy"))
            }
        }
        
        // En iyi ask'ler (en düşük fiyattan başlayarak)
        let sortedAsks = orderBookAsks.sorted { Double($0.key) ?? 0 < Double($1.key) ?? 0 }
        for (priceStr, size) in sortedAsks.prefix(10) {
            if let price = Double(priceStr) {
                newOrderBook.append(OrderBookEntry(price: price, size: size, side: "sell"))
            }
        }
        
        self.orderBook = newOrderBook
    }
    
    private func formatPrice(_ priceStr: String) -> String {
        if let price = Double(priceStr) {
            return String(format: "$%.2f", price)
        }
        return priceStr
    }
    
    private func formatVolume(_ volumeStr: String) -> String {
        if let volume = Double(volumeStr) {
            if volume > 1_000_000 {
                return String(format: "%.1fM", volume / 1_000_000)
            } else if volume > 1_000 {
                return String(format: "%.1fK", volume / 1_000)
            }
            return String(format: "%.0f", volume)
        }
        return volumeStr
    }
}
