# GLI Platform - Environment Variables Configuration

## Overview

This document describes the environment variable configuration for the GLI Platform, including both backend (Django API Server) and frontend (Vue.js User Frontend) applications.

## Backend Environment Variables (gli_api-server)

### File Locations
- Development: `.env.development`
- Staging: `.env.staging` (create as needed)
- Production: `.env.production` (create as needed)

### Django Core Settings
```bash
DJANGO_SECRET_KEY=your-secret-key-here
DJANGO_ENV=development|staging|production
DJANGO_DEBUG=True|False
DJANGO_ALLOWED_HOSTS=localhost,127.0.0.1,0.0.0.0
```

### Database Settings
```bash
# SQLite (Development)
DATABASE_NAME=gli_dev.db
DATABASE_USER=
DATABASE_PASSWORD=
DATABASE_HOST=
DATABASE_PORT=

# PostgreSQL (Staging/Production)
DATABASE_NAME=gli_database
DATABASE_USER=postgres_user
DATABASE_PASSWORD=secure_password
DATABASE_HOST=localhost
DATABASE_PORT=5432
```

### JWT Authentication
```bash
JWT_ACCESS_TOKEN_LIFETIME=30              # minutes
JWT_REFRESH_TOKEN_LIFETIME=1440           # minutes (24 hours)
JWT_ROTATE_REFRESH_TOKENS=False
```

### Solana Configuration
```bash
SOLANA_NETWORK=devnet|mainnet-beta
SOLANA_RPC_URL=https://api.devnet.solana.com
```

### CORS Settings
```bash
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:5173,http://127.0.0.1:3000,http://127.0.0.1:5173
```

### API & Logging
```bash
API_VERSION=v1
API_RATE_LIMIT=1000
LOG_LEVEL=DEBUG|INFO|WARNING|ERROR
LOG_TO_FILE=False|True
```

### AWS Configuration (Optional)
```bash
AWS_ACCESS_KEY_ID=your_aws_access_key
AWS_SECRET_ACCESS_KEY=your_aws_secret_key
AWS_STORAGE_BUCKET_NAME=your_bucket_name
AWS_S3_REGION=ap-northeast-2
```

### Email Settings
```bash
EMAIL_BACKEND=django.core.mail.backends.console.EmailBackend
EMAIL_HOST=
EMAIL_PORT=
EMAIL_USE_TLS=False
```

## Frontend Environment Variables (gli_user-frontend)

### File Locations
- Development: `.env.development`
- Staging: `.env.staging`
- Production: `.env.production`
- Local Override: `.env.local` (create from `.env.local.example`)

### API Configuration
```bash
VITE_API_BASE_URL=http://localhost:8000     # Backend API URL
VITE_API_VERSION=v1
VITE_API_TIMEOUT=10000                      # milliseconds
```

### Solana Configuration
```bash
VITE_SOLANA_NETWORK=devnet|mainnet-beta
VITE_SOLANA_RPC_URL=https://api.devnet.solana.com
VITE_SOLANA_COMMITMENT=confirmed|finalized
```

### Authentication
```bash
VITE_JWT_STORAGE_KEY=gli_auth_token
VITE_USER_PROFILE_STORAGE_KEY=gli_user_profile
```

### App Configuration
```bash
VITE_APP_TITLE=GLI User Frontend
VITE_APP_DESCRIPTION=GLI Platform User Frontend Application
VITE_APP_VERSION=1.0.0
VITE_APP_ENVIRONMENT=development|staging|production
```

### Feature Flags
```bash
VITE_ENABLE_DEVTOOLS=true|false
VITE_ENABLE_DEBUG_MODE=true|false
VITE_ENABLE_PERFORMANCE_MONITOR=true|false
VITE_ENABLE_ERROR_REPORTING=true|false
```

### PWA Settings
```bash
VITE_PWA_ENABLED=true
VITE_PWA_CACHE_NAME=gli-user-frontend-cache
```

