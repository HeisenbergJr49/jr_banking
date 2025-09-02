#!/bin/bash

# Jr Banking Installation Script
# This script helps set up the Jr Banking system

echo "=================================================="
echo "    Jr Banking - FiveM Banking System Setup"
echo "=================================================="
echo

# Check if we're in the right directory
if [ ! -f "fxmanifest.lua" ]; then
    echo "❌ Error: Please run this script from the jr_banking directory"
    exit 1
fi

echo "✅ Found jr_banking resource files"
echo

# Check for required dependencies
echo "🔍 Checking dependencies..."

if [ ! -d "../mysql-async" ] && [ ! -d "../oxmysql" ]; then
    echo "⚠️  Warning: mysql-async or oxmysql not found in resources folder"
    echo "   Make sure you have a MySQL connector resource installed"
fi

if [ ! -d "../es_extended" ] && [ ! -d "../qb-core" ]; then
    echo "⚠️  Warning: ESX or QB-Core not found in resources folder"
    echo "   Make sure you have a compatible framework installed"
fi

echo

# Database setup reminder
echo "📋 Database Setup Checklist:"
echo "   1. Import sql/banking_tables.sql into your database"
echo "   2. Make sure your MySQL connection is configured"
echo "   3. Verify mysql-async or oxmysql is working"
echo

# Configuration reminder
echo "⚙️  Configuration Checklist:"
echo "   1. Edit config.lua to match your server settings"
echo "   2. Set your framework: Config.Framework = 'esx' or 'qb'"
echo "   3. Configure transaction limits and fees"
echo "   4. Customize ATM/Bank locations if needed"
echo

# Server.cfg reminder
echo "📝 Server Configuration:"
echo "   Add the following to your server.cfg:"
echo "   ensure jr_banking"
echo

# Permission setup
echo "🔐 Admin Permissions:"
echo "   Make sure admins have the 'admin' or 'superadmin' group"
echo "   for access to /bankadmin command"
echo

echo "=================================================="
echo "                Setup Complete!"
echo "=================================================="
echo
echo "🚀 Your Jr Banking system is ready to use!"
echo
echo "📖 For detailed documentation, see README.md"
echo "🐛 Report issues at: https://github.com/HeisenbergJr49/jr_banking/issues"
echo
echo "💡 Need help? Check the README.md for troubleshooting"
echo

# Final file permissions check
chmod +x install.sh 2>/dev/null
echo "✅ Installation script completed successfully!"