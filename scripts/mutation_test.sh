#!/bin/bash
#
# Mutation Testing - Kill Every Mutant!
# Tests the QUALITY of your tests by injecting bugs and seeing if they catch them
#
# Usage: ./scripts/mutation_test.sh
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
REPORT_DIR="reports/mutation"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
REPORT_FILE="${REPORT_DIR}/mutation_report_${TIMESTAMP}.md"
MIN_KILL_RATE=70

# Critical services to test - these are the ones we MUST have good tests for
MUTATION_TARGETS=(
    "lib/core/services/gamification_service.dart"
    "lib/core/services/sync_service.dart"
    "lib/core/services/offline_queue_service.dart"
    "lib/shared/repositories/relatives_repository.dart"
    "lib/shared/repositories/interactions_repository.dart"
)

# Track statistics
TOTAL_MUTANTS=0
KILLED_MUTANTS=0
SURVIVED_MUTANTS=0

# Print dramatic header
print_header() {
    echo ""
    echo -e "${RED}${BOLD}"
    echo "  ========================================================================"
    echo "  ||                                                                    ||"
    echo "  ||   _  _____ _     _       _______     _______ ______   __           ||"
    echo "  ||  | |/ /_ _| |   | |     | ____\ \   / / ____|  _ \ \ / /           ||"
    echo "  ||  | ' / | || |   | |     |  _|  \ \ / /|  _| | |_) \ V /            ||"
    echo "  ||  | . \ | || |___| |___  | |___  \ V / | |___|  _ < | |             ||"
    echo "  ||  |_|\_\___|_____|_____| |_____|  \_/  |_____|_| \_\|_|             ||"
    echo "  ||                                                                    ||"
    echo "  ||              __  __ _   _ _____  _    _   _ _____                  ||"
    echo "  ||             |  \/  | | | |_   _|/ \  | \ | |_   _|                 ||"
    echo "  ||             | |\/| | | | | | | / _ \ |  \| | | |                   ||"
    echo "  ||             | |  | | |_| | | |/ ___ \| |\  | | |                   ||"
    echo "  ||             |_|  |_|\___/  |_/_/   \_\_| \_| |_|                   ||"
    echo "  ||                                                                    ||"
    echo "  ||               MUTATION TESTING - THE ULTIMATE TEST                 ||"
    echo "  ||            \"If your tests don't catch the mutant, they're weak\"    ||"
    echo "  ||                                                                    ||"
    echo "  ========================================================================"
    echo -e "${NC}"
    echo ""
    echo -e "${CYAN}${BOLD}  Initializing mutation testing battery...${NC}"
    echo -e "${YELLOW}  Target: ${WHITE}Critical Services${NC}"
    echo -e "${YELLOW}  Date: ${WHITE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${YELLOW}  Minimum Kill Rate: ${WHITE}${MIN_KILL_RATE}%${NC}"
    echo ""
}

# Print section divider
print_divider() {
    echo -e "${PURPLE}------------------------------------------------------------------------${NC}"
}

# Mutation operators
# Each function takes a file and applies a specific mutation

# Mutation 1: Change == to !=
mutate_equality() {
    local file=$1
    sed -i.mutation_bak 's/==/!=/g' "$file"
}

# Mutation 2: Change > to <
mutate_greater_than() {
    local file=$1
    sed -i.mutation_bak 's/>/</g' "$file"
}

# Mutation 3: Change + to -
mutate_addition() {
    local file=$1
    # Be careful to not change ++ or +=
    sed -i.mutation_bak 's/\([^+]\)+\([^+=]\)/\1-\2/g' "$file"
}

# Mutation 4: Change true to false
mutate_true_false() {
    local file=$1
    sed -i.mutation_bak 's/\btrue\b/false/g' "$file"
}

# Mutation 5: Remove return statements (replace with empty return or nothing)
mutate_return() {
    local file=$1
    # Replace 'return xxx;' with 'return null;' for nullable returns
    # or just comment out the return for void functions
    sed -i.mutation_bak 's/return [^;]*;/\/\/ MUTANT: return removed/g' "$file"
}

