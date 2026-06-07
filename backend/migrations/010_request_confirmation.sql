-- Migration: 010_request_confirmation.sql
-- Talep onay mekanizması: yönetici talebi RESOLVED işaretledikten sonra
-- sakin "sorunum çözüldü" diyerek onaylar (CLOSED + user_confirmed_at) ya da
-- reddederse talep IN_PROGRESS'e geri döner.

ALTER TABLE requests ADD COLUMN IF NOT EXISTS user_confirmed_at TIMESTAMP NULL;
