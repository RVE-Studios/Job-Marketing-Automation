# Deployment Checklist - Recruitment Marketing Automation

## Overview

This checklist ensures proper setup and deployment of the enhanced Job Marketing workflow with all improvements implemented.

**Estimated Setup Time**: 2-3 hours
**Prerequisites**: n8n cloud account, Airtable account, Claude API access

---

## Phase 1: Prerequisites & Access (30 min)

### 1.1 API Keys & Credentials

- [ ] **Anthropic API Key**
  - Sign up at: https://console.anthropic.com/
  - Create API key with sufficient credits
  - Minimum recommended: $25 initial credit
  - Store securely (password manager)
  - **Copy key**: `sk-ant-...`

- [ ] **Airtable Access Token**
  - Create at: https://airtable.com/create/tokens
  - Required scopes:
    - `data.records:read`
    - `data.records:write`
    - `schema.bases:read`
  - Add base access: `appRhnA2VngPTd6JO` (Recruitment Marketing)
  - **Copy token**: `pat...`

- [ ] **LinkedIn Ads API** (Phase 2 - Optional)
  - LinkedIn Ads account with admin access
  - Create Developer App: https://www.linkedin.com/developers/apps
  - OAuth 2.0 credentials:
    - Client ID: `____________`
    - Client Secret: `____________`
  - Ad Account ID: `____________`
  - Organization ID: `____________`

### 1.2 n8n Cloud Setup

- [ ] n8n cloud account active
  - Plan: Starter ($20/month) minimum
  - Check execution limits: 2,500/month on Starter
  - Confirm timezone settings match your region

- [ ] n8n credentials configured:
  - [ ] Anthropic API (new credential type)
  - [ ] Airtable Token API
  - [ ] LinkedIn OAuth 2.0 (if Phase 2)

---

## Phase 2: Airtable Configuration (30 min)

### 2.1 Verify Existing Fields

Open Airtable base: https://airtable.com/appRhnA2VngPTd6JO/tblN1K0pCU7UPiFfs

Confirm these fields exist:

**Input Fields** (filled by users):
- [ ] `Vacaturetitel` (Single line text)
- [ ] `Functietitel EN` (Single line text)
- [ ] `Omschrijving` (Long text)
- [ ] `Requirements` (Long text)
- [ ] `Locatie` (Single line text)
- [ ] `Senioriteit` (Single select: Junior, Medior, Senior)
- [ ] `Salaris` (Single line text)
- [ ] `USPs` (Long text)

**Output Fields** (populated by workflow):
- [ ] `Status` (Single line text)
- [ ] `Headline 1` (Single line text)
- [ ] `Headline 2` (Single line text)
- [ ] `Headline 3` (Single line text)
- [ ] `Ad Copy 1` (Long text)
- [ ] `Ad Copy 2` (Long text)
- [ ] `Targeting` (Long text)
- [ ] `Generated At` (Date with time)
- [ ] `Error Log` (Long text)

### 2.2 Add New Fields for Enhanced Features

Create these additional fields:

- [ ] **Tokens_Used** (Number field)
  - Description: "Total API tokens consumed"
  - Format: Integer
  - Default: 0

- [ ] **Estimated_Cost** (Currency field)
  - Description: "API cost in USD"
  - Currency: USD
  - Precision: 4 decimal places

- [ ] **Quality_Issues** (Long text field)
  - Description: "Automated quality validation results"

- [ ] **Daily_Budget** (Currency field) - Phase 2
  - Description: "Daily LinkedIn Ads budget in EUR"
  - Currency: EUR
  - Default: 50

- [ ] **Auto_Publish** (Checkbox field) - Phase 2
  - Description: "Automatically create LinkedIn campaign"
  - Default: Unchecked

- [ ] **LinkedIn_Campaign_ID** (Single line text) - Phase 2
- [ ] **LinkedIn_Creative_IDs** (Long text) - Phase 2
- [ ] **Campaign_Status** (Single select) - Phase 2
  - Options: Draft, Paused, Active, API Error
- [ ] **Campaign_Created_At** (Date with time) - Phase 2

### 2.3 Create Views (Optional but Recommended)

- [ ] **Pending Content** view
  - Filter: `Status` is empty OR `Status` = ""
  - Purpose: Shows jobs waiting for content generation

- [ ] **Errors** view
  - Filter: `Status` = "Error"
  - Purpose: Quick access to failed generations