# Array of mutation functions and their names
MUTATION_OPERATORS=(
    "mutate_equality:Change == to !="
    "mutate_greater_than:Change > to <"
    "mutate_addition:Change + to -"
    "mutate_true_false:Change true to false"
    "mutate_return:Remove return statements"
)

# Run tests and return 0 if tests fail (mutant killed), 1 if tests pass (mutant survived)
run_tests() {
    local target_file=$1
    local test_output="/tmp/mutation_test_output_${TIMESTAMP}.log"

    # Determine test file path based on source file
    local test_file=""
    if [[ "$target_file" == *"services/"* ]]; then
        local service_name=$(basename "$target_file" .dart)
        test_file="test/unit/services/${service_name}_test.dart"
    elif [[ "$target_file" == *"repositories/"* ]]; then
        local repo_name=$(basename "$target_file" .dart)
        test_file="test/unit/repositories/${repo_name}_test.dart"
    fi

    # Run the specific test file if it exists, otherwise run all unit tests
    set +e
    if [ -f "$test_file" ]; then
        flutter test "$test_file" > "$test_output" 2>&1
    else
        flutter test test/unit/ > "$test_output" 2>&1
    fi
    local exit_code=$?
    set -e

    rm -f "$test_output"

    # If tests fail (exit_code != 0), mutant was killed
    if [ $exit_code -ne 0 ]; then
        return 0  # Killed
    else
        return 1  # Survived
    fi
}

# Apply mutation and test
apply_mutation() {
    local file=$1
    local mutation_func=$2
    local mutation_name=$3

    # Create backup
    cp "$file" "${file}.bak"

    # Apply mutation
    $mutation_func "$file"

    # Check if file was actually mutated
    if diff -q "$file" "${file}.bak" > /dev/null 2>&1; then
        # No change was made, skip this mutation
        mv "${file}.bak" "$file"
        rm -f "${file}.mutation_bak"
        return 2  # Skipped
    fi

    echo -e "${CYAN}    Applying mutation: ${mutation_name}${NC}"

    # Run tests
    if run_tests "$file"; then
        echo -e "${GREEN}    [KILLED] Mutant was caught by tests${NC}"
        # Restore original
        mv "${file}.bak" "$file"
        rm -f "${file}.mutation_bak"
        return 0  # Killed
    else
        echo -e "${RED}    [SURVIVED] Mutant escaped! Tests need improvement${NC}"
        # Restore original
        mv "${file}.bak" "$file"
        rm -f "${file}.mutation_bak"
        return 1  # Survived
    fi
}

# Process a single target file
process_target() {
    local target=$1
    local target_name=$(basename "$target")

    echo ""
    echo -e "${BLUE}${BOLD}  [MUTATING] ${target_name}${NC}"
    print_divider

    if [ ! -f "$target" ]; then
        echo -e "${YELLOW}    [SKIPPED] File not found: $target${NC}"
        echo "### $(basename $target .dart)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        echo "**Status:** SKIPPED (file not found)" >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
        return
    fi

    local file_mutants=0
    local file_killed=0
    local file_survived=0
    local file_skipped=0

    # Apply each mutation operator
    for mutation_entry in "${MUTATION_OPERATORS[@]}"; do
        local func_name="${mutation_entry%%:*}"
        local mutation_desc="${mutation_entry#*:}"

        local result
        apply_mutation "$target" "$func_name" "$mutation_desc"
        result=$?

        if [ $result -eq 2 ]; then
            ((file_skipped++))
        elif [ $result -eq 0 ]; then
            ((file_mutants++))
            ((file_killed++))
            ((TOTAL_MUTANTS++))
            ((KILLED_MUTANTS++))
        else
            ((file_mutants++))
            ((file_survived++))
            ((TOTAL_MUTANTS++))
            ((SURVIVED_MUTANTS++))
        fi
    done

    # Calculate kill rate for this file
    local kill_rate=0
    if [ $file_mutants -gt 0 ]; then
        kill_rate=$((file_killed * 100 / file_mutants))
    fi

    echo ""
    echo -e "${WHITE}    Results for ${target_name}:${NC}"
    echo -e "${GREEN}      Killed: ${file_killed}${NC}"
    echo -e "${RED}      Survived: ${file_survived}${NC}"
    echo -e "${YELLOW}      Skipped: ${file_skipped}${NC}"
    echo -e "${CYAN}      Kill Rate: ${kill_rate}%${NC}"

    # Add to report
    echo "### $(basename $target .dart)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
    echo "- **File:** \`$target\`" >> "$REPORT_FILE"
    echo "- **Mutants Created:** $file_mutants" >> "$REPORT_FILE"
    echo "- **Mutants Killed:** $file_killed" >> "$REPORT_FILE"
    echo "- **Mutants Survived:** $file_survived" >> "$REPORT_FILE"
    echo "- **Mutations Skipped:** $file_skipped" >> "$REPORT_FILE"
    echo "- **Kill Rate:** ${kill_rate}%" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"

    if [ $file_survived -gt 0 ]; then
        echo "**Warning:** Some mutants survived. Consider adding more tests for this file." >> "$REPORT_FILE"
        echo "" >> "$REPORT_FILE"
    fi
}

