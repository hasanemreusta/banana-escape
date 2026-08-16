# Banana Escape — Yol Haritası

Son güncelleme: 2026-08-16

---

## P0 — Play Store yayın blokajı ✅ TAMAMLANDI

Google Play, 31 Ağustos 2026'dan itibaren hedef API düzeyi son Android
sürümünden 1 yıldan eski olan uygulamalara güncelleme yayınlanmasına izin
vermiyordu. Uygulama Android 15'i (API 35) hedefliyordu.

**Doğrulanmış sonuç** — `apkanalyzer` ile release APK manifest'inden okundu:

```
android:targetSdkVersion="36"
android:minSdkVersion="24"
android:versionCode="8"  android:versionName="1.1.0"
compileSdkVersionCodename="16"  platformBuildVersionCode="36"
android:enableOnBackInvokedCallback="true"
android:screenOrientation="1"          (portre)
```

Yapılan işler:

| Bileşen | Önce | Sonra |
|---|---|---|
| Flutter | 3.24.5 (Kas 2024) | 3.47.0 |
| Dart | 3.5.4 | 3.13.0 |
| flame | 1.19.0 | 1.38.x |
| audioplayers | 5.2.1 | 6.8.x |
| flutter_lints | 4.0.0 | 6.0.0 |
| Android Gradle Plugin | 8.4.2 | 9.1.0 |
| Gradle | 8.7 | 9.3.1 |
| Kotlin Gradle Plugin | 1.9.24 | 2.4.0 |
| compileSdk / targetSdk | 35 | **36** |
| minSdk | 21 | 24 |
| NDK | 26.1 (kurulu değildi) | 28.2.13676358 |

Kod tarafındaki kırılmalar:

- `ThemeData.cardTheme` artık `CardThemeData` bekliyor (tek gerçek derleme hatası)
- `Color.withOpacity` deprecate oldu — 13 dosyada 143 çağrı `withValues(alpha:)`
  olarak dönüştürüldü
- **flame 1.19 → 1.38 sıçraması hiçbir API değişikliği gerektirmedi**

Android 16 davranış değişiklikleri:

- Edge-to-edge zorunlu hale geldi → `SystemUiMode.edgeToEdge` + şeffaf sistem
  çubukları
- Yönelim kilidi **hiç yoktu**, oyun yatayda da açılıyordu → hem `SystemChrome`
  hem manifest üzerinden portre kilidi
- Predictive back → `android:enableOnBackInvokedCallback="true"`

### Yol boyunca çıkan iki tuzak

**1. Built-in Kotlin geçişi şu an mümkün değil.** Flutter, bağımsız Kotlin
Gradle Plugin'in gelecekte kırılacağı uyarısını veriyor ve built-in Kotlin'e
geçmeyi öneriyor. Ancak AGP 9.1'in gömülü Kotlin'i **2.2.10**, Flutter'ın
dayattığı minimum ise **2.2.20**. İki gereksinim uyuşmadığı için bağımsız
eklenti (2.4.0) bilinçli olarak korundu. Gerekçe `android/settings.gradle`
içinde yorum olarak duruyor. AGP daha yeni bir Kotlin ile geldiğinde
tekrar denenmeli.

**2. `cmdline-tools` eksikti ve release build'i düşürüyordu.** Hata mesajı
"failed to strip debug symbols from native libraries" diyordu ve yanıltıcıydı:
soyma işlemi aslında **başarılıydı**, ayrılmış semboller AAB içinde
`BUNDLE-METADATA/com.android.tools.build.debugsymbols/` altında duruyordu.
Flutter bunu `apkanalyzer` ile doğruluyor, o da `cmdline-tools` içinde geliyor —
bileşen kurulu olmadığı için doğrulama çalışamayıp "başarısız" varsayıyordu.
cmdline-tools 22.0 kuruldu, sorun çözüldü.

### Play Console'a yükleme öncesi kalanlar

- [ ] Gerçek cihazda duman testi (özellikle portre kilidi ve edge-to-edge HUD)
- [ ] Internal testing → closed testing → production
- [ ] Gizlilik politikası URL'sinin canlı olduğunu teyit et
- [ ] `minSdk` 24'e çıktı: Android 5.0/5.1/6.0 desteği düştü. Play Console'da
      desteklenen cihaz sayısı azalacak, beklenen bir sonuç.

---

## P1 — Oyun geliştirmeleri ✅ TAMAMLANDI

### Karakter

Öncesinde karakterin tek animasyonu yatay eğilme ve ezilmeydi; koşan bir
karakter gibi durmuyordu.

- Gerçek koşu döngüsü: bacaklar zıt fazda, kollar bacaklara karşı salınıyor,
  gövde adım başına iki kez zıplıyor, gölge adımın tepesinde daralıyor