- [ ] **Review Needed** view
  - Filter: `Status` = "Review"
  - Purpose: Content with quality issues

- [ ] **Ready to Publish** view (Phase 2)
  - Filter: `Status` = "Done" AND `Auto_Publish` = checked
  - Purpose: Jobs ready for LinkedIn campaign creation

---

## Phase 3: n8n Workflow Deployment (45 min)

### 3.1 Import Workflows

#### Option A: Fresh Import (Recommended)

1. [ ] In n8n, click "Add workflow" → "Import from File"
2. [ ] Import `workflows/enhanced-workflow.json` (to be created)
3. [ ] Workflow name: "Job Marketing - Enhanced"

#### Option B: Update Existing Workflow

1. [ ] Open existing "Job Marketing - Content Generation" workflow
2. [ ] **⚠️ CRITICAL**: Create backup first
   - Workflow → Download → Save as `backup-YYYYMMDD.json`
3. [ ] Follow manual update steps below

### 3.2 Configure Workflow Nodes

#### Node 1: Airtable Trigger

- [ ] Credential: Select `Airtable-Recruitment Vacatures`
- [ ] Base: `Recruitment Marketing` (appRhnA2VngPTd6JO)
- [ ] Table: `Vacatures` (tblN1K0pCU7UPiFfs)
- [ ] Trigger Field: `Vacaturetitel`
- [ ] Poll Interval: Every 5 minutes (default)
- [ ] **Optional**: Add filter for `Status` is empty (avoids retriggers)

#### Node 2: Parse Data (Validation)

- [ ] Replace code with enhanced version from `lib/error-handlers.js`
- [ ] Copy `validateJobInput()` function
- [ ] Implement try-catch error handling
- [ ] Test with sample data

#### Node 3: Claude API Call

- [ ] Method: POST
- [ ] URL: `https://api.anthropic.com/v1/messages`
- [ ] Authentication: Anthropic API credential
- [ ] Headers:
  - `anthropic-version`: `2023-06-01`
  - `content-type`: `application/json`
- [ ] Body: Copy improved prompt from `docs/improved-prompts.md`
- [ ] **Enable retry**: `retryOnFail: true`, Max tries: 3, Wait: 5000ms

#### Node 4: Parse Output (Enhanced)

- [ ] Replace code with `parseClaudeOutput()` from `lib/error-handlers.js`
- [ ] Includes:
  - Token usage extraction
  - Cost calculation
  - Quality validation
  - Character limit checks
- [ ] Test output structure

#### Node 5: Update Airtable

- [ ] Credential: Same as trigger
- [ ] Operation: Update
- [ ] Base/Table: Same as trigger
- [ ] Match column: `id`
- [ ] Update fields:
  - `Status` → `{{ $json.status }}`
  - `Headline 1` → `{{ $json.headline1 }}`
  - `Headline 2` → `{{ $json.headline2 }}`
  - `Headline 3` → `{{ $json.headline3 }}`
  - `Ad Copy 1` → `{{ $json.adCopy1 }}`
  - `Ad Copy 2` → `{{ $json.adCopy2 }}`
  - `Targeting` → `{{ $json.targeting }}`
  - `Generated At` → `{{ $json.generatedAt }}`
  - `Tokens_Used` → `{{ $json.tokensUsed }}`
  - `Estimated_Cost` → `{{ $json.estimatedCost }}`
  - `Quality_Issues` → `{{ $json.qualityIssues }}`
  - `Error Log` → `{{ $json.errorLog }}`

### 3.3 Remove Duplicate Nodes (If Updating Existing)

- [ ] **Delete these nodes** (they duplicate the first 5):
  - Parse Data1 (node 6)
  - HTTP Request (node 7)
  - Parse Output1 (node 8)
  - Update record (node 9)

- [ ] Update connections:
  - Ensure workflow ends at "Update Airtable" (node 5)
  - No dangling connections

### 3.4 Test Workflow

- [ ] Click "Execute Workflow" manually
- [ ] Use test data from `testing-suite/test-data/test-job.json`
- [ ] Verify each node completes successfully:
  - ✓ Parse Data outputs valid data
  - ✓ Claude API returns 200 status
  - ✓ Parse Output extracts all fields
  - ✓ Airtable updates successfully

- [ ] Check execution time: should be 10-15s (down from 20-30s)

