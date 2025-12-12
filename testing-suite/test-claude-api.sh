#!/bin/bash

################################################################################
# Test Script: Claude API Integration
# Tests Claude API with sample job data to verify response format and cost
################################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DATA_FILE="${SCRIPT_DIR}/test-data/test-job.json"
RESULTS_DIR="${SCRIPT_DIR}/results"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_FILE="${RESULTS_DIR}/claude_api_test_${TIMESTAMP}.json"

# Ensure results directory exists
mkdir -p "${RESULTS_DIR}"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Claude API Integration Test${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Check for required environment variables
if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo -e "${RED}ERROR: ANTHROPIC_API_KEY environment variable not set${NC}"
    echo "Set it with: export ANTHROPIC_API_KEY='your-key-here'"
    exit 1
fi

echo -e "${GREEN}✓${NC} ANTHROPIC_API_KEY found"
echo ""

# Load test job data
if [ ! -f "$TEST_DATA_FILE" ]; then
    echo -e "${RED}ERROR: Test data file not found: $TEST_DATA_FILE${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} Test data file loaded: $TEST_DATA_FILE"
echo ""

# Extract first test case
TEST_CASE=$(jq '.test_jobs[0]' "$TEST_DATA_FILE")
JOB_TITLE=$(echo "$TEST_CASE" | jq -r '.fields.Vacaturetitel')
DESCRIPTION=$(echo "$TEST_CASE" | jq -r '.fields.Omschrijving')
REQUIREMENTS=$(echo "$TEST_CASE" | jq -r '.fields.Requirements')
LOCATION=$(echo "$TEST_CASE" | jq -r '.fields.Locatie')
SENIORITY=$(echo "$TEST_CASE" | jq -r '.fields.Senioriteit')
SALARY=$(echo "$TEST_CASE" | jq -r '.fields.Salaris')
USPS=$(echo "$TEST_CASE" | jq -r '.fields.USPs')

echo -e "${BLUE}Test Case:${NC} $JOB_TITLE"
echo -e "${BLUE}Location:${NC} $LOCATION"
echo -e "${BLUE}Seniority:${NC} $SENIORITY"
echo ""

# Build Claude API request
PROMPT="Je bent recruitment marketing copywriter.

VACATURE:
Titel: ${JOB_TITLE}
Omschrijving: ${DESCRIPTION}
Requirements: ${REQUIREMENTS}
Locatie: ${LOCATION}
Senioriteit: ${SENIORITY}
Salaris: ${SALARY}
USPs: ${USPS}

GENEREER (output ALLEEN valid JSON, geen markdown):

{
  \"headline_1\": \"[outcome-driven, max 80 chars]\",
  \"headline_2\": \"[challenge-focused, max 80 chars]\",
  \"headline_3\": \"[culture angle, max 80 chars]\",
  \"ad_copy_1\": \"[problem-solution framing, max 350 chars]\",
  \"ad_copy_2\": \"[opportunity-transformation, max 350 chars]\",
  \"targeting\": {
    \"linkedin_titles\": [\"title1\", \"title2\", \"title3\"],
    \"linkedin_skills\": [\"skill1\", \"skill2\", \"skill3\"],
    \"meta_interests\": [\"interest1\", \"interest2\"],
    \"geo\": \"${LOCATION}\"
  }
}"

# Create API request body
API_REQUEST=$(cat <<EOF
{
  "model": "claude-sonnet-4-20250514",
  "max_tokens": 2000,
  "temperature": 0.7,
  "messages": [
    {
      "role": "user",
      "content": $(echo "$PROMPT" | jq -R -s .)
    }
  ]
}
EOF
)

echo -e "${YELLOW}Calling Claude API...${NC}"
START_TIME=$(date +%s)

# Make API request
HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
  -X POST https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d "$API_REQUEST")

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# Extract status code and body
HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_STATUS=$(echo "$HTTP_RESPONSE" | tail -n1)

