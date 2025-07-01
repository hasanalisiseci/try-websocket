//
//  ConnectionHeaderView.swift
//  trywebsocket
//
//  Created by Hasan Ali Şişeci on 1.07.2025.
//

import SwiftUI

struct ConnectionHeaderView: View {
    @StateObject var webSocketManager: WSManagerStarScream
    
    var body: some View {
        HStack {
            Text(webSocketManager.connectionStatus.displayText)
                .font(.caption)
                .foregroundColor(webSocketManager.connectionStatus.color)
            
            Spacer()
            
            Button(webSocketManager.connectionStatus == .connected ? "Disconnect" : "Connect") {
                if webSocketManager.connectionStatus == .connected {
                    webSocketManager.disconnect()
                } else {
                    webSocketManager.connect()
                }
            }
            .font(.caption)
            .buttonStyle(.bordered)
            .controlSize(.mini)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
    }
}
