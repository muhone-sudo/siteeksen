-- Migration: 008_manager_roles.sql
-- Yönetim tarafı rol değerleri (MANAGER, AUDITOR, STAFF) RBAC için kullanılacak.
-- users.roles zaten TEXT[] olduğundan şema değişikliği gerekmiyor; sadece demo
-- yönetici hesabına MANAGER rolü ekleniyor (admin panel/admin_app RBAC menü
-- filtrelemesinin test edilebilmesi için).

UPDATE users
SET roles = array_append(roles, 'MANAGER')
WHERE phone = '+905551234567'
  AND NOT ('MANAGER' = ANY(roles));
