CREATE TABLE IF NOT EXISTS md_insight_report_log (
  report_id     INT           NOT NULL AUTO_INCREMENT PRIMARY KEY,
  plant_code    VARCHAR(128)  NOT NULL,
  period        VARCHAR(7)    NOT NULL,
  generated_at  DATETIME      NOT NULL,
  generated_by  VARCHAR(191)  NOT NULL,
  report_state  VARCHAR(32)   NOT NULL,
  source        VARCHAR(16)   NOT NULL DEFAULT 'manual',
  payload_json  LONGTEXT      NULL,
  INDEX idx_md_insight_report_log_plant_period (plant_code, period)
);

-- Run against existing deployments (MySQL 8.0.29+ supports IF NOT EXISTS on
-- ADD COLUMN; on older versions drop that clause and ignore the duplicate-
-- column error if it's already applied).
-- `source` distinguishes:
--   'manual' — existing behavior: logged when a user clicks Download Report.
--   'auto'   — the canonical, locked monthly snapshot written by
--              mdInsightMonthlyRollup.js at month rollover (or via the
--              backfill route). Exactly one 'auto' row is kept per
--              (plant_code, period) — the rollup deletes any existing
--              'auto' row for that pair before inserting, so it's safe to
--              re-run without creating duplicates.
ALTER TABLE md_insight_report_log
  ADD COLUMN IF NOT EXISTS source VARCHAR(16) NOT NULL DEFAULT 'manual' AFTER report_state;
