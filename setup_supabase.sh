#!/bin/bash

# Supabase Setup Script for iOS App Template
# This script helps you set up the Supabase database for the app

echo "🚀 Setting up Supabase database for iOS App Template"
echo ""

# Check if Supabase CLI is installed
if ! command -v supabase &> /dev/null; then
    echo "❌ Supabase CLI is not installed."
    echo "Please install it first:"
    echo "npm install supabase --global"
    echo "or visit: https://supabase.com/docs/guides/cli"
    exit 1
fi

# Check if we're in a Supabase project
if [ ! -f "supabase/config.toml" ]; then
    echo "❌ Not in a Supabase project directory."
    echo "Please run this script from your Supabase project root."
    echo "If you haven't initialized Supabase yet, run:"
    echo "supabase init"
    exit 1
fi

echo "✅ Supabase CLI detected"
echo "📁 Project directory: $(pwd)"
echo ""

# Ask user if they want to start Supabase locally or connect to remote
echo "Choose setup option:"
echo "1) Local development (start Supabase locally)"
echo "2) Remote project (apply migrations to existing remote project)"
echo "3) Just show migration commands"
read -p "Enter your choice (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🏠 Starting local Supabase development environment..."
        supabase start

        echo ""
        echo "📊 Applying database migrations..."
        supabase db reset

        echo ""
        echo "✅ Local setup complete!"
        echo "🌐 Supabase Studio: http://localhost:54323"
        echo "🔑 Local anon key: retrieve from 'supabase status' output or Supabase Studio (Settings → API)"
        ;;

    2)
        echo ""
        echo "🔗 Connecting to remote Supabase project..."
        echo "Please make sure you're logged in:"
        supabase login

        echo ""
        echo "📤 Pushing migrations to remote project..."
        supabase db push

        echo ""
        echo "✅ Remote setup complete!"
        ;;

    3)
        echo ""
        echo "📋 Migration Commands:"
        echo ""
        echo "1. For local development:"
        echo "   supabase start"
        echo "   supabase db reset"
        echo ""
        echo "2. For remote project:"
        echo "   supabase login"
        echo "   supabase db push"
        echo ""
        echo "3. Manual SQL execution:"
        echo "   Copy the contents of supabase_migrations.sql"
        echo "   Paste into Supabase SQL Editor in your dashboard"
        ;;

    *)
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "📤 Deploying edge functions..."
supabase functions deploy get-onboarding-screens
supabase functions deploy get-survey-questions

echo ""
echo "📝 Next steps:"
echo "1. Update Configuration.swift with your Supabase URL and keys"
echo "2. Test the app to ensure onboarding loads properly"
echo "3. Check Supabase dashboard for data verification"
echo "4. Verify edge functions are working by checking the function logs"
echo ""
echo "🎉 Setup complete! Your Supabase database and edge functions are ready."