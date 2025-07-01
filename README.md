# 📡 WebSocket Öğrenme Projesi

Bu proje, iOS'ta WebSocket teknolojisini öğrenmek için hazırlanmış eğitim amaçlı bir uygulamadır. Coinbase Pro API'si kullanılarak gerçek zamanlı kripto para verilerini gösterir.

## 🎯 Proje Amacı

Bu proje **WebSocket teknolojisini öğrenmek** isteyen iOS geliştiriciler için hazırlanmıştır. İki farklı WebSocket implementasyonu içerir:

1. **Native iOS WebSocket** - Apple'ın yerli URLSessionWebSocketTask
2. **Starscream Kütüphanesi** - Gelişmiş üçüncü parti WebSocket kütüphanesi

## 📱 Uygulama Özellikleri

- **Gerçek zamanlı kripto fiyatları** (Bitcoin, Ethereum, vb.)
- **Anlık fiyat değişimleri** ve yüzde hesaplamaları
- **Order Book** (Alış/Satış emirleri)
- **İşlem Geçmişi** (Son gerçekleşen alım/satımlar)
- **Otomatik yeniden bağlanma** (Starscream versiyonunda)


## 📚 WebSocket Nedir?

WebSocket, web uygulamaları ile sunucu arasında **çift yönlü, gerçek zamanlı** iletişim sağlayan bir protokoldür.

### Geleneksel HTTP vs WebSocket

```
📄 HTTP (Request-Response):
Client ➜ Request ➜ Server
Client ⬅ Response ⬅ Server

🔄 WebSocket (Bidirectional):
Client ↔ Persistent Connection ↔ Server
```

### WebSocket Avantajları
- **Düşük gecikme** - Bağlantı sürekli açık
- **Az bandwidth** - Header overhead yok
- **Gerçek zamanlı** - Sunucu istediği zaman veri gönderebilir
- **Çift yönlü** - Her iki taraf da mesaj başlatabilir

## 🏗️ Kod Yapısı

### Native iOS WebSocket Implementation

```swift
// Bağlantı kurma
webSocketTask = urlSession.webSocketTask(with: url)
webSocketTask?.resume()

// Mesaj gönderme
let message = URLSessionWebSocketTask.Message.string(jsonString)
webSocketTask?.send(message) { error in
    // Hata kontrolü
}

// Mesaj dinleme
webSocketTask?.receive { result in
    switch result {
    case .success(let message):
        // Gelen mesajı işle
    case .failure(let error):
        // Hata yönetimi
    }
}
```

### Starscream Implementation

```swift
// Starscream kütüphanesi import
import Starscream

// WebSocket oluşturma
socket = WebSocket(request: request)
socket?.delegate = self

// Otomatik ping/pong
socket?.respondToPingWithPong = true

// Bağlantı kurma
socket?.connect()

// Delegate methodları
func didReceive(event: WebSocketEvent, client: WebSocket) {
    switch event {
    case .connected:
        // Bağlantı başarılı
    case .text(let string):
        // Metin mesajı geldi
    case .error(let error):
        // Hata oluştu
    }
}
```

## 📊 Coinbase Pro WebSocket API

### Bağlantı URL'i
```
wss://ws-feed.exchange.coinbase.com
```

### Abone Olma (Subscription)
```json
{
  "type": "subscribe",
  "channels": [
    {
      "name": "ticker",
      "product_ids": ["BTC-USD"]
    }
  ]
}
```

### Gelen Veri Örneği
```json
{
  "type": "ticker",
  "product_id": "BTC-USD",
  "price": "65432.12",
  "volume_24h": "1234.56",
  "best_bid": "65431.11",
  "best_ask": "65432.13"
}
```

## 🆚 Native vs Starscream Karşılaştırması

| Özellik | Native URLSession | Starscream |
|---------|-------------------|------------|
| **Kurulum** | ✅ Yerleşik | ❓ Harici kütüphane |
| **Otomatik Yeniden Bağlanma** | ❌ Manuel | ✅ Otomatik |
| **Ping/Pong** | ❌ Manuel | ✅ Otomatik |
| **Hata Yönetimi** | ⚠️ Basit | ✅ Gelişmiş |
| **Öğrenme Eğrisi** | ✅ Kolay | ⚠️ Orta |
| **Production Kullanımı** | ⚠️ Dikkatli | ✅ Güvenli |

## 🔍 Öğrenme Alanları

Bu projeden öğrenebileceğiniz konular:

### 1. WebSocket Bağlantı Yönetimi
```swift
func connect() {
    // Bağlantı kurma
}

func disconnect() {
    // Bağlantıyı kapatma
}
```

### 2. JSON Veri İşleme
```swift
// Codable ile JSON parsing
struct TickerData: Codable {
    let price: String
    let productId: String
    // ...
}
```

### 3. SwiftUI ile Reactive Programming
```swift
@ObservableObject
class WebSocketManager {
    @Published var currentPrice: String = "Bekleniyor..."
    // UI otomatik güncellenecek
}
```

### 4. Hata Yönetimi
```swift
switch result {
case .success(let message):
    // Başarılı durum
case .failure(let error):
    // Hata durumu - ne yapmalı?
}
```

### 5. Bağlantı Durumu Takibi
```swift
enum ConnectionStatus {
    case connected
    case disconnected
    case connecting
    case error(String)
}
```

## 🐛 Sık Karşılaşılan Sorunlar

### Bağlantı Kurulmuyor
- İnternet bağlantısını kontrol edin
- URL'nin doğru olduğunu kontrol edin
- Console loglarını inceleyin

### Veri Gelmiyor
- Subscription mesajının gönderildiğini kontrol edin
- JSON formatının doğru olduğunu kontrol edin
- Coinbase API durumunu kontrol edin

### Uygulama Çöküyor
- Try-catch blokları ekleyin
- Nil kontrolü yapın
- Main thread'de UI güncellemesi yapın

## 📝 Çalışma Notları

### WebSocket Yaşam Döngüsü
1. **Connect** - Sunucuya bağlan
2. **Subscribe** - Veri kanallarına abone ol
3. **Listen** - Gelen mesajları dinle
4. **Process** - Verileri işle ve UI'ı güncelle
5. **Handle Errors** - Hataları yönet
6. **Reconnect** - Gerekirse yeniden bağlan
7. **Disconnect** - Bağlantıyı temiz kapat

### JSON Mesaj Tipleri
- **ticker** - Fiyat güncellemeleri
- **l2update** - Order book değişiklikleri
- **match** - Gerçekleşen işlemler
- **heartbeat** - Bağlantı sağlık kontrolü

## 🚀 İleriye Dönük Geliştirmeler

Bu proje üzerinde çalışarak şunları ekleyebilirsiniz:

- [ ] **Grafik gösterimi** - Fiyat grafikleri
- [ ] **Bildirimler** - Fiyat alarmları
- [ ] **Çoklu exchange** - Binance, Kraken vb.
- [ ] **Portfolio takibi** - Coin portföyü
- [ ] **Offline mod** - Bağlantı kesildiğinde veri saklama

## 🎓 Öğrenme Kaynakları

- [Apple WebSocket Documentation](https://developer.apple.com/documentation/foundation/urlsessionwebsockettask)
- [Starscream GitHub](https://github.com/daltoniam/Starscream)
- [Coinbase Pro API Docs](https://docs.pro.coinbase.com/)
