-- ==============================================================================
-- Migration: Tambah Kolom Koordinat (latitude, longitude) & Tabel Supabase Scan Koper dan Paspor
-- Tanggal: 23 November 2026
-- ==============================================================================

-- 1. Buat Tabel koper jika belum ada
CREATE TABLE IF NOT EXISTS public.koper (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    kode_koper text NOT NULL,
    nama_pemilik text,
    nomor_telepon text,
    kloter text,
    scanned_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    no_urutan integer,
    latitude double precision,
    longitude double precision,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tambah kolom latitude & longitude jika tabel koper sudah ada sebelumnya
ALTER TABLE public.koper 
ADD COLUMN IF NOT EXISTS latitude double precision;

ALTER TABLE public.koper 
ADD COLUMN IF NOT EXISTS longitude double precision;

ALTER TABLE public.koper 
ADD COLUMN IF NOT EXISTS no_urutan integer;

-- 2. Buat Tabel passport_scans jika belum ada
CREATE TABLE IF NOT EXISTS public.passport_scans (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    passport_number text NOT NULL,
    owner_name text,
    phone text,
    kloter text,
    scanned_by uuid REFERENCES public.profiles(id) ON DELETE SET NULL,
    no_urutan integer,
    latitude double precision,
    longitude double precision,
    scanned_at timestamp with time zone DEFAULT timezone('utc'::text, now()),
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Tambah kolom latitude & longitude jika tabel passport_scans sudah ada sebelumnya
ALTER TABLE public.passport_scans 
ADD COLUMN IF NOT EXISTS latitude double precision;

ALTER TABLE public.passport_scans 
ADD COLUMN IF NOT EXISTS longitude double precision;

ALTER TABLE public.passport_scans 
ADD COLUMN IF NOT EXISTS no_urutan integer;

-- 3. Tambah Index untuk optimasi performa query koordinat & pencarian
CREATE INDEX IF NOT EXISTS idx_koper_latitude ON public.koper (latitude);
CREATE INDEX IF NOT EXISTS idx_koper_longitude ON public.koper (longitude);
CREATE INDEX IF NOT EXISTS idx_passport_scans_latitude ON public.passport_scans (latitude);
CREATE INDEX IF NOT EXISTS idx_passport_scans_longitude ON public.passport_scans (longitude);

-- 4. Enable Row Level Security (RLS)
ALTER TABLE public.koper ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.passport_scans ENABLE ROW LEVEL SECURITY;

-- 5. Policies (Akses SELECT, INSERT, UPDATE, DELETE untuk koper & passport_scans)
DO $$
BEGIN
    -- Policy SELECT untuk koper
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'koper' AND policyname = 'Allow select on koper') THEN
        CREATE POLICY "Allow select on koper" ON public.koper FOR SELECT USING (true);
    END IF;

    -- Policy INSERT untuk koper
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'koper' AND policyname = 'Allow insert on koper') THEN
        CREATE POLICY "Allow insert on koper" ON public.koper FOR INSERT WITH CHECK (true);
    END IF;

    -- Policy UPDATE untuk koper
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'koper' AND policyname = 'Allow update on koper') THEN
        CREATE POLICY "Allow update on koper" ON public.koper FOR UPDATE USING (true);
    END IF;

    -- Policy DELETE untuk koper
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'koper' AND policyname = 'Allow delete on koper') THEN
        CREATE POLICY "Allow delete on koper" ON public.koper FOR DELETE USING (true);
    END IF;

    -- Policy SELECT untuk passport_scans
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'passport_scans' AND policyname = 'Allow select on passport_scans') THEN
        CREATE POLICY "Allow select on passport_scans" ON public.passport_scans FOR SELECT USING (true);
    END IF;

    -- Policy INSERT untuk passport_scans
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'passport_scans' AND policyname = 'Allow insert on passport_scans') THEN
        CREATE POLICY "Allow insert on passport_scans" ON public.passport_scans FOR INSERT WITH CHECK (true);
    END IF;

    -- Policy UPDATE untuk passport_scans
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'passport_scans' AND policyname = 'Allow update on passport_scans') THEN
        CREATE POLICY "Allow update on passport_scans" ON public.passport_scans FOR UPDATE USING (true);
    END IF;

    -- Policy DELETE untuk passport_scans
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'passport_scans' AND policyname = 'Allow delete on passport_scans') THEN
        CREATE POLICY "Allow delete on passport_scans" ON public.passport_scans FOR DELETE USING (true);
    END IF;
END $$;
