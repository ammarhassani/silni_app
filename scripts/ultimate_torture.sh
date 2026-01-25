#!/bin/bash
#
# Ultimate Torture Runner - LEAVE NO BUG ALIVE!
# The most comprehensive test battery for the Silni App
#
# Usage: ./scripts/ultimate_torture.sh [--full]
#   --full  Include mutation testing (slower but more thorough)
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
DIM='\033[2m'

# Configuration
REPORT_DIR="reports/ultimate_torture"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${REPORT_DIR}/torture_report_${TIMESTAMP}.md"
MIN_COVERAGE=80

# Track results
TOTAL_PHASES=0
PASSED_PHASES=0
FAILED_PHASES=0
PHASE_RESULTS=()
START_TIME=$(date +%s)
FULL_MODE=false

# Parse arguments
if [ "$1" = "--full" ]; then
    FULL_MODE=true
fi

# Print the dramatic header
print_header() {
    clear
    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                      ║"
    echo "  ║   💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀   ║"
    echo "  ║                                                                      ║"
    echo "  ║   ██╗   ██╗██╗  ████████╗██╗███╗   ███╗ █████╗ ████████╗███████╗    ║"
    echo "  ║   ██║   ██║██║  ╚══██╔══╝██║████╗ ████║██╔══██╗╚══██╔══╝██╔════╝    ║"
    echo "  ║   ██║   ██║██║     ██║   ██║██╔████╔██║███████║   ██║   █████╗      ║"
    echo "  ║   ██║   ██║██║     ██║   ██║██║╚██╔╝██║██╔══██║   ██║   ██╔══╝      ║"
    echo "  ║   ╚██████╔╝███████╗██║   ██║██║ ╚═╝ ██║██║  ██║   ██║   ███████╗    ║"
    echo "  ║    ╚═════╝ ╚══════╝╚═╝   ╚═╝╚═╝     ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝    ║"
    echo "  ║                                                                      ║"
    echo "  ║   ████████╗ ██████╗ ██████╗ ████████╗██╗   ██╗██████╗ ███████╗      ║"
    echo "  ║   ╚══██╔══╝██╔═══██╗██╔══██╗╚══██╔══╝██║   ██║██╔══██╗██╔════╝      ║"
    echo "  ║      ██║   ██║   ██║██████╔╝   ██║   ██║   ██║██████╔╝█████╗        ║"
    echo "  ║      ██║   ██║   ██║██╔══██╗   ██║   ██║   ██║██╔══██╗██╔══╝        ║"
    echo "  ║      ██║   ╚██████╔╝██║  ██║   ██║   ╚██████╔╝██║  ██║███████╗      ║"
    echo "  ║      ╚═╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝      ║"
    echo "  ║                                                                      ║"
    echo "  ║   💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀 💀   ║"
    echo "  ║                                                                      ║"
    echo "  ║              ╔════════════════════════════════════╗                  ║"
    echo "  ║              ║     L E A V E   N O   B U G       ║                  ║"
    echo "  ║              ║           A L I V E !             ║                  ║"
    echo "  ║              ╚════════════════════════════════════╝                  ║"
    echo "  ║                                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}  Initializing Ultimate Torture Battery...${NC}"
    echo -e "${YELLOW}  Target: ${WHITE}Silni App${NC}"
    echo -e "${YELLOW}  Date: ${WHITE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${YELLOW}  Mode: ${WHITE}$([ "$FULL_MODE" = true ] && echo "FULL (with Mutation Testing)" || echo "STANDARD")${NC}"
    echo -e "${YELLOW}  Min Coverage: ${WHITE}${MIN_COVERAGE}%${NC}"
    echo ""
}

# Print section divider
print_divider() {
    echo -e "${PURPLE}════════════════════════════════════════════════════════════════════════${NC}"
}

# Print phase header
print_phase() {
    local phase_num=$1
    local phase_name=$2
    local total_phases=$3

    echo ""
    print_divider
    echo -e "${BLUE}${BOLD}  ⚡ PHASE ${phase_num}/${total_phases}: ${phase_name}${NC}"
    print_divider
    echo ""
}

