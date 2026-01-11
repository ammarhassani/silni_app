#!/bin/bash

# Switch between staging/production
# Usage: ./scripts/switch-env.sh [staging|production]

set -e

ENV=$1
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "$ENV" ]; then
    echo "Current: $(grep 'APP_ENV=' "$PROJECT_ROOT/.env" | cut -d'=' -f2)"
    exit 0
fi

if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
    echo "Error: Use 'staging' or 'production'"
    exit 1
fi

# Update APP_ENV in .env
sed -i '' "s/^APP_ENV=.*/APP_ENV=$ENV/" "$PROJECT_ROOT/.env"

# Update ENVIRONMENT
if [ "$ENV" == "staging" ]; then
    sed -i '' "s/^ENVIRONMENT=.*/ENVIRONMENT=development/" "$PROJECT_ROOT/.env"
    cat > "$PROJECT_ROOT/lib/core/config/env/env.g.dart" << 'EOF'
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _Env {
  static const String appEnv = 'staging';
  static const String environment = 'development';
  static const String isTestFlight = 'false';
}
EOF
    echo "✓ Switched to STAGING"
else
    sed -i '' "s/^ENVIRONMENT=.*/ENVIRONMENT=production/" "$PROJECT_ROOT/.env"
    cat > "$PROJECT_ROOT/lib/core/config/env/env.g.dart" << 'EOF'
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'env.dart';

// **************************************************************************
// EnviedGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _Env {
  static const String appEnv = 'production';
  static const String environment = 'production';
  static const String isTestFlight = 'false';
}
EOF
    echo "✓ Switched to PRODUCTION"
fi
