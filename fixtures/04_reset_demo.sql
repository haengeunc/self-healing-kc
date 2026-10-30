-- ============================================================================
-- 04_reset_demo.sql
-- One-shot 5-second SQL script that reverts opening_mrr_usd back to
-- start_mrr_usd, drops contraction_mrr_usd, and restores the baseline
-- 3-node revenue_retention property graph.
-- ============================================================================

-- 1. Revert column name opening_mrr_usd -> start_mrr_usd
ALTER TABLE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
RENAME COLUMN opening_mrr_usd TO start_mrr_usd;

ALTER TABLE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
ALTER COLUMN start_mrr_usd SET OPTIONS (
  description = 'Starting monthly recurring revenue at the beginning of the billing period in USD.'
);

-- 2. Drop contraction_mrr_usd added during Scene 1
ALTER TABLE `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements`
DROP COLUMN IF EXISTS contraction_mrr_usd;

-- 3. Restore baseline 3-Node BigQuery Property Graph (Account, Subscription, MrrMovement)
CREATE OR REPLACE PROPERTY GRAPH `opm-looker-core-demo-instance.sales_analytics_demo.revenue_retention`
  NODE TABLES (
    `opm-looker-core-demo-instance.sales_analytics_demo.tbl_accounts_v2` AS Account
      KEY (acc_id)
      LABEL Account
      PROPERTIES (
        acc_id AS account_id,
        account_name AS account_name,
        region AS region,
        segment AS segment,
        industry AS industry,
        status AS status
      ),
    `opm-looker-core-demo-instance.sales_analytics_demo.tbl_subscriptions` AS Subscription
      KEY (sub_id)
      LABEL Subscription
      PROPERTIES (
        sub_id AS subscription_id,
        acc_id AS account_id,
        sku_tier AS sku_tier,
        billing_cadence AS billing_cadence,
        contract_arr_usd AS contract_arr,
        contract_start_date AS contract_start_date,
        renewal_date AS renewal_date
      ),
    `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements` AS MrrMovement
      KEY (mrr_event_id)
      LABEL MrrMovement
      PROPERTIES (
        mrr_event_id AS mrr_event_id,
        acc_id AS account_id,
        sub_id AS subscription_id,
        billing_month AS billing_month,
        start_mrr_usd AS starting_mrr,
        expansion_mrr_usd AS expansion_mrr,
        churned_mrr_usd AS churn_mrr
      )
  )
  EDGE TABLES (
    `opm-looker-core-demo-instance.sales_analytics_demo.tbl_subscriptions` AS subscription_account
      KEY (sub_id)
      SOURCE KEY (sub_id) REFERENCES Subscription (sub_id)
      DESTINATION KEY (acc_id) REFERENCES Account (acc_id)
      LABEL subscription_account
      NO PROPERTIES,
    `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements` AS mrr_movement_subscription
      KEY (mrr_event_id)
      SOURCE KEY (mrr_event_id) REFERENCES MrrMovement (mrr_event_id)
      DESTINATION KEY (sub_id) REFERENCES Subscription (sub_id)
      LABEL mrr_movement_subscription
      NO PROPERTIES,
    `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements` AS account_mrr_movements
      KEY (mrr_event_id)
      SOURCE KEY (mrr_event_id) REFERENCES MrrMovement (mrr_event_id)
      DESTINATION KEY (acc_id) REFERENCES Account (acc_id)
      LABEL account_mrr_movements
      NO PROPERTIES
  );
