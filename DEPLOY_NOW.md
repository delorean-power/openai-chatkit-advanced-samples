# Deploy Backend with CORS Fix

## The Issue

The frontend is getting CORS errors because the backend doesn't have CORS middleware configured yet.

## Quick Fix - Deploy Backend Now

```bash
cd /Users/admac/Developer/github/openai-chatkit-advanced-samples

# Deploy backend with CORS fix
./deploy/deploy-backend.sh
```

## What Changed

The backend now includes CORS middleware that allows all origins:

```python
# backend/app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Allows all origins
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
    expose_headers=["*"],
)
```

## After Deployment

1. **Wait for deployment to complete** (2-3 minutes)

2. **Refresh your browser** (hard refresh: Cmd+Shift+R on Mac, Ctrl+Shift+R on Windows)

3. **Clear browser cache** if needed

4. **Test ChatKit** - the CORS errors should be gone

## Verify Backend is Updated

```bash
# Check backend logs
gcloud run services logs read chatkit-backend --region=us-east4 --limit=20

# Test health endpoint
curl https://chatkit-backend-anjiaavaaq-uk.a.run.app/health

# Should return: {"status":"healthy"}
```

## If CORS Errors Persist

1. **Check backend revision**:
   ```bash
   gcloud run services describe chatkit-backend --region=us-east4
   ```

2. **Force redeploy**:
   ```bash
   ./deploy/deploy-backend.sh
   ```

3. **Clear browser cache completely**

4. **Try in incognito/private window**

## Production Security Note

The current CORS configuration allows all origins (`allow_origins=["*"]`). 

For production, you should restrict this:

```bash
# Set in .env.deploy
ALLOWED_ORIGINS=https://chatkit.lightshift.local,https://chatkit-frontend-520735029663.us-east4.run.app

# Redeploy
./deploy/deploy-backend.sh
```

## Other Errors in Your Screenshot

### 1. "Iframe not available" Error
- This is caused by the CORS issue
- Will be fixed once backend is redeployed

### 2. Preload Warning
- Not critical, just a performance warning
- Can be ignored for now

### 3. Favicon 404
- Not critical, just means no favicon.ico file
- Can be ignored or add a favicon later

## Summary

**The main issue is CORS - deploy the backend now:**

```bash
./deploy/deploy-backend.sh
```

Then refresh your browser and test again.