# Print final verdict
print_verdict() {
    echo ""
    print_divider
    echo ""

    local kill_rate=0
    if [ $TOTAL_MUTANTS -gt 0 ]; then
        kill_rate=$((KILLED_MUTANTS * 100 / TOTAL_MUTANTS))
    fi

    if [ $kill_rate -ge $MIN_KILL_RATE ]; then
        echo -e "${GREEN}${BOLD}"
        echo "  ========================================================================"
        echo "  ||                                                                    ||"
        echo "  ||    __  __ _   _ _____  _    _   _ _____ ____                       ||"
        echo "  ||   |  \/  | | | |_   _|/ \  | \ | |_   _/ ___|                      ||"
        echo "  ||   | |\/| | | | | | | / _ \ |  \| | | | \___ \                      ||"
        echo "  ||   | |  | | |_| | | |/ ___ \| |\  | | |  ___) |                     ||"
        echo "  ||   |_|  |_|\___/  |_/_/   \_\_| \_| |_| |____/                      ||"
        echo "  ||                                                                    ||"
        echo "  ||              _  _____ _     _     _____ ____                       ||"
        echo "  ||             | |/ /_ _| |   | |   | ____|  _ \                      ||"
        echo "  ||             | ' / | || |   | |   |  _| | | | |                     ||"
        echo "  ||             | . \ | || |___| |___| |___| |_| |                     ||"
        echo "  ||             |_|\_\___|_____|_____|_____|____/                      ||"
        echo "  ||                                                                    ||"
        echo "  ||              Your tests are STRONG! ${kill_rate}% kill rate!                  ||"
        echo "  ||                                                                    ||"
        echo "  ========================================================================"
        echo -e "${NC}"
    else
        echo -e "${RED}${BOLD}"
        echo "  ========================================================================"
        echo "  ||                                                                    ||"
        echo "  ||   __  __ _   _ _____  _    _   _ _____ ____                        ||"
        echo "  ||  |  \/  | | | |_   _|/ \  | \ | |_   _/ ___|                       ||"
        echo "  ||  | |\/| | | | | | | / _ \ |  \| | | | \___ \                       ||"
        echo "  ||  | |  | | |_| | | |/ ___ \| |\  | | |  ___) |                      ||"
        echo "  ||  |_|  |_|\___/  |_/_/   \_\_| \_| |_| |____/                       ||"
        echo "  ||                                                                    ||"
        echo "  ||   ____  _   _ ______     _____     _______ ____                    ||"
        echo "  ||  / ___|| | | |  _ \ \   / /_ _|   / / ____|  _ \                   ||"
        echo "  ||  \___ \| | | | |_) \ \ / / | |   / /|  _| | | | |                  ||"
        echo "  ||   ___) | |_| |  _ < \ V /  | |  / / | |___| |_| |                  ||"
        echo "  ||  |____/ \___/|_| \_\ \_/  |___|/_/  |_____|____/                   ||"
        echo "  ||                                                                    ||"
        echo "  ||       Your tests are WEAK! Only ${kill_rate}% kill rate!                   ||"
        echo "  ||            Mutants are escaping! Improve your tests!               ||"
        echo "  ||                                                                    ||"
        echo "  ========================================================================"
        echo -e "${NC}"
    fi

    echo ""
    echo -e "${CYAN}${BOLD}  SUMMARY${NC}"
    echo -e "${WHITE}  -----------------------------------------${NC}"
    echo -e "${WHITE}  Total Mutants Created: ${TOTAL_MUTANTS}${NC}"
    echo -e "${GREEN}  Mutants Killed:        ${KILLED_MUTANTS}${NC}"
    echo -e "${RED}  Mutants Survived:      ${SURVIVED_MUTANTS}${NC}"
    echo -e "${CYAN}${BOLD}  Kill Rate:             ${kill_rate}%${NC}"
    echo -e "${YELLOW}  Minimum Required:      ${MIN_KILL_RATE}%${NC}"
    echo ""
    echo -e "${WHITE}  Full report saved to: ${BLUE}${REPORT_FILE}${NC}"
    echo ""

    return $kill_rate
}

