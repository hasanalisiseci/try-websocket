//
//  WSManagerStarScream.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import Starscream
import SwiftUI

class WSManagerStarScream: NSObject, ObservableObject, WebSocketDelegate {
    
    @Published var currentPrice: String = "Bekleniyor..."
    @Published var priceChange24h: String = "0.00%"
    @Published var volume24h: String = "0"
    @Published var bestBid: String = "0"
    @Published var bestAsk: String = "0"
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var orderBook: [OrderBookEntry] = []
    @Published var recentTrades: [TradeHistory] = []
    @Published var selectedProduct: String = "BTC-USD"
    @Published var connectionQuality: ConnectionQuality = .unknown
    @Published var lastHeartbeat: Date?
    
    private var socket: WebSocket?
    private var orderBookBids: [String: Double] = [:]
    private var orderBookAsks: [String: Double] = [:]
    private var reconnectTimer: Timer?
    private var reconnectAttempts = 0
    private let maxReconnectAttempts = 10
    private var pingTimer: Timer?
    
    let availableProducts = ["BTC-USD", "ETH-USD", "ADA-USD", "SOL-USD", "DOGE-USD", "LTC-USD", "LINK-USD", "DOT-USD"]
    
    // MARK: - Connection Management
    func connect() {
        disconnect() // Önceki bağlantıyı temizle
        
        guard let url = URL(string: "wss://ws-feed.exchange.coinbase.com") else {
            connectionStatus = .error("Geçersiz URL")
            return
        }
        
        connectionStatus = .connecting
        reconnectAttempts = 0
        
        // Starscream WebSocket yapılandırması
        var request = URLRequest(url: url)
        request.timeoutInterval = 15
        request.setValue("ios-starscream-app", forHTTPHeaderField: "User-Agent")
        request.setValue("WebSocket", forHTTPHeaderField: "Connection")
        request.setValue("13", forHTTPHeaderField: "Sec-WebSocket-Version")
        
        socket = WebSocket(request: request)
        socket?.delegate = self
        
        // Starscream gelişmiş ayarları
        socket?.respondToPingWithPong = true    // Otomatik pong response
        
        socket?.connect()
        
        // Bağlantı timeout kontrolü
        DispatchQueue.main.asyncAfter(deadline: .now() + 20) {
            if self.connectionStatus == .connecting {
                self.connectionStatus = .error("Bağlantı timeout (20s)")
                self.setupReconnection()
            }
        }
    }
    
    func disconnect() {
        // Timers'ları temizle
        reconnectTimer?.invalidate()
        reconnectTimer = nil
        pingTimer?.invalidate()
        pingTimer = nil
        
        // Socket'i kapat
        socket?.disconnect()
        socket = nil
        connectionStatus = .disconnected
        reconnectAttempts = 0
        connectionQuality = .unknown
        lastHeartbeat = nil
    }
    
    func changeProduct(_ newProduct: String) {
        selectedProduct = newProduct
        
        // UI'ı temizle
        currentPrice = "Bekleniyor..."
        priceChange24h = "0.00%"
        volume24h = "0"
        bestBid = "0"
        bestAsk = "0"
        orderBook.removeAll()
        recentTrades.removeAll()
        orderBookBids.removeAll()
        orderBookAsks.removeAll()
        
        // Yeni product için subscription yap
        if connectionStatus == .connected {
            subscribeToFeeds()
        }
    }
    
