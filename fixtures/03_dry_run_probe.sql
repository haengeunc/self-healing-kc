-- ============================================================================
-- 03_dry_run_probe.sql
-- Zero-cost ($0, 0 bytes billed) BigQuery CTE dry-run probes synthesized by
-- the Knowledge Catalog Self-Healing Ontology Agent (workflow=SELF_LEARNING)
-- across the 3-entity model (Account, Subscription, MrrMovement).
--
-- Usage:
--   Pre-heal probe (lines 14-45):
--     bq query --project_id="opm-looker-core-demo-instance" --use_legacy_sql=false \
--       --dry_run --label datacloud:vscode \
--       "$(sed -n '14,45p' "${FIXTURES_DIR}/03_dry_run_probe.sql")"
--   Post-heal probe (lines 50-85):
--     bq query --project_id="opm-looker-core-demo-instance" --use_legacy_sql=false \
--       --dry_run --label datacloud:vscode \
--       "$(sed -n '50,85p' "${FIXTURES_DIR}/03_dry_run_probe.sql")"
-- ============================================================================
WITH
  Account AS (
    SELECT acc_id AS account_id, account_name, region, segment, industry, status
    FROM `opm-looker-core-demo-instance.sales_analytics_demo.tbl_accounts_v2`
    WHERE 1 = 0
  ),
  Subscription AS (
    SELECT sub_id AS subscription_id, acc_id AS account_id, sku_tier, billing_cadence, contract_arr_usd AS contract_arr
    FROM `opm-looker-core-demo-instance.sales_analytics_demo.tbl_subscriptions`
    WHERE 1 = 0
  ),
  MrrMovement AS (
    SELECT
      mrr_event_id,
      acc_id AS account_id,
      sub_id AS subscription_id,
      billing_month,
      start_mrr_usd AS starting_mrr,
      expansion_mrr_usd AS expansion_mrr,
      churned_mrr_usd AS churn_mrr
    FROM `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
    WHERE 1 = 0
  )
SELECT
  Account.region,
  Subscription.sku_tier,
  SUM(MrrMovement.starting_mrr) AS total_starting_mrr,
  (SUM(MrrMovement.starting_mrr) + SUM(MrrMovement.expansion_mrr) - SUM(MrrMovement.churn_mrr))
    / NULLIF(SUM(MrrMovement.starting_mrr), 0) AS net_revenue_retention
FROM MrrMovement
JOIN Subscription ON MrrMovement.subscription_id = Subscription.subscription_id
JOIN Account ON MrrMovement.account_id = Account.account_id
GROUP BY Account.region, Subscription.sku_tier;

-- ============================================================================
-- SECTION B: POST-HEAL ZERO-COST CTE PROBE (Lines 50-85)
-- Rebinds starting_mrr -> opening_mrr_usd and incorporates contraction_mrr_usd
-- ============================================================================
WITH
  Account AS (
    SELECT acc_id AS account_id, account_name, region, segment, industry, status
    FROM `opm-looker-core-demo-instance.sales_analytics_demo.tbl_accounts_v2`
    WHERE 1 = 0
  ),
  Subscription AS (
    SELECT sub_id AS subscription_id, acc_id AS account_id, sku_tier, billing_cadence, contract_arr_usd AS contract_arr
    FROM `opm-looker-core-demo-instance.sales_analytics_demo.tbl_subscriptions`
    WHERE 1 = 0
  ),
  MrrMovement AS (
    SELECT
      mrr_event_id,
      acc_id AS account_id,
      sub_id AS subscription_id,
      billing_month,
      opening_mrr_usd AS starting_mrr,
      expansion_mrr_usd AS expansion_mrr,
      contraction_mrr_usd AS contraction_mrr,
      churned_mrr_usd AS churn_mrr
    FROM `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
    WHERE 1 = 0
  )
SELECT
  Account.region,
  Subscription.sku_tier,
  SUM(MrrMovement.starting_mrr) AS total_starting_mrr,
  (SUM(MrrMovement.starting_mrr) + SUM(MrrMovement.expansion_mrr) - SUM(MrrMovement.contraction_mrr) - SUM(MrrMovement.churn_mrr))
    / NULLIF(SUM(MrrMovement.starting_mrr), 0) AS net_revenue_retention
FROM MrrMovement
JOIN Subscription ON MrrMovement.subscription_id = Subscription.subscription_id
JOIN Account ON MrrMovement.account_id = Account.account_id
GROUP BY Account.region, Subscription.sku_tier;