---

## Phase 4: Environment Variables (15 min)

### 4.1 n8n Environment Variables

Set these in n8n Settings → Variables:

```bash
ANTHROPIC_API_KEY=sk-ant-xxx...
AIRTABLE_API_KEY=patxxx...

# Phase 2 (LinkedIn Ads)
LINKEDIN_AD_ACCOUNT_ID=123456789
LINKEDIN_ORGANIZATION_ID=987654321
CAREER_PAGE_URL=https://your-company.com/careers

# Monitoring
DAILY_BUDGET_LIMIT=5.00
ALERT_EMAIL=your-email@company.com
```

### 4.2 Security Best Practices

- [ ] Never commit API keys to git
- [ ] Use n8n's credential encryption
- [ ] Rotate keys quarterly
- [ ] Monitor API usage in dashboards:
  - Anthropic: https://console.anthropic.com/usage
  - Airtable: https://airtable.com/account (API section)

---

## Phase 5: Testing & Validation (30 min)

### 5.1 Run Test Scripts

Make scripts executable:
```bash
cd testing-suite
chmod +x *.sh
```

#### Test 1: Claude API Integration
```bash
export ANTHROPIC_API_KEY="sk-ant-xxx..."
./test-claude-api.sh
```

Expected output:
- ✓ Valid JSON response
- ✓ All headlines ≤ 80 chars
- ✓ All ad copy ≤ 350 chars
- ✓ Cost < $0.01 per test

#### Test 2: Error Handling
```bash
./test-error-handling.sh
```

Expected output:
- ✓ Invalid data correctly rejected
- ✓ Malformed JSON detected
- ✓ Generic phrases flagged

#### Test 3: Airtable Trigger
```bash
export AIRTABLE_API_KEY="patxxx..."
./test-airtable-trigger.sh
```

Expected output:
- ✓ Test record created
- ✓ Workflow triggers within 5 min
- ✓ Record updated with content

### 5.2 Manual Testing Checklist

Create test jobs in Airtable:

- [ ] **Test 1**: Complete valid job (Senior level)
  - Expect: Status = "Done", all fields populated

- [ ] **Test 2**: Minimal data job (Junior level)
  - Expect: Status = "Done", may have quality issues

- [ ] **Test 3**: Invalid job (missing description)
  - Expect: Status = "Error", error log populated

- [ ] **Test 4**: Edge case (very long description)
  - Expect: Status = "Done" or "Review"

### 5.3 Verify Results

For each test:

- [ ] Check n8n execution logs (no errors)
- [ ] Verify Airtable record updated
- [ ] Review generated content quality:
  - Headlines under 80 chars?
  - Ad copy under 350 chars?
  - No generic phrases?
  - Targeting data populated?
- [ ] Check cost tracking:
  - `Tokens_Used` populated?
  - `Estimated_Cost` reasonable ($0.004-$0.008)?

---

## Phase 6: LinkedIn Ads Integration (Phase 2 - Optional) (1-2 hours)

### 6.1 LinkedIn API Setup

- [ ] Create LinkedIn Developer App
  - Go to: https://www.linkedin.com/developers/apps
  - Create new app
  - Product: Marketing Developer Platform
  - OAuth 2.0 scopes:
    - `r_ads`
    - `rw_ads`
    - `r_organization_admin`

- [ ] Get OAuth Access Token
  ```bash
  # Use LinkedIn OAuth 2.0 flow or n8n OAuth node
  # Store token in n8n credentials
  ```

- [ ] Get Ad Account ID
  ```bash
  curl -X GET \
    'https://api.linkedin.com/rest/adAccounts?q=search&search=(status:(values:List(ACTIVE,DRAFT)))' \
    -H "Authorization: Bearer {ACCESS_TOKEN}" \
    -H "LinkedIn-Version: 202407"
  ```

### 6.2 Import LinkedIn Ads Extension

- [ ] Import `workflows/linkedin-ads-extension.json` as NEW workflow
- [ ] Name: "LinkedIn Ads - Campaign Creation"
- [ ] Configure credentials:
  - LinkedIn OAuth 2.0
  - Airtable (same as main workflow)

### 6.3 Connect Workflows

Option A: Merge into single workflow
- [ ] Copy nodes from extension into main workflow
- [ ] Connect "Update Airtable" → "Check Auto Publish"

