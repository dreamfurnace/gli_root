#!/bin/bash

# GLI User Frontend Startup Script
echo "🚀 Starting GLI User Frontend..."

cd "$(dirname "$0")/gli_user-frontend"

# 포트 체크
if lsof -i :3000 > /dev/null 2>&1; then
    echo "❌ Port 3000 is already in use"
    echo "   Please stop the service using port 3000 and try again."
    exit 1
fi

echo "✅ Starting User Frontend on port 3000..."
npm run dev