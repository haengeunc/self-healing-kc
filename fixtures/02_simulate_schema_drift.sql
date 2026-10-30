-- ============================================================================
-- 02_simulate_schema_drift.sql
-- Live Scene 1 DDL script: Billing Pipeline v2.4 migration
--   1. Renames start_mrr_usd -> opening_mrr_usd on fct_mrr_movements (260 rows)
--   2. Adds contraction_mrr_usd for seat downgrades and tier contractions
-- ============================================================================

-- Step 1: Rename physical column start_mrr_usd to opening_mrr_usd
ALTER TABLE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
RENAME COLUMN start_mrr_usd TO opening_mrr_usd;

-- Step 2: Update column description on opening_mrr_usd for lineage clarity
ALTER TABLE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
ALTER COLUMN opening_mrr_usd SET OPTIONS (
  description = 'Opening monthly recurring revenue at the start of the billing period in USD (renamed from start_mrr_usd in billing pipeline v2.4).'
);

-- Step 3: Add new contraction_mrr_usd column separated from churn in v2.4
ALTER TABLE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
ADD COLUMN IF NOT EXISTS contraction_mrr_usd NUMERIC OPTIONS (
  description = 'Monthly recurring revenue lost from seat downgrades or tier contractions in USD while the account remains active. Must be subtracted alongside churned_mrr_usd when computing net retained MRR and Net Revenue Retention (NRR).'
);

-- Step 4: Populate v2.4 contraction ledger events (APAC: 24,100 USD, EMEA: 7,500 USD, AMER: 0 USD)
UPDATE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
SET contraction_mrr_usd = CASE
  WHEN mrr_event_id = 'MRR-20036' THEN NUMERIC '1850.00'
  WHEN mrr_event_id = 'MRR-20037' THEN NUMERIC '2350.00'
  WHEN mrr_event_id = 'MRR-20038' THEN NUMERIC '1600.00'
  WHEN mrr_event_id = 'MRR-20039' THEN NUMERIC '2950.00'
  WHEN mrr_event_id = 'MRR-20040' THEN NUMERIC '2100.00'
  WHEN mrr_event_id = 'MRR-20041' THEN NUMERIC '3250.00'
  WHEN mrr_event_id = 'MRR-20042' THEN NUMERIC '1950.00'
  WHEN mrr_event_id = 'MRR-20043' THEN NUMERIC '2650.00'
  WHEN mrr_event_id = 'MRR-20044' THEN NUMERIC '2800.00'
  WHEN mrr_event_id = 'MRR-20045' THEN NUMERIC '2600.00'
  WHEN mrr_event_id = 'MRR-30036' THEN NUMERIC '650.00'
  WHEN mrr_event_id = 'MRR-30037' THEN NUMERIC '900.00'
  WHEN mrr_event_id = 'MRR-30038' THEN NUMERIC '550.00'
  WHEN mrr_event_id = 'MRR-30039' THEN NUMERIC '850.00'
  WHEN mrr_event_id = 'MRR-30040' THEN NUMERIC '700.00'
  WHEN mrr_event_id = 'MRR-30041' THEN NUMERIC '950.00'
  WHEN mrr_event_id = 'MRR-30042' THEN NUMERIC '600.00'
  WHEN mrr_event_id = 'MRR-30043' THEN NUMERIC '800.00'
  WHEN mrr_event_id = 'MRR-30044' THEN NUMERIC '750.00'
  WHEN mrr_event_id = 'MRR-30045' THEN NUMERIC '750.00'
  ELSE NUMERIC '0.00'
END
WHERE TRUE;
