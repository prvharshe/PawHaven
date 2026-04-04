-- ============================================================
-- PawHaven — Phase 3: Urgent / Emergency pets
-- Run in: Supabase Dashboard → SQL Editor
-- ============================================================

-- Add urgent flag to pets table
ALTER TABLE public.pets
    ADD COLUMN IF NOT EXISTS urgent boolean NOT NULL DEFAULT false;

-- Index for map queries (only urgent pets are shown on map)
CREATE INDEX IF NOT EXISTS pets_urgent_idx ON public.pets(urgent) WHERE urgent = true;
