#!/bin/bash

# Setup script for Silni App
# Run this after cloning

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "Setting up Silni App..."

# Configure git hooks
git config core.hooksPath .githooks
echo "✓ Git hooks configured"

# Install Flutter dependencies
flutter pub get
echo "✓ Dependencies installed"

echo ""
echo "Done! Now create your .env.staging and .env.production files."
