# Loto Kolon Üretici

Flutter/Android kaynak projesi. Türkçe arayüz, Material 3, SQLite, offline çalışma, geçmiş çekilişlerden sayı havuzu, dengeli kolon üretimi, kolon geçmişi ve geçmiş-veri istatistikleri içerir.

## Resmi kurallar ve veri kaynağı

Uygulamadaki oyun kuralları geliştirme sırasında Milli Piyango Online'ın resmi sayfalarından doğrulanmıştır:
- Çılgın Sayısal Loto: 1–90 arasından 6 ana sayı; Joker/SüperStar ayrı özelliklerdir.
- Süper Loto: 1–60 arasından 6 sayı.
- On Numara: 1–80 arasından 10 sayı; çekilişte 22 sayı çıkar.
- Şans Topu: 1–34 arasından 5 + 1–14 arasından 1 sayı.

Remote adapter yalnızca resmi sonuç sayfalarını okur. Veri kaynağı koddan bağımsız `OfficialDrawService` sınıfındadır.

## Windows'ta kurulum ve APK

Bu çalışma ortamında Flutter SDK bulunmadığı için APK burada derlenmedi. Windows bilgisayarda Flutter kuruluysa:

1. Bu klasörü aç.
2. `setup_and_build.bat` dosyasını çalıştır.
3. Script Flutter platform dosyalarını oluşturur, bağımlılıkları çeker, analyze/test çalıştırır ve release APK üretir.

Beklenen çıktı:
`build\\app\\outputs\\flutter-apk\\app-release.apk`

Script gerçek dosyanın varlığını kontrol eder; build başarısızsa başarı mesajı vermez.

## Doğrulanan resmi sayfalar
- https://www.millipiyangoonline.com/sayisal-loto/kurallar
- https://www.millipiyangoonline.com/super-loto/kurallar
- https://www.millipiyangoonline.com/on-numara/kurallar
- https://www.millipiyangoonline.com/sans-topu/kurallar
