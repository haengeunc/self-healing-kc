#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BRANCH="fix/self-heal-fct-mrr-movements-opening-mrr"
TITLE="fix(ontology): self-heal starting_mrr -> opening_mrr_usd in revenue_retention"
BODY_FILE="${REPO_DIR}/fixtures/pr_body_healed_mrr.md"

cd "${REPO_DIR}"
git checkout -B "${BRANCH}"
git add models/revenue_retention.osi.yaml
git commit -m "fix(ontology): self-heal starting_mrr -> opening_mrr_usd on fct_mrr_movements" --allow-empty
git push -f -u origin "${BRANCH}"

python3 - "${TITLE}" "${BODY_FILE}" "${BRANCH}" << 'PYEOF'
import sys, urllib.parse

title = sys.argv[1]
with open(sys.argv[2], "r", encoding="utf-8") as f:
    body = f.read()
branch = sys.argv[3]

params = urllib.parse.urlencode({
    "quick_pull": "1",
    "title": title,
    "body": body,
})
url = f"https://github.com/haengeunc/self-healing-kc/compare/main...{branch}?{params}"
print("\n" + "=" * 78)
print("Outbound BYOG Pull Request Branch Pushed to GitHub!")
print("Repository : https://github.com/haengeunc/self-healing-kc")
print("Branch     :", branch)
print("Pre-filled PR URL (Cmd+Click to open in Tab 4):")
print(url)
print("=" * 78)
PYEOF
