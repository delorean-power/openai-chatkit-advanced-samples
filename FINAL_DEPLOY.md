# Final Deployment Steps

## Issue Identified

The frontend was trying to connect directly to the backend URL, but it should use nginx proxy with relative URLs (`/chatkit` and `/facts`).

## All Fixes Applied

✅ **Backend CORS** - Added CORS middleware  
✅ **Frontend Build** - Fixed vite dependencies  
✅ **Nginx Config** - Added environment variable substitution  
✅ **API URLs** - Changed to use relative URLs for nginx proxy  
✅ **Domain Mapping** - Using `gcloud beta`

## Deploy Both Services Now

### 1. Deploy Backend (with CORS)

```bash
cd ~/openai-chatkit-advanced-samples
./deploy/deploy-backend.sh
```

Wait for completion (~2-3 minutes).

### 2. Deploy Frontend (with fixed URLs)

```bash
./deploy/deploy-frontend.sh
```

Wait for completion (~2-3 minutes).

### 3. Test the Application

```bash
# Get frontend URL
gcloud run services describe chatkit-frontend --region=us-east4 --format='value(status.url)'

# Open in browser
```

## How It Works Now

```
Browser
  ↓
Frontend (React App)
  ↓ POST /chatkit
Nginx (in frontend container)
  ↓ proxy_pass
Backend (FastAPI with CORS)
  ↓
OpenAI API
```

### Frontend Configuration

- **Build time**: URLs set to `/chatkit` and `/facts` (relative)
- **Runtime**: Nginx proxies these to backend URL via environment variable
- **Result**: No CORS issues, clean architecture

### Backend Configuration

- **CORS**: Allows all origins (`allow_origins=["*"]`)
- **Endpoints**: `/chatkit`, `/facts`, `/health`
- **Port**: 8080

## Verify Deployment

### Check Backend

```bash
# Health check
curl https://chatkit-backend-anjiaavaaq-uk.a.run.app/health

# Should return: {"status":"healthy"}

# Check logs
gcloud run services logs read chatkit-backend --region=us-east4 --limit=10
```

### Check Frontend

```bash
# Health check
curl https://chatkit-frontend-520735029663.us-east4.run.app/health

# Should return: healthy

# Check logs
gcloud run services logs read chatkit-frontend --region=us-east4 --limit=10
```

### Test in Browser

1. Open frontend URL
2. Open browser console (F12)
3. Send a test message: "Hello"
4. Should see:
   - ✅ No CORS errors
   - ✅ POST to `/chatkit` succeeds
   - ✅ ChatKit responds

## Expected Logs

### Backend Logs (Good)
```
GET 200 /health
OPTIONS 200 /chatkit  (CORS preflight)
POST 200 /chatkit     (ChatKit request)
```

### Frontend Logs (Good)
```
GET 200 /health
GET 200 /
POST 200 /chatkit (proxied to backend)
```

## If Issues Persist

### CORS Errors
```bash
# Redeploy backend
./deploy/deploy-backend.sh
```

### 404 Errors
```bash
# Redeploy frontend
./deploy/deploy-frontend.sh
```

### Clear Browser Cache
- Hard refresh: Cmd+Shift+R (Mac) or Ctrl+Shift+R (Windows)
- Or use incognito/private window

## Next Steps (Optional)

### 1. Set Up Custom Domain

```bash
./deploy/setup-domain.sh
```

Then configure GoDaddy DNS following [GODADDY_DNS_SETUP.md](GODADDY_DNS_SETUP.md).

### 2. Configure ChatKit Domain Key

1. Go to [OpenAI Domain Allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist)
2. Add your domain
3. Copy the domain key
4. Update `.env.deploy`:
   ```bash
   CHATKIT_DOMAIN_KEY=your-key-here
   ```
5. Redeploy frontend:
   ```bash
   ./deploy/deploy-frontend.sh
   ```

### 3. Restrict CORS (Production)

Update `.env.deploy`:
```bash
ALLOWED_ORIGINS=https://chatkit.lightshift.local,https://chatkit-frontend-520735029663.us-east4.run.app
```

Redeploy backend:
```bash
./deploy/deploy-backend.sh
```

## Summary

**Deploy both services:**

```bash
# 1. Backend (CORS fix)
./deploy/deploy-backend.sh

# 2. Frontend (URL fix)
./deploy/deploy-frontend.sh

# 3. Test
open $(gcloud run services describe chatkit-frontend --region=us-east4 --format='value(status.url)')
```

The application should now work completely! 🎉
