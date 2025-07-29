#!/bin/bash

# GLI Admin Frontend Startup Script
echo "🚀 Starting GLI Admin Frontend..."

cd "$(dirname "$0")/gli_admin-frontend"

# 포트 체크
if lsof -i :3001 > /dev/null 2>&1; then
    echo "❌ Port 3001 is already in use"
    echo "   Please stop the service using port 3001 and try again."
    exit 1
fi

echo "✅ Starting Admin Frontend on port 3001..."
npm run dev