### Logging & Development
```bash
VITE_LOG_LEVEL=debug|info|warn|error
VITE_ENABLE_CONSOLE_LOGS=true|false
VITE_HOT_RELOAD=true|false
VITE_SOURCE_MAPS=true|false
```

### Production Settings
```bash
VITE_BUILD_OPTIMIZATION=true
VITE_CDN_URL=https://cdn.gli-platform.com
VITE_STATIC_ASSETS_URL=https://static.gli-platform.com
```

### Analytics & Error Reporting
```bash
VITE_SENTRY_DSN=your_sentry_dsn
VITE_ERROR_REPORTING_ENDPOINT=https://api.gli-platform.com/errors
VITE_GOOGLE_ANALYTICS_ID=GA-XXXXX-X
VITE_MIXPANEL_TOKEN=your_mixpanel_token
```

## Environment-Specific Configurations

### Development Environment
- **Backend**: SQLite database, debug mode enabled, all CORS origins allowed
- **Frontend**: Hot reload enabled, devtools enabled, debug mode on
- **Solana**: Devnet network for testing

### Staging Environment
- **Backend**: PostgreSQL database, limited CORS, staging-specific URLs
- **Frontend**: Production optimizations enabled, error reporting on
- **Solana**: Devnet network with finalized commitment

### Production Environment
- **Backend**: PostgreSQL database, strict CORS, production URLs only
- **Frontend**: All optimizations enabled, minimal logging, error reporting
- **Solana**: Mainnet-beta network

## Security Best Practices

### Backend
1. Never commit `.env.*` files with real credentials
2. Use strong `DJANGO_SECRET_KEY` in production
3. Set `DJANGO_DEBUG=False` in production
4. Configure specific `CORS_ALLOWED_ORIGINS` for production
5. Use environment-specific database credentials

### Frontend
1. Use `VITE_` prefix for all environment variables (required by Vite)
2. Never include sensitive data in frontend environment variables
3. Configure different API URLs for each environment
4. Enable error reporting only in staging/production

## Setup Instructions

### Backend Setup
```bash
cd gli_api-server

# Copy and configure environment file
cp .env.development .env.local
# Edit .env.local with your specific values

# Load environment and start server
uv run python manage.py runserver
```

### Frontend Setup
```bash
cd gli_user-frontend

# Copy and configure environment file
cp .env.local.example .env.local
# Edit .env.local with your specific values

# Start development server
npm run dev
```

### Database Setup
```bash
cd gli_database

# Start PostgreSQL container
docker-compose up -d

# Run migrations
cd ../gli_api-server
uv run python manage.py migrate
```

## Troubleshooting

### Common Issues

1. **CORS Errors**: Check `CORS_ALLOWED_ORIGINS` in backend matches frontend URL
2. **API Connection Failed**: Verify `VITE_API_BASE_URL` matches backend server address
3. **Solana Network Issues**: Ensure `SOLANA_NETWORK` and `SOLANA_RPC_URL` are consistent between frontend and backend
4. **Database Connection**: Check database environment variables and ensure database server is running

### Environment Variable Loading

- **Backend**: Django loads `.env.{DJANGO_ENV}` automatically
- **Frontend**: Vite loads `.env.{NODE_ENV}` and `.env.local` automatically

### Verification Commands

```bash
# Backend - Check loaded environment
cd gli_api-server
uv run python -c "import os; print(f'DJANGO_ENV: {os.getenv(\"DJANGO_ENV\")}')"

# Frontend - Check environment in browser console
console.log('API_BASE_URL:', import.meta.env.VITE_API_BASE_URL)
```

## Monitoring

- Check `server.log` for backend environment variable loading messages
- Use browser developer tools to inspect frontend environment variables
- Monitor CORS preflight requests in network tab for cross-origin issues

## Related Files

- Backend: `config/settings.py` - Environment variable processing
- Frontend: `src/composables/useSolanaAuth.ts` - Environment variable usage
- Docker: `gli_database/docker-compose.yml` - Database configuration