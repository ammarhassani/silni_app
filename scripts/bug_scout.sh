#!/bin/bash
#
# Bug Scout - The Prosecutor
# Runs ALL adversarial tests and generates a comprehensive bug report
#
# Usage: ./scripts/bug_scout.sh [--quick]
#   --quick  Run only fuzz + security tests (faster feedback)
#

# Colors for dramatic effect
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Configuration
REPORT_DIR="reports/bug_scout"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${REPORT_DIR}/bug_scout_${TIMESTAMP}.md"
TEST_DIR="test/adversarial"
RESULTS_FILE="/tmp/bug_scout_results_${TIMESTAMP}.txt"

# Test suites
ALL_SUITES="input_fuzzing_test.dart boundary_test.dart state_chaos_test.dart race_condition_test.dart stress_test.dart security_test.dart widget_torture_test.dart"
QUICK_SUITES="input_fuzzing_test.dart security_test.dart"

# Track results
TOTAL_BUGS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
TOTAL_SKIPPED=0
VERDICT="INNOCENT"

# Print dramatic header
print_header() {
    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ========================================================================"
    echo "  ||                                                                    ||"
    echo "  ||   ____  _   _  ____    ____   ____ ___  _   _ _____               ||"
    echo "  ||  | __ )| | | |/ ___|  / ___| / ___/ _ \| | | |_   _|              ||"
    echo "  ||  |  _ \| | | | |  _   \___ \| |  | | | | | | | | |                ||"
    echo "  ||  | |_) | |_| | |_| |   ___) | |__| |_| | |_| | | |                ||"
    echo "  ||  |____/ \___/ \____|  |____/ \____\___/ \___/  |_|                ||"
    echo "  ||                                                                    ||"
    echo "  ||                    THE PROSECUTOR                                  ||"
    echo "  ||              \"Finding bugs before they find you\"                   ||"
    echo "  ||                                                                    ||"
    echo "  ========================================================================"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}  Initializing adversarial test battery...${NC}"
    echo -e "${YELLOW}  Target: ${WHITE}Silni App${NC}"
    echo -e "${YELLOW}  Date: ${WHITE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${YELLOW}  Mode: ${WHITE}${MODE}${NC}"
    echo ""
}

# Print section divider
print_divider() {
    echo -e "${PURPLE}------------------------------------------------------------------------${NC}"
}

# Run a single test suite
run_suite() {
    local suite=$1
    local suite_name="${suite%.dart}"

    echo ""
    echo -e "${BLUE}${BOLD}  [PROSECUTING] ${suite_name}${NC}"
    echo -e "${CYAN}  Running ${suite}...${NC}"

    # Run test and capture output
    local output_file="/tmp/bug_scout_${suite_name}_${TIMESTAMP}.log"
    local start_time=$(date +%s)
    local suite_status="PASSED"
    local suite_bugs=0

    set +e
    flutter test "${TEST_DIR}/${suite}" --reporter expanded 2>&1 | tee "$output_file"
    local exit_code=$?
    set -e

    if [ $exit_code -eq 0 ]; then
        suite_status="PASSED"
        echo -e "${GREEN}  [PASSED] ${suite_name}${NC}"
    else
        suite_status="FAILED"
        echo -e "${RED}  [FAILED] ${suite_name}${NC}"
    fi

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))

    # Parse test output for statistics
    local passed=0
    local failed=0
    local skipped=0

    # Try to extract counts from test output
    passed=$(grep -c "^    ✓" "$output_file" 2>/dev/null || true)
    if [ -z "$passed" ]; then passed=0; fi

    failed=$(grep -c "^    ✗" "$output_file" 2>/dev/null || true)
    if [ -z "$failed" ]; then failed=0; fi

    skipped=$(grep -c "^    ○" "$output_file" 2>/dev/null || true)
    if [ -z "$skipped" ]; then skipped=0; fi

    # Try alternate patterns if primary didn't work
    if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ]; then
        # Look for summary line like "All tests passed!" or "X tests passed"
        local summary_passed=$(grep -oE "[0-9]+ tests? passed" "$output_file" 2>/dev/null | head -1 | grep -oE "^[0-9]+" || true)
        if [ -n "$summary_passed" ]; then
            passed=$summary_passed
        fi

        local summary_failed=$(grep -oE "[0-9]+ tests? failed" "$output_file" 2>/dev/null | head -1 | grep -oE "^[0-9]+" || true)
        if [ -n "$summary_failed" ]; then
            failed=$summary_failed
        fi
    fi

    # If still no counts, check if tests ran at all
    if [ "$passed" -eq 0 ] && [ "$failed" -eq 0 ] && [ "$suite_status" = "PASSED" ]; then
        # Count test lines - look for lines that indicate test execution
        passed=$(grep -c "✓\|passed\|PASS" "$output_file" 2>/dev/null || echo "0")
    fi

    suite_bugs=$failed

    # Update totals
    TOTAL_PASSED=$((TOTAL_PASSED + passed))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))
    TOTAL_SKIPPED=$((TOTAL_SKIPPED + skipped))
    TOTAL_BUGS=$((TOTAL_BUGS + failed))

    # Store result for later
    echo "${suite}|${suite_status}|${suite_bugs}" >> "$RESULTS_FILE"

    # Add to report
    echo "" >> "$REPORT_FILE"
    echo "### ${suite_name}" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **Status:** ${suite_status}" >> "$REPORT_FILE"
    echo "- **Duration:** ${duration}s" >> "$REPORT_FILE"
    echo "- **Tests Passed:** ${passed}" >> "$REPORT_FILE"
    echo "- **Tests Failed:** ${failed}" >> "$REPORT_FILE"
    echo "- **Tests Skipped:** ${skipped}" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ "${suite_status}" = "FAILED" ]; then
        echo "<details>" >> "$REPORT_FILE"
        echo "<summary>Error Details</summary>" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo '```' >> "$REPORT_FILE"
        # Extract failure details
        grep -A 20 "FAILED\|Error\|Exception" "$output_file" 2>/dev/null | head -50 >> "$REPORT_FILE" || true
        echo '```' >> "$REPORT_FILE"
        echo "</details>" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
}