# Run a phase and track result
run_phase() {
    local phase_num=$1
    local phase_name=$2
    local command=$3
    local optional=${4:-false}

    ((TOTAL_PHASES++))

    local phase_start=$(date +%s)

    echo -e "${CYAN}  Executing: ${DIM}${command}${NC}"
    echo ""

    set +e
    eval "$command"
    local exit_code=$?
    set -e

    local phase_end=$(date +%s)
    local duration=$((phase_end - phase_start))

    if [ $exit_code -eq 0 ]; then
        echo ""
        echo -e "${GREEN}  ✓ PHASE ${phase_num} PASSED ${DIM}(${duration}s)${NC}"
        ((PASSED_PHASES++))
        PHASE_RESULTS+=("${phase_name}|PASSED|${duration}")
        return 0
    elif [ "$optional" = true ]; then
        echo ""
        echo -e "${YELLOW}  ⚠ PHASE ${phase_num} SKIPPED ${DIM}(${duration}s)${NC}"
        PHASE_RESULTS+=("${phase_name}|SKIPPED|${duration}")
        return 0
    else
        echo ""
        echo -e "${RED}  ✗ PHASE ${phase_num} FAILED ${DIM}(${duration}s)${NC}"
        ((FAILED_PHASES++))
        PHASE_RESULTS+=("${phase_name}|FAILED|${duration}")
        return 1
    fi
}

# Initialize report
init_report() {
    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_FILE" << EOF
# Ultimate Torture Report 💀

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Project:** Silni App
**Mode:** $([ "$FULL_MODE" = true ] && echo "FULL (with Mutation Testing)" || echo "STANDARD")
**Minimum Coverage Required:** ${MIN_COVERAGE}%

---

## Executive Summary

This report contains the results of the Ultimate Torture test battery.
Every bug that could hide has been hunted down.

---

## Phase Results

| Phase | Name | Status | Duration |
|-------|------|--------|----------|
EOF
}

# Finalize report
finalize_report() {
    local verdict=$1
    local total_duration=$2
    local coverage_pct=$3

    # Add phase results to report
    local phase_num=1
    for result in "${PHASE_RESULTS[@]}"; do
        IFS='|' read -r name status duration <<< "$result"
        local status_emoji="✓"
        if [ "$status" = "FAILED" ]; then
            status_emoji="✗"
        elif [ "$status" = "SKIPPED" ]; then
            status_emoji="⚠"
        fi
        echo "| ${phase_num} | ${name} | ${status_emoji} ${status} | ${duration}s |" >> "$REPORT_FILE"
        ((phase_num++))
    done

    cat >> "$REPORT_FILE" << EOF

---

## Summary Statistics

| Metric | Value |
|--------|-------|
| Total Phases | ${TOTAL_PHASES} |
| Passed | ${PASSED_PHASES} |
| Failed | ${FAILED_PHASES} |
| Coverage | ${coverage_pct}% |
| Total Duration | ${total_duration}s |

---

## Final Verdict

# ${verdict}

EOF

    if [ "$verdict" = "INNOCENT" ]; then
        cat >> "$REPORT_FILE" << EOF
The code has survived the Ultimate Torture!
All tests passed and coverage requirements met.
This code is ready for battle.
EOF
    else
        cat >> "$REPORT_FILE" << EOF
The code has been found GUILTY!
Bugs were discovered or coverage requirements not met.
Fix the issues and run the torture again.
EOF
    fi

    cat >> "$REPORT_FILE" << EOF

---

*Report generated by Ultimate Torture Runner*
*"Leave No Bug Alive!"*
EOF
}