# Initialize report
init_report() {
    mkdir -p "$REPORT_DIR"

    cat > "$REPORT_FILE" << EOF
# Mutation Testing Report

**Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Project:** Silni App
**Minimum Kill Rate Required:** ${MIN_KILL_RATE}%

---

## What is Mutation Testing?

Mutation testing evaluates the **quality** of your tests by:
1. Injecting small bugs (mutations) into your code
2. Running your tests to see if they catch the bugs
3. Calculating a "kill rate" - the percentage of mutants caught

A high kill rate means your tests are effective at catching bugs.

---

## Mutation Operators Used

| Operator | Description |
|----------|-------------|
| Equality | Change \`==\` to \`!=\` |
| Comparison | Change \`>\` to \`<\` |
| Arithmetic | Change \`+\` to \`-\` |
| Boolean | Change \`true\` to \`false\` |
| Return | Remove return statements |

---

## Results by File

EOF
}

# Finalize report
finalize_report() {
    local kill_rate=0
    if [ $TOTAL_MUTANTS -gt 0 ]; then
        kill_rate=$((KILLED_MUTANTS * 100 / TOTAL_MUTANTS))
    fi

    local verdict="PASS"
    if [ $kill_rate -lt $MIN_KILL_RATE ]; then
        verdict="FAIL"
    fi

    cat >> "$REPORT_FILE" << EOF

---

## Final Summary

| Metric | Value |
|--------|-------|
| Total Mutants Created | ${TOTAL_MUTANTS} |
| Mutants Killed | ${KILLED_MUTANTS} |
| Mutants Survived | ${SURVIVED_MUTANTS} |
| **Kill Rate** | **${kill_rate}%** |
| **Minimum Required** | **${MIN_KILL_RATE}%** |
| **Verdict** | **${verdict}** |

---

## Recommendations

EOF

    if [ $SURVIVED_MUTANTS -gt 0 ]; then
        cat >> "$REPORT_FILE" << EOF
- **Add more assertions** to your tests to catch edge cases
- **Test boundary conditions** (especially for comparison operators)
- **Test boolean logic** paths more thoroughly
- **Test return values** to ensure they're what you expect
EOF
    else
        cat >> "$REPORT_FILE" << EOF
- Great job! All mutants were killed.
- Continue adding tests as you add new code.
EOF
    fi

    cat >> "$REPORT_FILE" << EOF

---

*Report generated by Mutation Testing - Kill Every Mutant!*
*"If your tests don't catch the mutant, they're weak"*
EOF
}

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up backup files...${NC}"
    for target in "${MUTATION_TARGETS[@]}"; do
        rm -f "${target}.bak"
        rm -f "${target}.mutation_bak"
    done
}

# Set trap to ensure cleanup on exit
trap cleanup EXIT

# Main execution
main() {
    print_header
    init_report

    print_divider
    echo -e "${YELLOW}${BOLD}  RELEASING THE MUTANTS...${NC}"
    print_divider

    for target in "${MUTATION_TARGETS[@]}"; do
        process_target "$target"
    done

    finalize_report
    print_verdict
    local kill_rate=$?

    # Return exit code based on kill rate
    if [ $TOTAL_MUTANTS -eq 0 ]; then
        echo -e "${YELLOW}Warning: No mutations were applied. Check if target files exist.${NC}"
        exit 1
    fi

    if [ $kill_rate -lt $MIN_KILL_RATE ]; then
        exit 1
    fi
    exit 0
}

# Run main
main "$@"
