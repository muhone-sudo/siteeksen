-- Migration: 009_kvkk_consent.sql
-- KVKK açık rıza akışı için kullanıcının onay zamanını saklayan kolon.
-- NULL ise kullanıcı henüz onay vermemiştir; ilk girişte zorunlu onay ekranı gösterilir.

ALTER TABLE users ADD COLUMN IF NOT EXISTS kvkk_consent_at TIMESTAMP NULL;
