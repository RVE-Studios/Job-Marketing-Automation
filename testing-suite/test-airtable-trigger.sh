#!/bin/bash

################################################################################
# Test Script: Airtable Trigger
# Creates a test record in Airtable to verify workflow triggers correctly
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Airtable Trigger Test${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for required environment variables
if [ -z "$AIRTABLE_API_KEY" ]; then
    echo -e "${RED}ERROR: AIRTABLE_API_KEY environment variable not set${NC}"
    echo "Get your API key from: https://airtable.com/create/tokens"
    echo "Set it with: export AIRTABLE_API_KEY='your-key-here'"
    exit 1
fi

echo -e "${GREEN}✓${NC} AIRTABLE_API_KEY found"

# Airtable configuration (from workflow JSON)
BASE_ID="appRhnA2VngPTd6JO"
TABLE_ID="tblN1K0pCU7UPiFfs"
TABLE_NAME="Vacatures"

echo -e "${BLUE}Base ID:${NC} $BASE_ID"
echo -e "${BLUE}Table:${NC} $TABLE_NAME"
echo ""

# Create test record
echo -e "${YELLOW}Creating test record...${NC}"

TEST_RECORD=$(cat <<EOF
{
  "fields": {
    "Vacaturetitel": "TEST - Automated Test Job $(date +%H:%M:%S)",
    "Functietitel EN": "TEST - Automated Test Position",
    "Omschrijving": "This is an automated test record created by the test-airtable-trigger.sh script. It contains sufficient text to pass validation (minimum 100 characters). The workflow should trigger, generate content using Claude API, and update this record with headlines, ad copy, and targeting information. You can safely delete this record after verifying the workflow completed successfully.",
    "Requirements": "Automated testing, Bash scripting, n8n workflows, Airtable API, Claude API integration",
    "Locatie": "Amsterdam",
    "Senioriteit": "Medior",
    "Salaris": "€50.000 - €60.000",
    "USPs": "Automated testing environment, CI/CD integration, monitoring and alerting"
  }
}
EOF
)

# Make API request to create record
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST "https://api.airtable.com/v0/${BASE_ID}/${TABLE_ID}" \
  -H "Authorization: Bearer $AIRTABLE_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$TEST_RECORD")

# Extract status code and body
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)

if [ "$HTTP_STATUS" != "200" ]; then
    echo -e "${RED}ERROR: Failed to create record (HTTP $HTTP_STATUS)${NC}"
    echo "$HTTP_BODY" | jq '.'
    exit 1
fi

RECORD_ID=$(echo "$HTTP_BODY" | jq -r '.id')
JOB_TITLE=$(echo "$HTTP_BODY" | jq -r '.fields.Vacaturetitel')

echo -e "${GREEN}✓${NC} Test record created successfully"
echo -e "${BLUE}Record ID:${NC} $RECORD_ID"
echo -e "${BLUE}Job Title:${NC} $JOB_TITLE"
echo ""

# Instructions for manual verification
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Manual Verification Steps${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""
echo "1. Open your n8n workflow dashboard"
echo ""
echo "2. Check workflow executions (should show new execution within 5 minutes)"
echo "   - n8n polls Airtable every 5 minutes by default"
echo "   - If trigger is webhook-based, execution should be immediate"
echo ""
echo "3. Verify execution nodes completed:"
echo "   ✓ Airtable Trigger"
echo "   ✓ Parse Data"
echo "   ✓ Claude API call"
echo "   ✓ Parse Output"
echo "   ✓ Update Airtable"
echo ""
echo "4. Check Airtable record: $RECORD_ID"
echo "   https://airtable.com/${BASE_ID}/${TABLE_ID}"
echo ""
echo "5. Verify these fields were populated:"
echo "   - Status (should be 'Done' or 'Error')"
echo "   - Headline 1, 2, 3"
echo "   - Ad Copy 1, 2"
echo "   - Targeting (JSON)"
echo "   - Generated At (timestamp)"
echo "   - Error Log (should be empty if Status = Done)"
echo ""

# Wait option
echo -e "${YELLOW}Would you like to wait and check the result automatically? (y/n)${NC}"
read -r WAIT_RESPONSE

if [[ "$WAIT_RESPONSE" =~ ^[Yy]$ ]]; then
    echo ""
    echo -e "${YELLOW}Waiting 5 minutes for workflow to process...${NC}"

    for i in {1..30}; do
        sleep 10
        echo -n "."
    done

    echo ""
    echo ""
    echo -e "${YELLOW}Checking record status...${NC}"

    # Fetch updated record
    UPDATED_RECORD=$(curl -s \
      -X GET "https://api.airtable.com/v0/${BASE_ID}/${TABLE_ID}/${RECORD_ID}" \
      -H "Authorization: Bearer $AIRTABLE_API_KEY")

    STATUS=$(echo "$UPDATED_RECORD" | jq -r '.fields.Status // "Not Set"')
    HEADLINE_1=$(echo "$UPDATED_RECORD" | jq -r '.fields."Headline 1" // "Not Set"')
    ERROR_LOG=$(echo "$UPDATED_RECORD" | jq -r '.fields."Error Log" // ""')

    echo ""
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  Record Status${NC}"
    echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}Status:${NC} $STATUS"

    if [ "$STATUS" == "Done" ]; then
        echo -e "${GREEN}✓ Workflow completed successfully${NC}"
        echo ""
        echo -e "${BLUE}Generated Headline 1:${NC}"
        echo "  $HEADLINE_1"
        echo ""
        echo -e "${GREEN}Test PASSED - You can delete the test record now${NC}"
        exit 0
    elif [ "$STATUS" == "Error" ]; then
        echo -e "${RED}✗ Workflow failed${NC}"
        echo -e "${RED}Error Log:${NC}"
        echo "  $ERROR_LOG"
        echo ""
        echo -e "${YELLOW}Check n8n execution logs for details${NC}"
        exit 1
    else
        echo -e "${YELLOW}⚠ Workflow may not have triggered yet${NC}"
        echo -e "${YELLOW}Check n8n manually:${NC}"
        echo "  - Verify trigger is active"
        echo "  - Check execution history"
        echo "  - Confirm polling interval (default 5 min)"
        exit 0
    fi
else
    echo ""
    echo -e "${BLUE}Manual check required${NC}"
    echo "Check Airtable and n8n in 5-10 minutes"
    echo ""
    echo -e "${YELLOW}To delete the test record later:${NC}"
    echo "  curl -X DELETE \\"
    echo "    'https://api.airtable.com/v0/${BASE_ID}/${TABLE_ID}/${RECORD_ID}' \\"
    echo "    -H 'Authorization: Bearer \$AIRTABLE_API_KEY'"
    echo ""
    exit 0
fi
