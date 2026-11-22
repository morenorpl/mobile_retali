-- ============================================================================
-- SQL SCRIPT: Menambahkan Kolom cover Pada Tabel Persiapan Umrah
-- Tabel: persiapan_diniyah & persiapan_teknis
-- ============================================================================

-- 1. Tambah kolom cover (tipe TEXT) pada tabel persiapan_diniyah
ALTER TABLE public.persiapan_diniyah 
ADD COLUMN IF NOT EXISTS cover TEXT;

-- 2. Tambah kolom cover (tipe TEXT) pada tabel persiapan_teknis
ALTER TABLE public.persiapan_teknis 
ADD COLUMN IF NOT EXISTS cover TEXT;

-- 3. (Opsional) Sinkronisasi data lama jika attachment_url sebelumnya berisi URL gambar cover
UPDATE public.persiapan_diniyah 
SET cover = attachment_url 
WHERE cover IS NULL AND attachment_url IS NOT NULL;

UPDATE public.persiapan_teknis 
SET cover = attachment_url 
WHERE cover IS NULL AND attachment_url IS NOT NULL;
