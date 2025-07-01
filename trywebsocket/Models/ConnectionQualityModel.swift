//
//  ConnectionQualityModel.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

enum ConnectionQuality {
    case excellent  // < 50ms
    case good      // 50-200ms
    case fair      // 200-500ms
    case poor      // > 500ms
    case unknown
    
    var displayText: String {
        switch self {
        case .excellent: return "🚀 Mükemmel"
        case .good: return "✅ İyi"
        case .fair: return "⚠️ Orta"
        case .poor: return "🐌 Yavaş"
        case .unknown: return "❓ Bilinmiyor"
        }
    }
    
    var color: Color {
        switch self {
        case .excellent: return .green
        case .good: return .blue
        case .fair: return .yellow
        case .poor: return .red
        case .unknown: return .gray
        }
    }
}
