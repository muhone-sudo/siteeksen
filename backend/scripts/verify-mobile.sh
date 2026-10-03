#!/usr/bin/env bash
#
# verify-mobile.sh — İki Flutter uygulaması için doğrulama betiği.
#
# NEDEN VAR:
# 2026-09-09 denetiminde mobil tarafta "yapıldı" denen işlerin doğrulanamadığı görüldü
# (makinede Flutter yoktu). Flutter 2026-09-13'te WSL'e kuruldu; artık mobil değişiklikler
# de kanıtla işaretlenebilir. Bu betik `verify-stack.sh`in mobil karşılığıdır.
#
# KULLANIM:
#   bash backend/scripts/verify-mobile.sh
#
# GEREKSİNİM: flutter (PATH'te ya da ~/flutter/bin)
#
# ÇIKIŞ KODU: 0 = tüm kontroller geçti
#
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PASS=0
FAIL=0
ok()   { echo "  [GEÇTİ]    $1"; PASS=$((PASS+1)); }
bad()  { echo "  [BAŞARISIZ] $1"; FAIL=$((FAIL+1)); }
step() { echo ""; echo "=== $1 ==="; }

if ! command -v flutter >/dev/null 2>&1; then
  if [ -x "$HOME/flutter/bin/flutter" ]; then
    export PATH="$PATH:$HOME/flutter/bin"
  else
    echo "flutter bulunamadı (PATH ya da ~/flutter/bin)"; exit 1
  fi
fi

step "0) Araç sürümü"
flutter --version | head -1 | sed 's/^/  /'

for APP in mobile admin_app; do
  step "$APP"
  cd "$REPO_ROOT/$APP" || { bad "$APP dizini yok"; continue; }

  if flutter pub get >/tmp/verify-pubget-$APP.log 2>&1; then
    ok "$APP: flutter pub get"
  else
    bad "$APP: flutter pub get"; tail -8 /tmp/verify-pubget-$APP.log; continue
  fi

  # Hata ve uyarılar kapıdır; bilgi (info) düzeyi henüz temizlenmedi (todo 0.C.6).
  # Bilgi (info) düzeyi de kapıdır (2026-10-03, 0.C.6): iki uygulamada sıfıra indirildi;
  # yeni bir kullanımdan kalkmış API ya da eksik const yeniden birikmesin.
  if flutter analyze >/tmp/verify-analyze-$APP.log 2>&1; then
    ok "$APP: flutter analyze (hata/uyarı/bilgi yok)"
  else
    bad "$APP: flutter analyze"
    grep -E "error •|warning •|info •" /tmp/verify-analyze-$APP.log | head -10 | sed 's/^/      /'
  fi

  if flutter test >/tmp/verify-test-$APP.log 2>&1; then
    ok "$APP: flutter test ($(grep -o '+[0-9]*' /tmp/verify-test-$APP.log | tail -1) test geçti)"
  else
    bad "$APP: flutter test"; tail -12 /tmp/verify-test-$APP.log | sed 's/^/      /'
  fi
done

step "Dürüstlük: mobilde sahte başarı mesajı kalmamalı"
# "Ödeme Başarılı" gibi mesajlar ağ çağrısı yapılmadan gösteriliyordu.
# Yorum satırları (açıklama amaçlı geçen ifadeler) hariç tutulur.
FAKE=$(grep -rn "Ödeme Başarılı" "$REPO_ROOT/mobile/lib" "$REPO_ROOT/admin_app/lib" 2>/dev/null \
  | grep -v ':[0-9]*: *//' | wc -l)
[ "$FAKE" -eq 0 ] && ok "sahte 'Ödeme Başarılı' mesajı yok" || bad "$FAKE adet sahte ödeme başarı mesajı var"

HARDNAME=$(grep -rn "Ahmet Yılmaz\|Mehmet Demir\|Ayşe Yılmaz\|Ali Veli\|Ayşe Kaya" \
  "$REPO_ROOT/mobile/lib" "$REPO_ROOT/admin_app/lib" 2>/dev/null \
  | grep -v ':[0-9]*: *//' | wc -l)
[ "$HARDNAME" -eq 0 ] && ok "arayüzde gömülü sahte kullanıcı adı yok" || bad "$HARDNAME satırda gömülü sahte kullanıcı adı var"

step "SONUÇ"
echo "  Geçen: $PASS   Başarısız: $FAIL"
[ "$FAIL" -eq 0 ] && { echo "  TÜM KONTROLLER GEÇTİ"; exit 0; } || { echo "  BAŞARISIZ KONTROL VAR"; exit 1; }
