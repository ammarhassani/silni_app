#!/bin/bash

# Setup script for Silni App development environment
# Run this after cloning the repository

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$PROJECT_ROOT"

echo "🔧 Setting up Silni App development environment..."
echo ""

# 1. Configure git hooks
echo "1️⃣ Configuring git hooks..."
git config core.hooksPath .githooks
echo "   ✓ Git hooks configured"

# 2. Create .env files from examples if they don't exist
echo ""
echo "2️⃣ Setting up environment files..."

if [ ! -f ".env.staging" ]; then
    if [ -f ".env.staging.example" ]; then
        cp .env.staging.example .env.staging
        echo "   ✓ Created .env.staging from example"
    else
        echo "   ⚠️  .env.staging.example not found - please create .env.staging manually"
    fi
else
    echo "   ✓ .env.staging already exists"
fi

if [ ! -f ".env.production" ]; then
    if [ -f ".env.production.example" ]; then
        cp .env.production.example .env.production
        echo "   ✓ Created .env.production from example"
    else
        echo "   ⚠️  .env.production.example not found - please create .env.production manually"
    fi
else
    echo "   ✓ .env.production already exists"
fi

# 3. Set initial environment based on current branch
echo ""
echo "3️⃣ Setting environment for current branch..."
BRANCH=$(git branch --show-current)

if [ "$BRANCH" = "main" ]; then
    ./scripts/switch-env.sh production
else
    ./scripts/switch-env.sh staging
fi

# 4. Install Flutter dependencies
echo ""
echo "4️⃣ Installing Flutter dependencies..."
flutter pub get

echo ""
echo "✅ Setup complete!"
echo ""
echo "Your environment: $(grep 'APP_ENV=' .env | cut -d'=' -f2)"
echo "Current branch: $BRANCH"
echo ""
echo "Next steps:"
echo "  • Run 'flutter run' to start the app"
echo "  • Switch branches with 'git checkout develop' or 'git checkout main'"
echo "  • Environments auto-switch when you change branches"
