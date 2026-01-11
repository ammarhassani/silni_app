#!/bin/bash

# Environment Switching Script for Silni App
# Usage: ./scripts/switch-env.sh [staging|production]

set -e

ENV=$1
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if [ -z "$ENV" ]; then
    echo "Usage: ./scripts/switch-env.sh [staging|production]"
    echo ""
    echo "Current environment:"
    grep "APP_ENV=" "$PROJECT_ROOT/.env" | head -1
    exit 1
fi

if [ "$ENV" != "staging" ] && [ "$ENV" != "production" ]; then
    echo "Error: Invalid environment. Use 'staging' or 'production'"
    exit 1
fi

echo "Switching to $ENV environment..."

# Copy the appropriate env file
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
echo "Remember to restart your app or run 'flutter run' again."
