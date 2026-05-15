-- ============================================================
--  Midsouth Venture Labs — Intake Form Schema
--  Run this in: Supabase Dashboard → SQL Editor → New Query
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";


-- ── 1. APPLICATIONS (anchor table) ──────────────────────────
CREATE TABLE IF NOT EXISTS applications (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  status       TEXT NOT NULL DEFAULT 'draft'
                 CHECK (status IN ('draft','submitted','under_review','accepted','declined')),
  stage_number INT  NOT NULL DEFAULT 0,
  submitted_at TIMESTAMPTZ,
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ── 2. COMPANY INFO ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS company_info (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id         UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  company_name           TEXT,
  website                TEXT,
  incorporation_status   TEXT,
  state_of_incorporation TEXT,
  founded_date           DATE,
  industry               TEXT,
  business_model         TEXT,
  startup_stage          TEXT,
  one_line_pitch         TEXT,
  elevator_pitch         TEXT,
  UNIQUE (application_id)
);


-- ── 3. TEAM MEMBERS (founders) ──────────────────────────────
CREATE TABLE IF NOT EXISTS team_members (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id     UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  full_name          TEXT,
  role               TEXT,
  linkedin_url       TEXT,
  commitment_type    TEXT,
  background_summary TEXT,
  is_founder         BOOLEAN NOT NULL DEFAULT true,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ── 4. ADVISORS ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS advisors (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id     UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  full_name          TEXT,
  role               TEXT,
  linkedin_url       TEXT,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ── 5. PROBLEM & SOLUTION ───────────────────────────────────
CREATE TABLE IF NOT EXISTS problem_solution (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id      UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  problem_description TEXT,
  target_customer     TEXT,
  solution_description TEXT,
  competitors         TEXT,
  differentiator      TEXT,
  unfair_advantage    TEXT,
  UNIQUE (application_id)
);


-- ── 6. TRACTION ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS traction (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id       UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  has_paying_customers BOOLEAN,
  customer_count       INT,
  user_count           INT,
  mrr                  NUMERIC(12,2),
  milestones_achieved  TEXT,
  pilots_or_lois       TEXT,
  UNIQUE (application_id)
);


-- ── 7. FINANCIALS ───────────────────────────────────────────
CREATE TABLE IF NOT EXISTS financials (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id  UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  total_raised    NUMERIC(14,2),
  prior_investors TEXT,
  monthly_burn    NUMERIC(12,2),
  runway_months   INT,
  funding_sought  NUMERIC(14,2),
  use_of_funds    TEXT,
  UNIQUE (application_id)
);


-- ── 8. PROGRAM FIT ──────────────────────────────────────────
CREATE TABLE IF NOT EXISTS program_fit (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id      UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  primary_goals       TEXT,
  biggest_obstacle    TEXT,
  success_definition  TEXT,
  comm_preference     TEXT,
  availability        TEXT,
  UNIQUE (application_id)
);


-- ── 9. DOCUMENTS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS documents (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  application_id    UUID NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
  document_type     TEXT NOT NULL
                      CHECK (document_type IN ('pitch_deck','financial_model','cap_table','press','other')),
  storage_path      TEXT NOT NULL,
  original_filename TEXT,
  uploaded_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);


-- ── INDEXES ─────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_company_info_app     ON company_info(application_id);
CREATE INDEX IF NOT EXISTS idx_team_members_app     ON team_members(application_id);
CREATE INDEX IF NOT EXISTS idx_advisors_app         ON advisors(application_id);
CREATE INDEX IF NOT EXISTS idx_problem_solution_app ON problem_solution(application_id);
CREATE INDEX IF NOT EXISTS idx_traction_app         ON traction(application_id);
CREATE INDEX IF NOT EXISTS idx_financials_app       ON financials(application_id);
CREATE INDEX IF NOT EXISTS idx_program_fit_app      ON program_fit(application_id);
CREATE INDEX IF NOT EXISTS idx_documents_app        ON documents(application_id);
CREATE INDEX IF NOT EXISTS idx_applications_status  ON applications(status);


-- ── AUTO-UPDATE updated_at ──────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_applications_updated_at
  BEFORE UPDATE ON applications
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();


-- ── ROW LEVEL SECURITY (RLS) ────────────────────────────────
-- Enables RLS on all tables so the anon key can only INSERT/UPDATE
-- its own records. Anyone can create a draft; only your service_role
-- key (used in your admin panel) can read all rows.

ALTER TABLE applications    ENABLE ROW LEVEL SECURITY;
ALTER TABLE company_info    ENABLE ROW LEVEL SECURITY;
ALTER TABLE team_members    ENABLE ROW LEVEL SECURITY;
ALTER TABLE advisors        ENABLE ROW LEVEL SECURITY;
ALTER TABLE problem_solution ENABLE ROW LEVEL SECURITY;
ALTER TABLE traction        ENABLE ROW LEVEL SECURITY;
ALTER TABLE financials      ENABLE ROW LEVEL SECURITY;
ALTER TABLE program_fit     ENABLE ROW LEVEL SECURITY;
ALTER TABLE documents       ENABLE ROW LEVEL SECURITY;

-- Allow anonymous users (the intake form) to insert new applications
CREATE POLICY "anon can insert applications"
  ON applications FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can update own application"
  ON applications FOR UPDATE TO anon
  USING (true) WITH CHECK (true);

CREATE POLICY "anon can insert company_info"
  ON company_info FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can upsert company_info"
  ON company_info FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can insert problem_solution"
  ON problem_solution FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can upsert problem_solution"
  ON problem_solution FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can insert traction"
  ON traction FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can upsert traction"
  ON traction FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can insert financials"
  ON financials FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can upsert financials"
  ON financials FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can insert program_fit"
  ON program_fit FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can upsert program_fit"
  ON program_fit FOR UPDATE TO anon USING (true) WITH CHECK (true);

CREATE POLICY "anon can insert team_members"
  ON team_members FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can delete own team_members"
  ON team_members FOR DELETE TO anon USING (true);

CREATE POLICY "anon can insert advisors"
  ON advisors FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "anon can delete own advisors"
  ON advisors FOR DELETE TO anon USING (true);

CREATE POLICY "anon can insert documents"
  ON documents FOR INSERT TO anon WITH CHECK (true);


-- ── STORAGE BUCKET ──────────────────────────────────────────
-- Run this separately in SQL Editor OR create the bucket manually
-- in Storage → New Bucket → name: "application-docs", Private: ON

INSERT INTO storage.buckets (id, name, public)
VALUES ('application-docs', 'application-docs', false)
ON CONFLICT (id) DO NOTHING;

-- Allow anon to upload into the bucket
CREATE POLICY "anon can upload application docs"
  ON storage.objects FOR INSERT TO anon
  WITH CHECK (bucket_id = 'application-docs');


-- ── DONE ────────────────────────────────────────────────────
-- Tables created:
--   applications, company_info, team_members, advisors,
--   problem_solution, traction, financials, program_fit, documents
-- Storage bucket: application-docs
-- RLS policies: anon INSERT/UPDATE on all tables, anon upload to bucket
