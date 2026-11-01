# SiteEksen Tedarikçi

Usta & Hizmet tedarikçilerinin uygulaması (FAZ M9): kayıt ve giriş, hesap ve belgeler, işletmeler (harita, hizmet alanı,
hizmet kalemleri), gelen talepler (maskeli önizleme, kabul), teklif, alıcıyla yazışma, iş ve puanlar, bakiye ve paket.
Web panelindeki `/tedarikci` alanıyla aynı uçları kullanır (`tasks/api-sozlesmesi.md`, marketplace bölümü).

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8888/api/v1          # Android emülatörü
flutter build web --dart-define=API_BASE_URL=http://localhost:8888/api/v1    # test ortamı: http://localhost:3004
```

Doğrulama: `bash backend/scripts/verify-mobile.sh` (analyze, test, release manifestinde INTERNET izni).
