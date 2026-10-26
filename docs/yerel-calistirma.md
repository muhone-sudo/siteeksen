# Yerel çalıştırma ve giriş bilgileri

Son doğrulama: 2026-10-25. Aşağıdaki her satır bu tarihte çalıştırılarak denendi.

## Adresler

| Ne | Adres |
|---|---|
| Admin paneli | http://localhost:3001 |
| Gateway | http://localhost:8888 (`/health` → 200) |
| PostgreSQL (dev kabı `siteeksen-dev-db`) | `localhost:55432` |

## Demo hesaplar (seed verisi)

| Telefon | Şifre | Kişi | Roller |
|---|---|---|---|
| `5551234567` | `Demo123!` | Ahmet Yılmaz | BOARD_MEMBER, MANAGER, OWNER, RESIDENT |
| `5559876543` | `Demo123!` | Mehmet Demir | RESIDENT, TENANT |

Panele giriş yönetici hesabıyla yapılır (`5551234567`). Kademeli giriş kilidi vardır: 5. hatalı denemede
30 sn, 6.'da 2 dk, 7. ve sonrasında 15 dk bekleme.

## Çalıştırma

```bash
systemctl --user start docker-desktop      # Docker Desktop kapalıysa
bash backend/scripts/dev-up.sh             # PostgreSQL + migration + servisler + gateway (ön planda)
cd admin && npm run dev                    # panel, ayrı terminalde
bash backend/scripts/dev-up.sh --stop      # hepsini durdur
```

## `admin/.env.local` (depoya girmez, elle oluşturulur)

```
NEXT_PUBLIC_API_URL=http://localhost:8888/api/v1
NEXTAUTH_URL=http://localhost:3001
NEXTAUTH_SECRET=dev-secret-123
```

`NEXT_PUBLIC_API_URL` **`/api/v1` ile bitmelidir.** `/api` yazılırsa panel `/api/auth/login`'e gider;
gateway bu yolu korumalı sayıp 401 döner ve panel "Telefon numarası veya şifre hatalı" der, oysa
bilgiler doğrudur. Değişiklikten sonra `npm run dev` yeniden başlatılmalıdır (Next.js env'i açılışta okur)
**ve tarayıcıda Ctrl+Shift+R yapılmalıdır**: açık sekme eski kodla `/api/...` istemeye devam eder ve her
modülde "Bu özellik henüz sunucu tarafında hazır değil (404)" görünür. Tarayıcının hangi yolu istediği
`/tmp/dev-gateway.log` içindeki `"path"` alanından görülür.

## Hızlı kontrol

```bash
curl -s localhost:8888/health
curl -s -X POST localhost:8888/api/v1/auth/login -H 'Content-Type: application/json' \
  -d '{"phone":"5551234567","password":"Demo123!"}'      # access_token dönmeli
```