- Adım temposu oyun hızıyla artıyor (`setSpeedFactor`)
- Dört ifade durumu (`PlayerMood`): `running`, `startled` (yakın kaçış — irileşen
  gözler, açık ağız), `delighted` (toplama — mutlu yay gözler, sırıtış),
  `charged` (mıknatıs — kararlı bakış, gözde kıvılcım)
- Bakış yönü şerit değişimine göre kayıyor — karakter gittiği yere bakıyor
- Sap (peel) eğilmenin bir tık gerisinden savruluyor

### Sahne

Öncesinde arka plan tek katmandı ve tamamen statik bir `Picture`'a cache'lenmişti;
palmiyeler hiç hareket etmiyordu.

- Dört parallax katman, farklı hızlarda: sırt çizgisi (0.035×), palmiyeler
  (0.16×), yol kenarı objeleri (0.62×), yol (1×)
- Sürekli gün/gece döngüsü: öğle → gün batımı → gece → şafak, ~72 saniyede tam
  tur, dört palet arasında kesintisiz geçiş (`SkyPalette`)
- Gökyüzü karardıkça beliren yıldızlar
- Hız çizgileri yalnızca hız eşiği aşılınca görünüyor — sürekli görsel gürültü
  yerine hayatta kalmanın ödülü gibi okunuyor

### Oynanış

- **Combo çarpanı**: pencere içinde art arda toplama çarpanı ×5'e kadar
  büyütüyor, sessiz kalınca sönüyor. HUD'da göstergesi var.

### Ölü kodun canlandırılması

`DailyRewardState` modeli ve depolama katmanı tam yazılmıştı ama **hiçbir ekranda
kullanılmıyordu**. Artık bağlı:

- 7 günlük seri, artan ödül tablosu (40 → 400 coin)
- Takvim günü karşılaştırması, 24 saatlik pencere değil — 23:00'te ve ertesi
  sabah 08:00'de toplamak iki ayrı gün sayılıyor
- Gün atlanırsa seri 1'e dönüyor **ve ödül de o güne göre hesaplanıyor** (ilk
  yazımda buradaki hata yakalandı: seri sıfırlanmadan önce eski yüksek ödül
  veriliyordu)
- Menüde seri göstergeli kart
- 9 test

---

## P2 — Sıradaki

- **Zıplama mekaniği** (yukarı kaydırma). Şu an sadece sol/sağ var, mekanik sığ.
  Çarpışma sistemini ve spawn mantığını da değiştireceği için oynanış testi
  gerektiriyor — bu yüzden 1.1'e alınmadı.
- Kalkan power-up'ı (bir çarpışmayı emer)
- Ödüllü "ikinci şans" akışı — `AdService` soyutlaması hazır ama hâlâ hiçbir
  yerde çağrılmıyor (`MockAdService`)
- WAV → OGG dönüşümü. İki müzik dosyası 705 KB × 2; ~1.4 MB kazanç beklenir.
  Makinede `ffmpeg` kurulu değil, önce o gerekiyor.
- Sprite'a hazır render katmanı (`CharacterRenderer` / `ObstacleRenderer`
  arayüzü) — hazır görsel gelirse tek dosya değişimiyle takılabilsin
- Test kapsamını genişlet: çarpışma bağışlama kuralları, spawn şerit güvenliği,
  profil kalıcılığı
- Built-in Kotlin geçişini tekrar dene (yukarıdaki tuzak 1)

---

## P3 — Görsel asset seçenekleri (opsiyonel)

Meshy AI değerlendirildi, **bloke edici değil**:

- Ücretsiz planı var ancak lisans şartları ticari yayın öncesi doğrulanmalı;
  ücretsiz planlarda üretilen varlıklar genellikle atıf zorunluluğu olan bir
  lisansla gelir.
- Meshy 3D mesh üretir, bu oyun 2D lane-runner. Zincir: 3D model → turntable
  render → PNG kesme → sprite sheet → Flame `SpriteAnimation`.

Karar: 1.1 sonrasına bırakıldı. P2'deki render katmanı bu geçişi ucuzlatmak
içindir. `docs/ASSET_PROMPTS.md` ve `docs/ASSET_EXPORT_SPECS.md` hazır.

---

## P4 — GitHub

- Depo public, mantıksal katmanlara bölünmüş commit geçmişiyle
- `.gitignore` `*.jks` ve `/android/key.properties` içeriyor; her ikisinin de
  `git check-ignore` ile dışlandığı push öncesi teyit edildi — imzalama
  anahtarları ve şifreler depoya girmiyor
- README yenilendi: mimari, oynanış, çarpışma bağışlama sistemi, derleme adımları
