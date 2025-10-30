# Deploy Both Services - Final Fixes

## Issues Found & Fixed

### 1. CORS Preflight (OPTIONS) Failing
**Issue:** Backend returning 405 for OPTIONS requests  
**Fix:** Added explicit OPTIONS handlers for `/chatkit` and `/facts` endpoints

### 2. Nginx Buffer Size Too Small
**Issue:** `upstream sent too big header`  
**Fix:** Increased nginx buffer sizes for ChatKit/OpenAI responses

## Deploy Both Services

### Step 1: Deploy Backend (OPTIONS handlers)

```bash
cd ~/openai-chatkit-advanced-samples
./deploy/deploy-backend.sh
```

Wait for completion (~2-3 minutes)

### Step 2: Deploy Frontend (Buffer sizes)

```bash
./deploy/deploy-frontend.sh
```

Wait for completion (~2-3 minutes)

### Step 3: Test

```bash
# Run debug script
./debug-deployment.sh

# Should now show:
# ✅ Backend /chatkit OPTIONS: OK (200 instead of 405)
```

## What Changed

### Backend (`backend/app/main.py`)

```python
@app.options("/chatkit")
async def chatkit_options() -> Response:
    """Handle CORS preflight for ChatKit endpoint"""
    return Response(status_code=200)

@app.options("/facts")
async def facts_options() -> Response:
    """Handle CORS preflight for facts endpoint"""
    return Response(status_code=200)
```

### Frontend (`frontend/nginx.conf.template`)

```nginx
# Increase buffer sizes for large headers (ChatKit/OpenAI responses)
proxy_buffer_size 128k;
proxy_buffers 4 256k;
proxy_busy_buffers_size 256k;
large_client_header_buffers 4 32k;
```

## Request Flow (After Fix)

```
1. Browser sends: OPTIONS /chatkit (CORS preflight)
   ↓
2. Nginx proxies to backend
   ↓
3. Backend OPTIONS handler: 200 OK ✅
   ↓
4. CORS middleware adds headers
   ↓
5. Browser receives: 200 OK with CORS headers
   ↓
6. Browser sends: POST /chatkit (actual request)
   ↓
7. Backend processes and responds
   ↓
8. Nginx accepts large headers (increased buffers) ✅
   ↓
9. Browser receives: 200 OK with ChatKit response
   ↓
10. ChatKit displays message ✅
```

## Verification

After both deployments:

```bash
# Test OPTIONS (should be 200 now)
curl -X OPTIONS https://chatkit-backend-anjiaavaaq-uk.a.run.app/chatkit -v

# Should see:
# < HTTP/2 200
# < access-control-allow-origin: *
# < access-control-allow-methods: *

# Test in browser
open https://chatkit-frontend-anjiaavaaq-uk.a.run.app

# Hard refresh: Cmd+Shift+R
# Send message: "Hello"
# Should work! ✅
```

## All Fixes Summary

| Issue | Fix | File | Status |
|-------|-----|------|--------|
| Vite not found | `npm ci` | frontend/Dockerfile | ✅ |
| Nginx startup | docker-entrypoint.sh | frontend/ | ✅ |
| CORS middleware | CORSMiddleware | backend/app/main.py | ✅ |
| OPTIONS 405 | Explicit handlers | backend/app/main.py | ✅ NEW |
| Nginx buffers | Increased sizes | frontend/nginx.conf.template | ✅ NEW |
| Proxy paths | Added /chatkit | frontend/nginx.conf.template | ✅ |
| Domain mapping | gcloud beta | deploy/setup-domain.sh | ✅ |

## Deploy Commands (Copy-Paste)

```bash
cd ~/openai-chatkit-advanced-samples

# Deploy backend
./deploy/deploy-backend.sh

# Wait for backend, then deploy frontend
./deploy/deploy-frontend.sh

# Test
./debug-deployment.sh

# Open in browser
open https://chatkit-frontend-anjiaavaaq-uk.a.run.app
```

## Success Criteria

After deployment, you should see:

✅ Backend OPTIONS /chatkit returns 200 (not 405)  
✅ Backend POST /chatkit returns 200  
✅ Frontend logs show no 502 errors  
✅ Frontend logs show no "upstream sent too big header"  
✅ Browser console shows no CORS errors  
✅ ChatKit UI loads  
✅ Can send messages  
✅ ChatKit responds  

---

**This should be the final deployment!** 🎉

All issues have been identified and fixed.
