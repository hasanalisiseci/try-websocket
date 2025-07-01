//
//  ConnectionStatusModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

enum ConnectionStatus: Equatable {
    case connected
    case disconnected
    case connecting
    case reconnecting
    case error(String)
    
    var displayText: String {
        switch self {
        case .connected:
            return "🟢 Coinbase Pro'ya Bağlandı"
        case .disconnected:
            return "🔴 Bağlantı Kesildi"
        case .connecting:
            return "🟡 Bağlanıyor..."
        case .reconnecting:
            return "🔄 Yeniden Bağlanıyor..."
        case .error(let message):
            return "❌ Hata: \(message)"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .red
        case .connecting, .reconnecting: return .orange
        case .error: return .red
        }
    }
}