    // MARK: - Subscription Management
    private func subscribeToFeeds() {
        // Önce tüm subscriptions'ları iptal et
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
                ],
                [
                    "name": "heartbeat",
                    "product_ids": availableProducts
                ]
            ]
        ]
        
        sendMessage(unsubscribeMessage)
        
        // Sadece seçili product için subscribe ol
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
                ],
                [
                    "name": "heartbeat",
                    "product_ids": [selectedProduct]
                ]
            ]
        ]
        
        sendMessage(subscribeMessage)
        print("🔔 Subscribed to feeds for \(selectedProduct)")
    }
    
    private func sendMessage(_ message: [String: Any]) {
        guard connectionStatus == .connected else {
            print("❌ Socket not connected, cannot send message")
            return
        }
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message, options: []),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            print("❌ Failed to serialize message")
            return
        }
        
        socket?.write(string: jsonString)
        print("📤 Sent: \(jsonString)")
    }
    
    // MARK: - Reconnection Logic
    private func setupReconnection() {
        guard reconnectAttempts < maxReconnectAttempts else {
            connectionStatus = .error("Maksimum yeniden bağlanma denemesi aşıldı (\(maxReconnectAttempts))")
            return
        }
        
        reconnectAttempts += 1
        connectionStatus = .reconnecting
        
        // Exponential backoff: 2^attempt seconds, max 60s
        let delay = min(pow(2.0, Double(reconnectAttempts)), 60.0)
        
        print("🔄 Reconnection attempt \(reconnectAttempts)/\(maxReconnectAttempts) in \(delay)s")
        
        reconnectTimer?.invalidate()
        reconnectTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { _ in
            print("🔄 Attempting reconnection...")
            self.connect()
        }
    }
    
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            self.sendPing()
        }
    }
    
    private func sendPing() {
        guard connectionStatus == .connected else { return }
        
        let pingTime = Date()
        socket?.write(ping: Data()) { [weak self] in
            let latency = Date().timeIntervalSince(pingTime) * 1000 // ms
            DispatchQueue.main.async {
                self?.updateConnectionQuality(latency: latency)
            }
        }
    }
    
    private func updateConnectionQuality(latency: Double) {
        switch latency {
        case 0..<50:
            connectionQuality = .excellent
        case 50..<200:
            connectionQuality = .good
        case 200..<500:
            connectionQuality = .fair
        default:
            connectionQuality = .poor
        }
    }
    
    // MARK: - WebSocketDelegate Methods
    func didReceive(event: Starscream.WebSocketEvent, client: any Starscream.WebSocketClient) {        DispatchQueue.main.async {
            switch event {
            case .connected(let headers):
                self.connectionStatus = .connected
                self.reconnectAttempts = 0
                self.reconnectTimer?.invalidate()
                
                print("🟢 Connected to Coinbase Pro WebSocket")
                print("📋 Headers: \(headers)")
                
                // Subscription başlat
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.subscribeToFeeds()
                }
                
                // Ping timer başlat
                self.startPingTimer()
                
            case .disconnected(let reason, let code):
                print("🔴 Disconnected: \(reason), Code: \(code)")
                self.connectionStatus = .disconnected
                self.pingTimer?.invalidate()
                
                // Normal kapanma değilse yeniden bağlan
                if code != 1000 && code != 1001 {
                    self.setupReconnection()
                }
                
            case .text(let text):
                self.processMessage(text)
                
            case .binary(let data):
                if let text = String(data: data, encoding: .utf8) {
                    self.processMessage(text)
                }
                
            case .ping(let data):
                print("📡 Ping received: \(data?.count ?? 0) bytes")
                
            case .pong(let data):
                print("📡 Pong received: \(data?.count ?? 0) bytes")
                
            case .viabilityChanged(let isViable):
                if isViable {
                    print("🔗 Network connection restored")
                } else {
                    print("🔗 Network connection lost")
                }
                
            case .reconnectSuggested(let shouldReconnect):
                if shouldReconnect {
                    print("🔄 Server suggested reconnection")
                    self.setupReconnection()
                }
                
            case .cancelled:
                print("❌ Connection cancelled")
                self.connectionStatus = .disconnected
                
            case .error(let error):
                let errorMessage = error?.localizedDescription ?? "Bilinmeyen WebSocket hatası"
                print("❌ WebSocket error: \(errorMessage)")
                self.connectionStatus = .error(errorMessage)
                self.setupReconnection()
                
            case .peerClosed:
                print("🔌 Peer closed connection")
                self.setupReconnection()
                
            @unknown default:
                print("❓ Unknown WebSocket event")
            }
        }
    }
    
    // MARK: - Message Processing
    private func processMessage(_ message: String) {
        guard let data = message.data(using: .utf8) else { return }
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let type = json["type"] as? String {
            
            switch type {
            case "ticker":
                processTicker(data)
            case "l2update":
                processLevel2Update(data)
            case "match":
                processMatch(data)
            case "heartbeat":
                processHeartbeat(json)
            case "subscriptions":
                processSubscriptionConfirmation(json)
            case "error":
                processError(json)
            default:
                print("🤷‍♂️ Unknown message type: \(type)")
            }
        }
    }
    
    private func processTicker(_ data: Data) {
        if let ticker = try? JSONDecoder().decode(TickerData.self, from: data),
           ticker.productId == selectedProduct {
            
            let priceDouble = Double(ticker.price) ?? 0
            let openDouble = Double(ticker.open24h) ?? 0
            let change = openDouble > 0 ? ((priceDouble - openDouble) / openDouble) * 100 : 0
            
            self.currentPrice = formatPrice(ticker.price)
            self.priceChange24h = String(format: "%+.2f%%", change)
            self.volume24h = formatVolume(ticker.volume24h)
            self.bestBid = formatPrice(ticker.bestBid)
            self.bestAsk = formatPrice(ticker.bestAsk)
            
            print("💰 Price update: \(selectedProduct) = \(currentPrice)")
        }
    }
    
    private func processLevel2Update(_ data: Data) {
        if let level2 = try? JSONDecoder().decode(Level2Data.self, from: data),
           level2.productId == selectedProduct {
            
            for change in level2.changes {
                guard change.count >= 3,
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
            if recentTrades.count > 100 {
                recentTrades = Array(recentTrades.prefix(100))
            }
            
            print("🔄 New trade: \(match.side) \(match.size) @ \(formatPrice(match.price))")
        }
    }
    
    private func processHeartbeat(_ json: [String: Any]) {
        lastHeartbeat = Date()
        if let productId = json["product_id"] as? String,
           productId == selectedProduct {
            print("💓 Heartbeat for \(productId)")
        }
    }
    
    private func processSubscriptionConfirmation(_ json: [String: Any]) {
        if let channels = json["channels"] as? [[String: Any]] {
            let channelInfo = channels.compactMap { channel -> String? in
                if let name = channel["name"] as? String,
                   let productIds = channel["product_ids"] as? [String] {
                    return "\(name): \(productIds.joined(separator: ", "))"
                }
                return nil
            }
            print("✅ Subscription confirmed: \(channelInfo.joined(separator: "; "))")
        }
    }
    
    private func processError(_ json: [String: Any]) {
        if let message = json["message"] as? String {
            print("❌ Coinbase error: \(message)")

            if message.contains("Failed to subscribe") {
                // Sadece subscription hatası
                // Bağlantı durumunu bozma ama kullanıcıyı uyar
                // Belki bir @Published var subscriptionErrorMessage: String? tanımlayabilirsin
            } else {
                // Genel bir hata gibi davran
                connectionStatus = .error("Coinbase error: \(message)")
            }
        }
    }
    
    // MARK: - Order Book Management
    private func updateOrderBook() {
        var newOrderBook: [OrderBookEntry] = []
        
        // En iyi bid'ler (yüksekten düşüğe)
        let sortedBids = orderBookBids.sorted { Double($0.key) ?? 0 > Double($1.key) ?? 0 }
        for (priceStr, size) in sortedBids.prefix(15) {
            if let price = Double(priceStr) {
                newOrderBook.append(OrderBookEntry(price: price, size: size, side: "buy"))
            }
        }
        
        // En iyi ask'ler (düşükten yükseğe)
        let sortedAsks = orderBookAsks.sorted { Double($0.key) ?? 0 < Double($1.key) ?? 0 }
        for (priceStr, size) in sortedAsks.prefix(15) {
            if let price = Double(priceStr) {
                newOrderBook.append(OrderBookEntry(price: price, size: size, side: "sell"))
            }
        }
        
        self.orderBook = newOrderBook
    }
    
    // MARK: - Formatting Helpers
    private func formatPrice(_ priceStr: String) -> String {
        if let price = Double(priceStr) {
            return String(format: "$%.2f", price)
        }
        return priceStr
    }
    
    private func formatVolume(_ volumeStr: String) -> String {
        if let volume = Double(volumeStr) {
            if volume > 1_000_000_000 {
                return String(format: "%.1fB", volume / 1_000_000_000)
            } else if volume > 1_000_000 {
                return String(format: "%.1fM", volume / 1_000_000)
            } else if volume > 1_000 {
                return String(format: "%.1fK", volume / 1_000)
            }
            return String(format: "%.0f", volume)
        }
        return volumeStr
    }
}

// MARK: - SwiftUI Views için Extension
extension WSManagerStarScream {
    var isConnected: Bool {
        if case .connected = connectionStatus {
            return true
        }
        return false
    }
    
    var connectionStatusEmoji: String {
        switch connectionStatus {
        case .connected: return "🟢"
        case .connecting: return "🟡"
        case .reconnecting: return "🔄"
        case .disconnected: return "🔴"
        case .error: return "❌"
        }
    }
}
