#!/bin/bash

# Environment Switching Script for Silni App
# Usage: ./scripts/switch-env.sh [staging|production]

set -e

ENV=$1
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CURRENT_BRANCH=$(git -C "$PROJECT_ROOT" branch --show-current)

if [ -z "$ENV" ]; then
    echo "Usage: ./scripts/switch-env.sh [staging|production]"
    echo ""
    echo "Current environment:"
    grep "APP_ENV=" "$PROJECT_ROOT/.env" 2>/dev/null | head -1 || echo "APP_ENV not set"
    echo ""
    echo "Current branch: $CURRENT_BRANCH"
    exit 1
fi

if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
    echo "Error: Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

# Safety check: warn if switching to production on non-main branch
if [ "$ENV" == "production" ] && [ "$CURRENT_BRANCH" != "main" ]; then
    echo "⚠️  WARNING: You're switching to PRODUCTION on branch '$CURRENT_BRANCH'"
    echo "   Production builds should typically be done on 'main' branch."
    echo ""
    read -p "Are you sure you want to continue? (y/N): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "Cancelled."
        exit 1
    fi
fi

echo "Switching to $ENV environment..."

# Copy the appropriate env file
if [ ! -f "$PROJECT_ROOT/.env.$ENV" ]; then
    echo "Error: .env.$ENV file not found"
    echo "Please create it first based on .env.example"
    exit 1
fi

cp "$PROJECT_ROOT/.env.$ENV" "$PROJECT_ROOT/.env"

# Update the generated env file
if [ "$ENV" == "staging" ]; then
    cat > "$PROJECT_ROOT/lib/core/config/env/env.g.dart" << 'EOF'
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env
final class _Env {
  static const String appEnv = 'staging';

  static const String environment = 'development';

  static const String isTestFlight = 'false';
}
EOF
    echo "✓ Switched to STAGING (dqqyhmydodjpqboykzow)"
else
    cat > "$PROJECT_ROOT/lib/core/config/env/env.g.dart" << 'EOF'
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// generated_from: .env
final class _Env {
  static const String appEnv = 'production';

  static const String environment = 'production';

  static const String isTestFlight = 'false';
}
EOF
    echo "✓ Switched to PRODUCTION (bapwklwxmwhpucutyras)"
fi

echo ""
echo "Branch: $CURRENT_BRANCH"
echo "Remember to restart your app or run 'flutter run' again."