# Print final verdict
print_verdict() {
    echo ""
    print_divider
    echo ""

    if [ $TOTAL_BUGS -eq 0 ]; then
        echo -e "${GREEN}${BOLD}"
        echo "  ========================================================================"
        echo "  ||                                                                    ||"
        echo "  ||   ___ _   _ _   _  ___   ____ _____ _   _ _____                   ||"
        echo "  ||  |_ _| \ | | \ | |/ _ \ / ___| ____| \ | |_   _|                  ||"
        echo "  ||   | ||  \| |  \| | | | | |   |  _| |  \| | | |                    ||"
        echo "  ||   | || |\  | |\  | |_| | |___| |___| |\  | | |                    ||"
        echo "  ||  |___|_| \_|_| \_|\___/ \____|_____|_| \_| |_|                    ||"
        echo "  ||                                                                    ||"
        echo "  ||              The code has been found INNOCENT!                     ||"
        echo "  ||                   All tests passed.                                ||"
        echo "  ||                                                                    ||"
        echo "  ========================================================================"
        echo -e "${NC}"
        VERDICT="INNOCENT"
    else
        echo -e "${RED}${BOLD}"
        echo "  ========================================================================"
        echo "  ||                                                                    ||"
        echo "  ||    ____ _   _ ___ _   _______ __   __                             ||"
        echo "  ||   / ___| | | |_ _| | |_   _\ \  / /                               ||"
        echo "  ||  | |  _| | | || || |   | |  \ \/ /                                ||"
        echo "  ||  | |_| | |_| || || |___| |   |  |                                 ||"
        echo "  ||   \____|\___/|___|_____|_|   |__|                                 ||"
        echo "  ||                                                                    ||"
        echo "  ||            The code has been found GUILTY!                         ||"
        echo "  ||              ${TOTAL_BUGS} bug(s) discovered.                                  ||"
        echo "  ||                                                                    ||"
        echo "  ========================================================================"
        echo -e "${NC}"
        VERDICT="GUILTY"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}  SUMMARY${NC}"
    echo -e "${WHITE}  -----------------------------------------${NC}"
    echo -e "${GREEN}  Passed:  ${TOTAL_PASSED}${NC}"
    echo -e "${RED}  Failed:  ${TOTAL_FAILED}${NC}"
    echo -e "${YELLOW}  Skipped: ${TOTAL_SKIPPED}${NC}"
    echo ""
    echo -e "${WHITE}  Full report saved to: ${BLUE}${REPORT_FILE}${NC}"
    echo ""
}

# Initialize report
init_report() {
    mkdir -p "$REPORT_DIR"
    rm -f "$RESULTS_FILE"
    touch "$RESULTS_FILE"

    cat > "$REPORT_FILE" << EOF
# Bug Scout Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Mode:** ${MODE}
**Project:** Silni App

---

## Executive Summary

This report contains the results of running adversarial tests against the codebase.
These tests are designed to find edge cases, security vulnerabilities, and stability issues.

---

## Test Results

EOF
}

# Finalize report
finalize_report() {
    cat >> "$REPORT_FILE" << EOF

---

## Final Verdict

**${VERDICT}**

### Statistics

| Metric | Count |
|--------|-------|
| Tests Passed | ${TOTAL_PASSED} |
| Tests Failed | ${TOTAL_FAILED} |
| Tests Skipped | ${TOTAL_SKIPPED} |
| **Total Bugs Found** | **${TOTAL_BUGS}** |

### Suite Breakdown

| Suite | Status | Bugs Found |
|-------|--------|------------|
EOF

    # Read results from file and add to report
    while IFS='|' read -r suite status bugs; do
        if [ -n "$suite" ]; then
            suite_name="${suite%.dart}"
            echo "| ${suite_name} | ${status} | ${bugs} |" >> "$REPORT_FILE"
        fi
    done < "$RESULTS_FILE"

    cat >> "$REPORT_FILE" << EOF

---

*Report generated by Bug Scout - The Prosecutor*
*"Finding bugs before they find you"*
EOF

    # Cleanup
    rm -f "$RESULTS_FILE"
}

# Main execution
main() {
    # Parse arguments
    MODE="Full Adversarial Battery"
    SUITES="$ALL_SUITES"

    if [ "$1" = "--quick" ]; then
        MODE="Quick (Fuzz + Security)"
        SUITES="$QUICK_SUITES"
    fi

    print_header
    init_report

    print_divider
    echo -e "${YELLOW}${BOLD}  COMMENCING PROSECUTION...${NC}"
    print_divider

    for suite in $SUITES; do
        run_suite "$suite"
    done

    finalize_report
    print_verdict

    # Exit with appropriate code
    if [ $TOTAL_BUGS -gt 0 ]; then
        exit 1
    fi
    exit 0
}

# Run main
main "$@"
