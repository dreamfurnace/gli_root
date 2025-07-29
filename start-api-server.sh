#!/bin/bash

# GLI Django API Server Startup Script
echo "🚀 Starting GLI Django API Server..."

cd "$(dirname "$0")/gli_api-server"

# 포트 체크
if lsof -i :8000 > /dev/null 2>&1; then
    echo "❌ Port 8000 is already in use"
    echo "   Please stop the service using port 8000 and try again."
    exit 1
fi

echo "✅ Starting Django API Server on port 8000..."
uv run python manage.py runserver 0.0.0.0:8000