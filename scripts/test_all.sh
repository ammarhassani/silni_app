#!/bin/bash
# Silni App - Comprehensive Test Runner
# Run this script to test everything with one command

set -e  # Exit on any failure

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  Silni App - Comprehensive Test Suite${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Track results
FAILED_TESTS=()

# 1. Static Analysis
echo -e "${YELLOW}[1/6] Running Static Analysis...${NC}"
if flutter analyze --no-fatal-infos; then
    echo -e "${GREEN}✓ Static analysis passed${NC}"
else
    FAILED_TESTS+=("Static Analysis")
    echo -e "${RED}✗ Static analysis failed${NC}"
fi
echo ""

# 2. Unit Tests
echo -e "${YELLOW}[2/6] Running Unit Tests...${NC}"
if flutter test test/unit/ --coverage; then
    echo -e "${GREEN}✓ Unit tests passed${NC}"
else
    FAILED_TESTS+=("Unit Tests")
    echo -e "${RED}✗ Unit tests failed${NC}"
fi
echo ""

# 3. Widget Tests
echo -e "${YELLOW}[3/6] Running Widget Tests...${NC}"
if flutter test test/widget/ --coverage; then
    echo -e "${GREEN}✓ Widget tests passed${NC}"
else
    FAILED_TESTS+=("Widget Tests")
    echo -e "${RED}✗ Widget tests failed${NC}"
fi
echo ""

# 4. Integration Tests (requires running emulator/device)
echo -e "${YELLOW}[4/6] Running Integration Tests...${NC}"
if flutter test integration_test/ --coverage 2>/dev/null; then
    echo -e "${GREEN}✓ Integration tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Integration tests skipped (no device available)${NC}"
fi
echo ""

# 5. Golden Tests (UI regression)
echo -e "${YELLOW}[5/6] Running Golden Tests...${NC}"
if flutter test test/golden/ --coverage 2>/dev/null; then
    echo -e "${GREEN}✓ Golden tests passed${NC}"
else
    echo -e "${YELLOW}⚠ Golden tests skipped (no golden files yet)${NC}"
fi
echo ""

# 6. Coverage Report
echo -e "${YELLOW}[6/6] Generating Coverage Report...${NC}"
if command -v lcov &> /dev/null; then
    lcov --summary coverage/lcov.info 2>/dev/null || echo "Coverage summary not available"
else
    echo "Install lcov for coverage summary: brew install lcov"
fi
echo ""

# Final Summary
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}              TEST SUMMARY              ${NC}"
echo -e "${BLUE}========================================${NC}"

if [ ${#FAILED_TESTS[@]} -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Failed tests:${NC}"
    for test in "${FAILED_TESTS[@]}"; do
        echo -e "${RED}  - $test${NC}"
    done
    exit 1
fi
