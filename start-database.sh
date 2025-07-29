#!/bin/bash

# GLI Database Startup Script
echo "🚀 Starting GLI Database (PostgreSQL + Redis)..."

cd "$(dirname "$0")/gli_database"

# 포트 체크
if lsof -i :5433 > /dev/null 2>&1; then
    echo "❌ Port 5433 is already in use"
    echo "   Please stop the service using port 5433 and try again."
    exit 1
fi

echo "✅ Starting Database on port 5433..."
docker-compose up