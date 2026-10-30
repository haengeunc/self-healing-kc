## Automated Self-Healing Ontology Pull Request (`workflow=SELF_LEARNING`)

**Context Set (`EntryGroup`)**: `projects/opm-looker-core-demo-instance/locations/us-central1/entryGroups/sales-analytics`  
**Semantic Model (`OSI+G`)**: `revenue_retention` (`version: "0.2.0.dev0/google"`, 3 Entities: `Account`, `Subscription`, `MrrMovement`)  
**Target Property Graph**: `opm-looker-core-demo-instance.sales_analytics_demo.revenue_retention`

---

### 1. Root-Cause Diagnosis (Billing Pipeline v2.4 Schema Drift)

1. **Zero-Cost Pre-Flight Probe Failure (`$0`, `0 B` billed)**:
   - Synthetic BigQuery CTE dry-run probe (`WHERE 1 = 0` across `Account` $\bowtie$ `Subscription` $\bowtie$ `MrrMovement`) detected a broken column binding on `MrrMovement.starting_mrr`:
     ```text
     Unrecognized name: start_mrr_usd; Did you mean opening_mrr_usd? at [20:7]
     ```
2. **`INFORMATION_SCHEMA` & Column Metadata Inspection**:
   - On `opm-looker-core-demo-instance.sales_analytics_demo.fct_mrr_movements` (**260 MRR events** across **60 accounts** and **90 subscriptions**):
     - `start_mrr_usd` was renamed to `opening_mrr_usd` (*"Opening monthly recurring revenue at the start of the billing period in USD"*).
     - A new `contraction_mrr_usd` (`NUMERIC`) column was added to separate seat downgrades and tier contractions from full-account churn (`churned_mrr_usd`).

---

### 2. Summary of `.osi.yaml` Ontology Repairs

- **Rebound `MrrMovement.starting_mrr`**: Updated physical `expression` from `start_mrr_usd` $\rightarrow$ `opening_mrr_usd` while preserving the canonical semantic field name `starting_mrr`.
- **Added `MrrMovement.contraction_mrr` & `total_contraction_mrr`**: Exposed seat downgrade contraction (`contraction_mrr_usd`) as a first-class governed field and metric.
- **Updated `net_retained_mrr` & `net_revenue_retention` (`NRR`)**: Netted out `contraction_mrr` alongside `churn_mrr` (`(starting + expansion - contraction - churn) / starting`).

---

### 3. Deterministic Pre-Flight & Benchmark Verification Scorecard

| Verification Gate | Command / Check | Result | Cost / Status |
| :--- | :--- | :--- | :--- |
| **Gate 1: BigQuery CTE Dry-Run Probe** | `bq query --dry_run` (`WHERE 1 = 0` over `Account` $\bowtie$ `Subscription` $\bowtie$ `MrrMovement`) | `0 bytes` to be processed | **PASSED (`$0.00`)** |
| **Gate 2: `kcmd` Grammar & Graph Compiler** | `kcmd push --validate-only --print` | Compiled 3-node, 3-edge `CREATE OR REPLACE PROPERTY GRAPH` + KC entries (`0 errors`) | **PASSED** |
| **Gate 3: Golden NRR Benchmark Suite** | `run_eval_suite.py --eval-file golden_mrr_questions.eval.yaml` | **3 / 3 Passed (`100.0%`)** (`nonRegressionGate: 1.00`) | **PASSED** |

#### Certified Regional NRR Benchmark Results (`GQ-01` – `GQ-03`)
- **`AMER`**: `104.53%` (`1.0453` across 20 accounts, 30 subscriptions, 90 MRR events — `$1,425,100.00` / `$1,363,350.00`)
- **`APAC`**: `102.93%` (`1.0293` — reflects `$24,100.00` v2.4 tier contraction across 85 MRR events — `$1,286,050.00` / `$1,249,450.00`)
- **`EMEA`**: `104.67%` (`1.0467` — reflects `$7,500.00` v2.4 tier contraction across 85 MRR events — `$1,243,650.00` / `$1,188,200.00`)
- **Portfolio Net Retained MRR (`GQ-03`)**: `$3,954,800.00` / `$3,801,000.00` (`104.05%`)