echo -e "${GREEN}✓${NC} API Response received in ${DURATION}s"
echo -e "${BLUE}HTTP Status:${NC} $HTTP_STATUS"
echo ""

# Check HTTP status
if [ "$HTTP_STATUS" != "200" ]; then
    echo -e "${RED}ERROR: API request failed with status $HTTP_STATUS${NC}"
    echo "$HTTP_BODY" | jq '.'
    exit 1
fi

# Parse response
CONTENT=$(echo "$HTTP_BODY" | jq -r '.content[0].text')
INPUT_TOKENS=$(echo "$HTTP_BODY" | jq -r '.usage.input_tokens')
OUTPUT_TOKENS=$(echo "$HTTP_BODY" | jq -r '.usage.output_tokens')
MODEL=$(echo "$HTTP_BODY" | jq -r '.model')

# Calculate cost (Claude Sonnet 4 pricing)
INPUT_COST=$(echo "scale=6; $INPUT_TOKENS * 0.000003" | bc)
OUTPUT_COST=$(echo "scale=6; $OUTPUT_TOKENS * 0.000015" | bc)
TOTAL_COST=$(echo "scale=6; $INPUT_COST + $OUTPUT_COST" | bc)

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  API Response Metrics${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Model:${NC} $MODEL"
echo -e "${BLUE}Input Tokens:${NC} $INPUT_TOKENS"
echo -e "${BLUE}Output Tokens:${NC} $OUTPUT_TOKENS"
echo -e "${BLUE}Total Tokens:${NC} $((INPUT_TOKENS + OUTPUT_TOKENS))"
echo -e "${BLUE}Estimated Cost:${NC} \$${TOTAL_COST}"
echo ""

# Clean and parse generated content
CLEAN_CONTENT=$(echo "$CONTENT" | sed 's/```json//g' | sed 's/```//g' | tr -d '\n' | sed 's/^[[:space:]]*//' | sed 's/[[:space:]]*$//')

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Generated Content${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Validate JSON parsing
if ! echo "$CLEAN_CONTENT" | jq '.' > /dev/null 2>&1; then
    echo -e "${RED}✗ FAILED: Invalid JSON response${NC}"
    echo -e "${YELLOW}Raw content:${NC}"
    echo "$CLEAN_CONTENT"
    exit 1
fi

echo -e "${GREEN}✓ Valid JSON response${NC}"
echo ""

# Extract generated fields
HEADLINE_1=$(echo "$CLEAN_CONTENT" | jq -r '.headline_1')
HEADLINE_2=$(echo "$CLEAN_CONTENT" | jq -r '.headline_2')
HEADLINE_3=$(echo "$CLEAN_CONTENT" | jq -r '.headline_3')
AD_COPY_1=$(echo "$CLEAN_CONTENT" | jq -r '.ad_copy_1')
AD_COPY_2=$(echo "$CLEAN_CONTENT" | jq -r '.ad_copy_2')

# Display content
echo -e "${BLUE}Headline 1:${NC} (${#HEADLINE_1} chars)"
echo "  $HEADLINE_1"
echo ""
echo -e "${BLUE}Headline 2:${NC} (${#HEADLINE_2} chars)"
echo "  $HEADLINE_2"
echo ""
echo -e "${BLUE}Headline 3:${NC} (${#HEADLINE_3} chars)"
echo "  $HEADLINE_3"
echo ""
echo -e "${BLUE}Ad Copy 1:${NC} (${#AD_COPY_1} chars)"
echo "  $AD_COPY_1"
echo ""
echo -e "${BLUE}Ad Copy 2:${NC} (${#AD_COPY_2} chars)"
echo "  $AD_COPY_2"
echo ""

# Validation
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Validation Results${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

VALIDATION_PASSED=true

# Check headline lengths
for i in 1 2 3; do
    HEADLINE_VAR="HEADLINE_$i"
    HEADLINE_LEN=${#!HEADLINE_VAR}
    if [ $HEADLINE_LEN -gt 80 ]; then
        echo -e "${RED}✗ Headline $i too long: $HEADLINE_LEN chars (max 80)${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}✓ Headline $i length OK: $HEADLINE_LEN/80 chars${NC}"
    fi
done

# Check ad copy lengths
for i in 1 2; do
    COPY_VAR="AD_COPY_$i"
    COPY_LEN=${#!COPY_VAR}
    if [ $COPY_LEN -gt 350 ]; then
        echo -e "${RED}✗ Ad Copy $i too long: $COPY_LEN chars (max 350)${NC}"
        VALIDATION_PASSED=false
    else
        echo -e "${GREEN}✓ Ad Copy $i length OK: $COPY_LEN/350 chars${NC}"
    fi
done

# Check for generic phrases
GENERIC_PHRASES=("geweldige kans" "join ons team" "we zoeken" "solliciteer nu")
for phrase in "${GENERIC_PHRASES[@]}"; do
    if echo "$HEADLINE_1 $HEADLINE_2 $HEADLINE_3" | grep -iq "$phrase"; then
        echo -e "${YELLOW}⚠ Warning: Generic phrase detected: '$phrase'${NC}"
        VALIDATION_PASSED=false
    fi
done

# Check for required fields in targeting
TARGETING=$(echo "$CLEAN_CONTENT" | jq -r '.targeting')
LINKEDIN_TITLES_COUNT=$(echo "$TARGETING" | jq '.linkedin_titles | length')
LINKEDIN_SKILLS_COUNT=$(echo "$TARGETING" | jq '.linkedin_skills | length')

if [ "$LINKEDIN_TITLES_COUNT" -lt 3 ]; then
    echo -e "${RED}✗ Insufficient LinkedIn titles: $LINKEDIN_TITLES_COUNT (min 3)${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}✓ LinkedIn titles count OK: $LINKEDIN_TITLES_COUNT${NC}"
fi

if [ "$LINKEDIN_SKILLS_COUNT" -lt 3 ]; then
    echo -e "${RED}✗ Insufficient LinkedIn skills: $LINKEDIN_SKILLS_COUNT (min 3)${NC}"
    VALIDATION_PASSED=false
else
    echo -e "${GREEN}✓ LinkedIn skills count OK: $LINKEDIN_SKILLS_COUNT${NC}"
fi

echo ""

# Save results
RESULTS=$(cat <<EOF
{
  "test_name": "Claude API Integration Test",
  "timestamp": "$(date -Iseconds)",
  "duration_seconds": $DURATION,
  "test_case": "$(echo "$TEST_CASE" | jq -r '.name')",
  "job_title": "$JOB_TITLE",
  "api_response": {
    "model": "$MODEL",
    "input_tokens": $INPUT_TOKENS,
    "output_tokens": $OUTPUT_TOKENS,
    "total_cost_usd": $TOTAL_COST
  },
  "generated_content": $(echo "$CLEAN_CONTENT" | jq .),
  "validation": {
    "passed": $VALIDATION_PASSED,
    "headline_1_length": ${#HEADLINE_1},
    "headline_2_length": ${#HEADLINE_2},
    "headline_3_length": ${#HEADLINE_3},
    "ad_copy_1_length": ${#AD_COPY_1},
    "ad_copy_2_length": ${#AD_COPY_2},
    "linkedin_titles_count": $LINKEDIN_TITLES_COUNT,
    "linkedin_skills_count": $LINKEDIN_SKILLS_COUNT
  }
}
EOF
)

echo "$RESULTS" | jq '.' > "$RESULTS_FILE"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}✓ ALL VALIDATIONS PASSED${NC}"
    echo ""
    echo -e "Results saved to: ${GREEN}$RESULTS_FILE${NC}"
    exit 0
else
    echo -e "${RED}✗ SOME VALIDATIONS FAILED${NC}"
    echo ""
    echo -e "Results saved to: ${YELLOW}$RESULTS_FILE${NC}"
    exit 1
fi
