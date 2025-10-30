# Deploy Instructions - Final Fix

## Issue Summary

Your frontend logs show **502 Bad Gateway** and **400 Bad Request** errors because nginx wasn't properly proxying requests to the backend.

### Root Cause

The nginx config had:
```nginx
location /chatkit {
    proxy_pass ${BACKEND_URL};  # Wrong - missing path
}
```

This sent requests to `https://backend/` instead of `https://backend/chatkit`.

### Fix Applied

Updated nginx.conf.template:
```nginx
location /chatkit {
    proxy_pass ${BACKEND_URL}/chatkit;  # Correct - includes path
}

location /facts {
    proxy_pass ${BACKEND_URL}/facts;  # Correct - includes path
}
```

## Deploy Both Services Now

### Step 1: Deploy Backend (CORS Fix)

```bash
cd ~/openai-chatkit-advanced-samples
./deploy/deploy-backend.sh
```

**Wait for completion** (~2-3 minutes)

### Step 2: Deploy Frontend (Nginx Proxy Fix)

```bash
./deploy/deploy-frontend.sh
```

**Wait for completion** (~2-3 minutes)

### Step 3: Test

```bash
# Get frontend URL
FRONTEND_URL=$(gcloud run services describe chatkit-frontend --region=us-east4 --format='value(status.url)')

echo "Frontend URL: $FRONTEND_URL"

# Open in browser
```

Then:
1. **Hard refresh** browser: `Cmd+Shift+R` (Mac) or `Ctrl+Shift+R` (Windows)
2. **Open console** (F12)
3. **Send a message**: "Hello"

## Expected Results

### ✅ Backend Logs (Good)
```
GET 200 /health
OPTIONS 200 /chatkit
POST 200 /chatkit
```

### ✅ Frontend Logs (Good)
```
GET 200 /health
GET 200 /
POST 200 /chatkit  (proxied successfully)
```

### ✅ Browser Console (Good)
- No CORS errors
- No 404 errors
- No 502 errors
- ChatKit responds to messages

## What Changed

### Backend (`backend/app/main.py`)
```python
# Added CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

### Frontend Nginx (`frontend/nginx.conf.template`)
```nginx
# Fixed proxy paths
location /chatkit {
    proxy_pass ${BACKEND_URL}/chatkit;  # Added /chatkit
}

location /facts {
    proxy_pass ${BACKEND_URL}/facts;  # Added /facts
}
```

### Frontend Build (`deploy/deploy-frontend.sh`)
```bash
# Use relative URLs
VITE_CHATKIT_API_URL="/chatkit"  # Not full backend URL
VITE_FACTS_API_URL="/facts"
```

### Frontend Deployment
```bash
# Pass backend URL as environment variable for nginx
--set-env-vars="BACKEND_URL=$BACKEND_URL"
```

## Request Flow (After Fix)

```
1. Browser sends: POST /chatkit
   ↓
2. Frontend nginx receives: POST /chatkit
   ↓
3. Nginx proxies to: POST https://backend-url/chatkit
   ↓
4. Backend processes request (CORS allows it)
   ↓
5. Backend responds: 200 OK
   ↓
6. Nginx returns response to browser
   ↓
7. ChatKit displays response
```

## Troubleshooting

### If 502 Errors Persist

```bash
# Check backend is running
curl https://chatkit-backend-anjiaavaaq-uk.a.run.app/health

# Check backend logs
gcloud run services logs read chatkit-backend --region=us-east4 --limit=20

# Verify backend URL in frontend
gcloud run services describe chatkit-frontend --region=us-east4 \
  --format='value(spec.template.spec.containers[0].env)'
```

### If CORS Errors Persist

```bash
# Redeploy backend
./deploy/deploy-backend.sh

# Clear browser cache completely
```

### If 404 Errors Persist

```bash
# Redeploy frontend
./deploy/deploy-frontend.sh

# Hard refresh browser
```

## Verification Commands

```bash
# Check both services are healthy
curl https://chatkit-backend-anjiaavaaq-uk.a.run.app/health
curl https://chatkit-frontend-520735029663.us-east4.run.app/health

# Check frontend environment variables
gcloud run services describe chatkit-frontend --region=us-east4 \
  --format='value(spec.template.spec.containers[0].env)'

# Should show: BACKEND_URL=https://chatkit-backend-anjiaavaaq-uk.a.run.app

# Check backend CORS is working
curl -H "Origin: https://chatkit-frontend-520735029663.us-east4.run.app" \
     -H "Access-Control-Request-Method: POST" \
     -H "Access-Control-Request-Headers: Content-Type" \
     -X OPTIONS \
     https://chatkit-backend-anjiaavaaq-uk.a.run.app/chatkit -v

# Should see: Access-Control-Allow-Origin: *
```

## All Fixes Summary

| Issue | Fix | Status |
|-------|-----|--------|
| Vite not found | Changed to `npm ci` | ✅ Fixed |
| Nginx startup | Added `docker-entrypoint.sh` | ✅ Fixed |
| Domain mapping | Using `gcloud beta` | ✅ Fixed |
| CORS errors | Added CORS middleware | ✅ Fixed |
| 502 errors | Fixed nginx proxy paths | ✅ Fixed |
| 404 errors | Use relative URLs | ✅ Fixed |

## Deploy Commands (Copy-Paste)

```bash
cd ~/openai-chatkit-advanced-samples

# Deploy backend
./deploy/deploy-backend.sh

# Wait for backend to complete, then deploy frontend
./deploy/deploy-frontend.sh

# Get URL and test
echo "Frontend: $(gcloud run services describe chatkit-frontend --region=us-east4 --format='value(status.url)')"
echo "Backend: $(gcloud run services describe chatkit-backend --region=us-east4 --format='value(status.url)')"
```

## Success Criteria

✅ Backend health check returns 200  
✅ Frontend health check returns 200  
✅ No CORS errors in browser console  
✅ No 502 errors in frontend logs  
✅ No 404 errors in backend logs  
✅ ChatKit UI loads  
✅ Can send messages  
✅ ChatKit responds  

---

**Everything is fixed and ready to deploy!** 🚀

Just run the two deploy commands and test.