Option B: Keep separate (recommended for testing)
- [ ] Set up workflow trigger:
  - Trigger: Webhook from main workflow
  - OR Airtable trigger on Status = "Done" AND Auto_Publish = true

### 6.4 Test LinkedIn Integration

- [ ] Create test job with `Auto_Publish` checked
- [ ] Verify campaign created in LinkedIn Campaign Manager
- [ ] Check campaign settings:
  - Status: Paused (safe default)
  - Budget: Matches `Daily_Budget` field
  - Targeting: Matches generated criteria
  - Creatives: 3 variants (one per headline)

- [ ] Verify Airtable updated:
  - `LinkedIn_Campaign_ID` populated
  - `LinkedIn_Creative_IDs` JSON array
  - `Campaign_Status` = "Draft"

---

## Phase 7: Monitoring & Alerting (30 min)

### 7.1 Cost Monitoring

#### Option A: Airtable Formula Field

Create calculated field `Total_Daily_Cost`:
```
SUM(
  {Estimated_Cost}
  WHERE {Generated At} > TODAY()
)
```

Create automation:
- Trigger: When `Total_Daily_Cost` > €5
- Action: Send email alert

#### Option B: n8n Monitoring Workflow

Create separate workflow:
- Schedule: Every hour
- Query Airtable for today's records
- Sum `Estimated_Cost`
- If > $5, send Slack/email notification

### 7.2 Error Monitoring

- [ ] Set up n8n workflow error notifications:
  - Settings → Error Workflow
  - Select notification method (email/Slack)

- [ ] Create Airtable automation:
  - Trigger: Record enters "Errors" view
  - Action: Send notification with error log

### 7.3 Success Rate Tracking

Create Airtable dashboard view:

- [ ] **Total Jobs** (count)
- [ ] **Success Rate** (Done / Total * 100)
- [ ] **Error Rate** (Error / Total * 100)
- [ ] **Review Rate** (Review / Total * 100)
- [ ] **Avg Cost** (Average of Estimated_Cost)
- [ ] **Total Spend** (Sum of Estimated_Cost)

Update weekly to track trends.

---

## Phase 8: Go-Live Preparation (15 min)

### 8.1 Final Checks

- [ ] All test records deleted from Airtable
- [ ] Workflow is **ACTIVE** in n8n
- [ ] Credentials are valid (not expired)
- [ ] Team trained on:
  - How to add new jobs to Airtable
  - How to interpret Status field
  - How to handle "Review" status
  - How to manually approve LinkedIn campaigns

### 8.2 Documentation for Team

Create internal docs covering:

- [ ] **How to add a new job**:
  1. Open Airtable
  2. Add new record
  3. Fill required fields (title, description, requirements)
  4. Wait 5 min for content generation
  5. Review output
  6. If Status = "Review", manually edit headlines/copy
  7. If Status = "Error", check Error Log and fix data

- [ ] **How to handle errors**:
  - Check Error Log field
  - Common issues:
    - "Omschrijving te kort" → Add more detail
    - "Parse error" → Contact tech team
    - "API timeout" → Will retry automatically

- [ ] **How to use LinkedIn Ads** (Phase 2):
  1. Check `Auto_Publish` checkbox
  2. Set `Daily_Budget` (default €50)
  3. Wait for campaign creation (1-2 min)
  4. Go to LinkedIn Campaign Manager
  5. Review campaign, adjust targeting if needed
  6. Change status to "Active" to start ads

### 8.3 Rollout Plan

Recommended approach:

**Week 1**: Pilot (5-10 jobs)
- [ ] Select 5 diverse test jobs
- [ ] Generate content
- [ ] Review quality manually
- [ ] Collect feedback from recruiters
- [ ] Adjust prompts if needed

**Week 2**: Expand (20-30 jobs)
- [ ] Process all pending jobs
- [ ] Monitor costs daily
- [ ] Track time savings vs manual content creation
- [ ] Document any issues

**Week 3**: Full Production
- [ ] Enable for all new jobs
- [ ] Weekly quality reviews
- [ ] Monthly cost/performance reports

**Week 4+**: Optimize
- [ ] A/B test prompt variants
- [ ] Analyze which content performs best (CTR)
- [ ] Refine targeting based on LinkedIn/Meta metrics
- [ ] Consider Meta Ads integration (similar to LinkedIn)

---

## Cost Estimates

