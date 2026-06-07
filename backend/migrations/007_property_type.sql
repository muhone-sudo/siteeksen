-- Migration: 007_property_type.sql
-- properties tablosuna tür bilgisi ekler (Site, Apartman, Bina vb.)

ALTER TABLE properties ADD COLUMN IF NOT EXISTS type VARCHAR(20) NOT NULL DEFAULT 'SITE';
-- type: SITE (Site), APARTMENT (Apartman), BUILDING (Bina/Plaza)
