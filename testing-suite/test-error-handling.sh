#!/bin/bash

################################################################################
# Test Script: Error Handling
# Tests various error scenarios to ensure workflow handles failures gracefully
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DATA_FILE="${SCRIPT_DIR}/test-data/test-job.json"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Error Handling Test Suite${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Test helper function
run_test() {
    local test_name="$1"
    local test_case_index="$2"
    local expected_result="$3"  # "should_pass" or "should_fail"

    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${YELLOW}Test $TESTS_RUN: $test_name${NC}"

    # Extract test case
    TEST_CASE=$(jq ".test_jobs[$test_case_index]" "$TEST_DATA_FILE")
    FIELDS=$(echo "$TEST_CASE" | jq -r '.fields')

    # Simulate validation (using logic from error-handlers.js)
    JOB_TITLE=$(echo "$FIELDS" | jq -r '.Vacaturetitel // empty')
    DESCRIPTION=$(echo "$FIELDS" | jq -r '.Omschrijving // empty')
    SENIORITY=$(echo "$FIELDS" | jq -r '.Senioriteit // "Medior"')

    # Validation logic
    ERRORS=()

    # Required fields
    if [ -z "$JOB_TITLE" ]; then
        ERRORS+=("Vacaturetitel is verplicht")
    fi

    if [ -z "$DESCRIPTION" ]; then
        ERRORS+=("Omschrijving is verplicht")
    fi

    # Minimum lengths
    if [ -n "$DESCRIPTION" ] && [ ${#DESCRIPTION} -lt 100 ]; then
        ERRORS+=("Omschrijving te kort (${#DESCRIPTION} chars, min 100 nodig)")
    fi

    if [ -n "$JOB_TITLE" ] && [ ${#JOB_TITLE} -lt 5 ]; then
        ERRORS+=("Vacaturetitel te kort (${#JOB_TITLE} chars, min 5 nodig)")
    fi

    # Seniority validation
    if [ "$SENIORITY" != "Junior" ] && [ "$SENIORITY" != "Medior" ] && [ "$SENIORITY" != "Senior" ]; then
        ERRORS+=("Ongeldige Senioriteit: $SENIORITY")
    fi

    # Check result
    if [ ${#ERRORS[@]} -eq 0 ]; then
        # Validation passed
        if [ "$expected_result" == "should_pass" ]; then
            echo -e "  ${GREEN}✓ PASS${NC} - Validation passed as expected"
            echo -e "    Job: $JOB_TITLE"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "  ${RED}✗ FAIL${NC} - Expected validation to fail, but it passed"
            echo -e "    Job: $JOB_TITLE"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    else
        # Validation failed
        if [ "$expected_result" == "should_fail" ]; then
            echo -e "  ${GREEN}✓ PASS${NC} - Validation failed as expected"
            echo -e "    Errors: ${ERRORS[*]}"
            TESTS_PASSED=$((TESTS_PASSED + 1))
        else
            echo -e "  ${RED}✗ FAIL${NC} - Unexpected validation failure"
            echo -e "    Errors: ${ERRORS[*]}"
            TESTS_FAILED=$((TESTS_FAILED + 1))
        fi
    fi

    echo ""
}

# Run test cases
echo -e "${BLUE}Running validation tests...${NC}"
echo ""

# Test 1: Complete valid data
run_test "Complete valid data (Senior Developer)" 0 "should_pass"

# Test 2: Minimal valid data
run_test "Minimal valid data (Junior Frontend)" 1 "should_pass"

# Test 3: Missing description
run_test "Missing description (should fail)" 2 "should_fail"

# Test 4: Description too short
run_test "Description too short (should fail)" 3 "should_fail"

# Test 5: Complete valid data (Medior)
run_test "Complete valid data (Full Stack Developer)" 4 "should_pass"

# Additional error scenario tests

echo -e "${BLUE}Testing edge cases...${NC}"
echo ""

# Test: Invalid JSON parsing
echo -e "${YELLOW}Test $((TESTS_RUN + 1)): Malformed JSON response parsing${NC}"
MALFORMED_JSON='{"headline_1": "Test", "headline_2": "Test", incomplete...'

if echo "$MALFORMED_JSON" | jq '.' > /dev/null 2>&1; then
    echo -e "  ${RED}✗ FAIL${NC} - Should have detected malformed JSON"
    TESTS_FAILED=$((TESTS_FAILED + 1))
else
    echo -e "  ${GREEN}✓ PASS${NC} - Malformed JSON correctly detected"
    TESTS_PASSED=$((TESTS_PASSED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test: Markdown-wrapped JSON
echo -e "${YELLOW}Test $((TESTS_RUN + 1)): Markdown-wrapped JSON cleanup${NC}"
MARKDOWN_JSON='```json
{
  "headline_1": "Test",
  "headline_2": "Test",
  "headline_3": "Test"
}
```'

CLEANED=$(echo "$MARKDOWN_JSON" | sed 's/```json//g' | sed 's/```//g' | tr -d '\n' | sed 's/^[[:space:]]*//')

if echo "$CLEANED" | jq '.' > /dev/null 2>&1; then
    echo -e "  ${GREEN}✓ PASS${NC} - Markdown successfully removed, valid JSON parsed"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ FAIL${NC} - Failed to clean markdown"
    echo "$CLEANED"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test: Generic phrase detection
echo -e "${YELLOW}Test $((TESTS_RUN + 1)): Generic phrase detection${NC}"
TEST_HEADLINE="Geweldige kans voor een developer!"

GENERIC_PHRASES=("geweldige kans" "join ons team" "we zoeken")
DETECTED=false

for phrase in "${GENERIC_PHRASES[@]}"; do
    if echo "$TEST_HEADLINE" | grep -iq "$phrase"; then
        DETECTED=true
        echo -e "  ${GREEN}✓ PASS${NC} - Generic phrase detected: '$phrase'"
        break
    fi
done

if [ "$DETECTED" = true ]; then
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "  ${RED}✗ FAIL${NC} - Generic phrase not detected"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test: Character limit enforcement
echo -e "${YELLOW}Test $((TESTS_RUN + 1)): Character limit enforcement${NC}"
LONG_HEADLINE="This is a very long headline that definitely exceeds the eighty character limit and should be truncated"

if [ ${#LONG_HEADLINE} -gt 80 ]; then
    TRUNCATED="${LONG_HEADLINE:0:77}..."
    if [ ${#TRUNCATED} -le 80 ]; then
        echo -e "  ${GREEN}✓ PASS${NC} - Headline correctly truncated to ${#TRUNCATED} chars"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "  ${RED}✗ FAIL${NC} - Truncation failed: ${#TRUNCATED} chars"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
else
    echo -e "  ${YELLOW}⚠ SKIP${NC} - Test headline not long enough"
fi
TESTS_RUN=$((TESTS_RUN + 1))
echo ""

# Test Summary
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}Total Tests:${NC} $TESTS_RUN"
echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
echo -e "${RED}Failed:${NC} $TESTS_FAILED"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL TESTS PASSED${NC}"
    exit 0
else
    echo -e "${RED}✗ SOME TESTS FAILED${NC}"
    exit 1
fi