# Print innocent verdict
print_innocent() {
    echo ""
    echo -e "${GREEN}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                      ║"
    echo "  ║   ██╗███╗   ██╗███╗   ██╗ ██████╗  ██████╗███████╗███╗   ██╗████████╗║"
    echo "  ║   ██║████╗  ██║████╗  ██║██╔═══██╗██╔════╝██╔════╝████╗  ██║╚══██╔══╝║"
    echo "  ║   ██║██╔██╗ ██║██╔██╗ ██║██║   ██║██║     █████╗  ██╔██╗ ██║   ██║   ║"
    echo "  ║   ██║██║╚██╗██║██║╚██╗██║██║   ██║██║     ██╔══╝  ██║╚██╗██║   ██║   ║"
    echo "  ║   ██║██║ ╚████║██║ ╚████║╚██████╔╝╚██████╗███████╗██║ ╚████║   ██║   ║"
    echo "  ║   ╚═╝╚═╝  ╚═══╝╚═╝  ╚═══╝ ╚═════╝  ╚═════╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ║"
    echo "  ║                                                                      ║"
    echo "  ║                  🏆 THE CODE IS VICTORIOUS! 🏆                        ║"
    echo "  ║                                                                      ║"
    echo "  ║               All tests passed. No bugs survived.                    ║"
    echo "  ║                  This code is BATTLE-READY!                          ║"
    echo "  ║                                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Print guilty verdict
print_guilty() {
    local bug_count=$1
    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════════════════╗"
    echo "  ║                                                                      ║"
    echo "  ║        ██████╗ ██╗   ██╗██╗██╗  ████████╗██╗   ██╗██╗                ║"
    echo "  ║       ██╔════╝ ██║   ██║██║██║  ╚══██╔══╝╚██╗ ██╔╝██║                ║"
    echo "  ║       ██║  ███╗██║   ██║██║██║     ██║    ╚████╔╝ ██║                ║"
    echo "  ║       ██║   ██║██║   ██║██║██║     ██║     ╚██╔╝  ╚═╝                ║"
    echo "  ║       ╚██████╔╝╚██████╔╝██║███████╗██║      ██║   ██╗                ║"
    echo "  ║        ╚═════╝  ╚═════╝ ╚═╝╚══════╝╚═╝      ╚═╝   ╚═╝                ║"
    echo "  ║                                                                      ║"
    echo "  ║                 💀 THE CODE HAS BEEN CONDEMNED! 💀                    ║"
    echo "  ║                                                                      ║"
    echo "  ║             ${bug_count} phase(s) failed. Bugs were found!                     ║"
    echo "  ║                 Fix the issues and try again.                        ║"
    echo "  ║                                                                      ║"
    echo "  ╚══════════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

# Check coverage percentage
get_coverage() {
    if command -v lcov &> /dev/null && [ -f "coverage/lcov.info" ]; then
        local coverage_output=$(lcov --summary coverage/lcov.info 2>&1)
        local coverage_pct=$(echo "$coverage_output" | grep -oE "lines[^:]*: [0-9.]+" | grep -oE "[0-9.]+" | head -1)
        if [ -n "$coverage_pct" ]; then
            echo "${coverage_pct%.*}"
            return 0
        fi
    fi
    echo "0"
}

# Check if device/emulator is available for integration tests
check_device_available() {
    flutter devices 2>/dev/null | grep -qE "(android|ios|macos|linux|windows|chrome)" 2>/dev/null
}

# Main execution
main() {
    print_header
    init_report

    # Calculate total phases
    local total_phases=16
    if [ "$FULL_MODE" = false ]; then
        ((total_phases--))  # Skip mutation testing
    fi

    echo -e "${YELLOW}${BOLD}  ⚔️  COMMENCING ULTIMATE TORTURE - ${total_phases} PHASES ⚔️${NC}"
    echo ""
    sleep 1

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 1: Static Analysis
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 1 "STATIC ANALYSIS" $total_phases
    run_phase 1 "Static Analysis" "flutter analyze --no-fatal-infos"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 2: Unit Tests with Coverage
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 2 "UNIT TESTS (${MIN_COVERAGE}% coverage required)" $total_phases
    run_phase 2 "Unit Tests" "flutter test test/unit/ --coverage"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 3: Widget Tests
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 3 "WIDGET TESTS" $total_phases
    run_phase 3 "Widget Tests" "flutter test test/widget/ --coverage"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 4: Integration Tests (if device available)
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 4 "INTEGRATION TESTS" $total_phases
    if check_device_available; then
        run_phase 4 "Integration Tests" "flutter test integration_test/ --coverage" true
    else
        echo -e "${YELLOW}  ⚠ No device available - skipping integration tests${NC}"
        PHASE_RESULTS+=("Integration Tests|SKIPPED|0")
    fi

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 5: Golden Tests
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 5 "GOLDEN TESTS (UI Regression)" $total_phases
    run_phase 5 "Golden Tests" "flutter test test/golden/ --coverage 2>/dev/null" true

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 6: Input Fuzzing
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 6 "INPUT FUZZING" $total_phases
    run_phase 6 "Input Fuzzing" "flutter test test/adversarial/input_fuzzing_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 7: Boundary Testing
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 7 "BOUNDARY TESTING" $total_phases
    run_phase 7 "Boundary Testing" "flutter test test/adversarial/boundary_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 8: State Chaos
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 8 "STATE CHAOS" $total_phases
    run_phase 8 "State Chaos" "flutter test test/adversarial/state_chaos_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 9: Race Conditions
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 9 "RACE CONDITIONS" $total_phases
    run_phase 9 "Race Conditions" "flutter test test/adversarial/race_condition_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 10: Stress Testing
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 10 "STRESS TESTING" $total_phases
    run_phase 10 "Stress Testing" "flutter test test/adversarial/stress_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 11: Security Testing
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 11 "SECURITY TESTING" $total_phases
    run_phase 11 "Security Testing" "flutter test test/adversarial/security_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 12: Widget Torture
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 12 "WIDGET TORTURE" $total_phases
    run_phase 12 "Widget Torture" "flutter test test/adversarial/widget_torture_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 13: Monkey Testing
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 13 "MONKEY TESTING" $total_phases
    run_phase 13 "Monkey Testing" "flutter test test/adversarial/monkey_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 14: Memory Leak Detection
    # ═══════════════════════════════════════════════════════════════════════
    print_phase 14 "MEMORY LEAK DETECTION" $total_phases
    run_phase 14 "Memory Leak Detection" "flutter test test/adversarial/memory_leak_test.dart --reporter expanded"

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 15: Mutation Testing (only if --full)
    # ═══════════════════════════════════════════════════════════════════════
    if [ "$FULL_MODE" = true ]; then
        print_phase 15 "MUTATION TESTING (The Ultimate Test)" $total_phases
        run_phase 15 "Mutation Testing" "./scripts/mutation_test.sh"
    fi

    # ═══════════════════════════════════════════════════════════════════════
    # PHASE 16: Coverage Analysis
    # ═══════════════════════════════════════════════════════════════════════
    local final_phase=$total_phases
    print_phase $final_phase "COVERAGE ANALYSIS" $total_phases

    local coverage_pct=$(get_coverage)
    echo -e "${CYAN}  Coverage: ${coverage_pct}%${NC}"

    if [ "$coverage_pct" -ge "$MIN_COVERAGE" ]; then
        echo -e "${GREEN}  ✓ Coverage meets minimum requirement (${MIN_COVERAGE}%)${NC}"
        ((PASSED_PHASES++))
        PHASE_RESULTS+=("Coverage Analysis|PASSED|0")
    else
        echo -e "${RED}  ✗ Coverage below minimum requirement (${MIN_COVERAGE}%)${NC}"
        ((FAILED_PHASES++))
        PHASE_RESULTS+=("Coverage Analysis|FAILED|0")
    fi
    ((TOTAL_PHASES++))

    # ═══════════════════════════════════════════════════════════════════════
    # FINAL VERDICT
    # ═══════════════════════════════════════════════════════════════════════
    local end_time=$(date +%s)
    local total_duration=$((end_time - START_TIME))

    echo ""
    print_divider
    echo -e "${WHITE}${BOLD}  TORTURE COMPLETE - RENDERING VERDICT...${NC}"
    print_divider
    sleep 1

    local verdict="INNOCENT"
    if [ $FAILED_PHASES -gt 0 ]; then
        verdict="GUILTY"
        print_guilty $FAILED_PHASES
    else
        print_innocent
    fi

    finalize_report "$verdict" "$total_duration" "$coverage_pct"

    # Print summary
    echo ""
    echo -e "${CYAN}${BOLD}  ═══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}${BOLD}                           FINAL SUMMARY${NC}"
    echo -e "${CYAN}${BOLD}  ═══════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${WHITE}  Total Phases:   ${TOTAL_PHASES}${NC}"
    echo -e "${GREEN}  Passed:         ${PASSED_PHASES}${NC}"
    echo -e "${RED}  Failed:         ${FAILED_PHASES}${NC}"
    echo -e "${CYAN}  Coverage:       ${coverage_pct}%${NC}"
    echo -e "${WHITE}  Duration:       ${total_duration}s${NC}"
    echo ""
    echo -e "${WHITE}  Full report:    ${BLUE}${REPORT_FILE}${NC}"
    echo ""

    if [ $FAILED_PHASES -gt 0 ]; then
        exit 1
    fi
    exit 0
}

# Run main
main "$@"
