-- ============================================================================
-- 03b_post_heal_probe.sql
-- Post-heal zero-cost ($0, 0 bytes billed) BigQuery CTE dry-run probe across
-- the 3-entity model (Account, Subscription, MrrMovement).
-- Passes after the Self-Healing Agent rebinds starting_mrr -> opening_mrr_usd
-- and adds contraction_mrr_usd.
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