### Per-Job Costs (Optimized Workflow)

```
Claude API (1 call instead of 2):
- Input: ~500 tokens × $0.000003 = $0.0015
- Output: ~1000 tokens × $0.000015 = $0.015
- Total per job: ~$0.0165 (down from ~$0.033)

Monthly (100 jobs):
- Claude API: $1.65
- n8n cloud (Starter): $20.00
- Airtable (Free tier): $0
────────────────────────────
Total: ~$21.65/month
```

### LinkedIn Ads Costs (Phase 2 - Optional)

```
API calls: FREE (LinkedIn doesn't charge for API)
Ad spend: Variable (your budget)
- Recommended: €50/day per campaign
- 5 active campaigns: €250/day = ~€7,500/month

Note: Ad spend is separate from automation costs
```

### Total Platform Costs

```
BEFORE automation:
- Manual copywriting: 30 min per job × 100 jobs = 50 hours/month
- Hourly rate: €50/hour
- Cost: €2,500/month

AFTER automation:
- Platform costs: €21.65/month
- Manual review: 5 min per job = 8.3 hours/month (€415)
- Total: €436.65/month
────────────────────────────
SAVINGS: ~€2,063/month (82% reduction)
```

---

## Troubleshooting

### Issue: Workflow doesn't trigger

**Symptoms**: New Airtable records don't generate content

**Solutions**:
1. Check workflow is **ACTIVE** in n8n
2. Verify `Vacaturetitel` field changed (trigger field)
3. Check polling interval (default 5 min)
4. Test manually: Execute Workflow button
5. Check n8n execution quota (2,500/month on Starter)

### Issue: Claude API errors

**Symptoms**: Status = "Error", error log mentions API failure

**Solutions**:
1. Verify `ANTHROPIC_API_KEY` is valid
2. Check API credit balance: https://console.anthropic.com/
3. Review error message:
   - "Rate limit" → Wait 1 minute, will retry
   - "Invalid request" → Check prompt formatting
   - "Model not found" → Verify model name: `claude-sonnet-4-20250514`
4. Check retry is enabled (max 3 tries)

### Issue: Content quality poor

**Symptoms**: Status = "Review", generic phrases, wrong tone

**Solutions**:
1. Review `Quality_Issues` field for specific problems
2. Check job description quality (garbage in = garbage out)
3. Add more detail to `USPs` field
4. Adjust prompt based on seniority level (see improved-prompts.md)
5. Try different prompt variant (A/B test)

### Issue: Airtable update fails

**Symptoms**: Content generated but not saved to Airtable

**Solutions**:
1. Verify `AIRTABLE_API_KEY` has write permissions
2. Check field names match exactly (case-sensitive)
3. Verify new fields were created (Tokens_Used, Estimated_Cost, etc.)
4. Check field types match (e.g., Currency for Estimated_Cost)

### Issue: LinkedIn Ads creation fails (Phase 2)

**Symptoms**: `Campaign_Status` = "API Error"

**Solutions**:
1. Verify LinkedIn OAuth token not expired (refresh if needed)
2. Check `LINKEDIN_AD_ACCOUNT_ID` is correct
3. Verify account has active billing
4. Review error log for specific LinkedIn API error codes
5. Check targeting data is valid (titles, skills must exist in LinkedIn taxonomy)

---

## Support & Resources

### Documentation
- n8n Docs: https://docs.n8n.io/
- Anthropic API: https://docs.anthropic.com/
- Airtable API: https://airtable.com/developers/web/api/introduction
- LinkedIn Marketing API: https://learn.microsoft.com/en-us/linkedin/marketing/

### Community
- n8n Community: https://community.n8n.io/
- Anthropic Discord: https://anthropic.com/discord

### Internal Resources
- Workflow files: `/workflows`
- Test scripts: `/testing-suite`
- Error handlers: `/lib/error-handlers.js`
- Prompt templates: `/docs/improved-prompts.md`

---

## Deployment Sign-Off

### Deployment completed by:

- [ ] Name: _______________
- [ ] Date: _______________
- [ ] All tests passed: Yes / No
- [ ] Team trained: Yes / No
- [ ] Monitoring active: Yes / No

### Notes:

```
(Add any deployment-specific notes, issues encountered, or customizations made)
```

---

**Version**: 1.0.0
**Last Updated**: 2025-12-12
**Next Review**: 2026-01-12
