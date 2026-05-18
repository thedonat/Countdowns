# Countdowns

Countdowns, iOS için SwiftUI ile geliştirilmiş bir geri sayım uygulamasıdır. Kullanıcılar yaklaşan etkinliklerini kategori bazlı yönetebilir, takvimde görüntüleyebilir, widget üzerinden takip edebilir ve yerel bildirimlerle hatırlatmalar alabilir.

## Öne Çıkan Özellikler

- Etkinlik oluşturma, düzenleme ve silme
- Kategori bazlı organizasyon (Birthday, Travel, Event, Wedding, Holiday vb.)
- Yaklaşan etkinlikleri ana listede ve kategori ekranlarında görüntüleme
- Takvim görünümü ile gün bazlı etkinlik takibi
- Bildirimler için hatırlatma süresi ayarı (1/2/4/6/12/24 saat)
- Widget desteği (yaklaşan etkinlikler)
- Live Activity güncellemeleri
- Uygulama dili desteği (`en`, `tr`)
- Açık/Koyu/Sistem tema tercihi

## Teknoloji ve Mimari

- `SwiftUI` tabanlı arayüz
- `EventStore` ile durum yönetimi (`ObservableObject`)
- Veri saklama: `UserDefaults` + Widget paylaşımı için `App Group UserDefaults`
- Bildirimler: `UserNotifications`
- Widget: `WidgetKit`
- Yerelleştirme: `LocalizationManager` + `Localizable.strings`

## Proje Yapısı

- `Countdowns/`: Ana iOS uygulaması
- `CountdownsWidget/`: Widget extension
- `Shared/`: Ortak dosyalar (gerekirse)
- `Countdowns.xcodeproj/`: Xcode proje dosyaları

## Başlangıç

### Gereksinimler

- Xcode 15+
- iOS 17+ hedefi (Widget/Live Activity tarafı için önerilir)
- Apple Developer hesabı (cihazda bildirim ve extension testleri için)

### Kurulum

1. Repoyu klonlayın:
   ```bash
   git clone git@github-personal:thedonat/Countdowns.git
   cd Countdowns
   ```
2. Projeyi açın:
   ```bash
   open Countdowns.xcodeproj
   ```
3. Xcode içinde bir development team seçin ve imzalama ayarlarını doğrulayın.
4. Uygulamayı simulator veya fiziksel cihazda çalıştırın.

## Önemli Konfigürasyon Notları

- `EventStore` ve Widget provider içinde kullanılan App Group kimliği şu anda:
  - `group.appgroup.com`
- Gerçek bir dağıtım için bu değeri kendi App Group kimliğiniz ile değiştirmeniz ve hem app hem widget target'larında aynı App Group'u etkinleştirmeniz gerekir.

## Bildirim Davranışı

- Uygulama açılışında bildirim izni istenir.
- Her etkinlik için kullanıcı seçimine göre (varsayılan 4 saat önce) tek seferlik bildirim planlanır.
- Ayarlar ekranından hatırlatma süresi değiştiğinde tüm etkinlik bildirimleri yeniden planlanır.

## Widget Davranışı

- Widget, paylaşılan `UserDefaults` içindeki etkinlikleri okur.
- Geçmişte kalmış etkinliklerden sadece bugüne ait olanlar gösterilir.
- Timeline saatlik olarak yenilenir.

## Yerelleştirme

Aşağıdaki dil dosyaları kullanılır:

- `Countdowns/en.lproj/Localizable.strings`
- `Countdowns/tr.lproj/Localizable.strings`
- `CountdownsWidget/en.lproj/Localizable.strings`
- `CountdownsWidget/tr.lproj/Localizable.strings`

Yeni bir dil eklemek için ilgili target altında yeni `.lproj` klasörü ve `Localizable.strings` dosyası ekleyebilirsiniz.

## Lisans

Bu repoda lisans dosyası bulunmuyor. Gerekirse `LICENSE` dosyası ekleyerek lisans türünü açıkça belirleyin.
