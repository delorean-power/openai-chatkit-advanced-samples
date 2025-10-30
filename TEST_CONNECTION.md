# Test Frontend-Backend Connection

## Quick Tests

### 1. Test from your browser console

Open the frontend in browser, then open console (F12) and run:

```javascript
// Test if /chatkit endpoint is reachable
fetch('/chatkit', {
  method: 'OPTIONS',
  headers: {
    'Origin': window.location.origin
  }
}).then(r => console.log('OPTIONS /chatkit:', r.status, r.statusText));

// Test POST to /chatkit
fetch('/chatkit', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({test: 'hello'})
}).then(r => r.text()).then(t => console.log('POST /chatkit response:', t));
```

### 2. Check what's loaded

In browser console:

```javascript
// Check config
console.log('CHATKIT_API_URL:', '/chatkit');
console.log('Current origin:', window.location.origin);

// Check if ChatKit SDK loaded
console.log('ChatKit available:', typeof window.ChatKit);
```

### 3. Check Network Tab

1. Open DevTools (F12)
2. Go to Network tab
3. Refresh page
4. Look for:
   - ❌ Failed requests (red)
   - ⚠️ 502 errors to `/chatkit`
   - ⚠️ CORS errors
   - ✅ Successful requests to ChatKit CDN

### 4. Check Console Errors

Look for specific errors:
- "Iframe not available" - ChatKit SDK issue
- "Failed to fetch" - Network/CORS issue
- "502 Bad Gateway" - Nginx buffer issue
- "CORS policy" - CORS headers missing

## Expected Behavior

### ✅ Working State

**Network Tab:**
```
GET  /                200 OK
GET  /assets/*.js     200 OK
GET  /assets/*.css    200 OK
OPTIONS /chatkit      200 OK (with CORS headers)
POST /chatkit         200 OK (when you send a message)
```

**Console:**
```
No errors
ChatKit iframe loads
Can send messages
```

### ❌ Current Issue

Based on your screenshot:
- "Iframe not available" error
- ChatKit component not rendering

This suggests:
1. ChatKit SDK not loading properly, OR
2. ChatKit can't connect to backend, OR
3. Domain key issue

## Diagnostic Steps

### Step 1: Verify backend is reachable

```bash
# From your terminal
curl https://chatkit-frontend-anjiaavaaq-uk.a.run.app/chatkit \
  -X OPTIONS \
  -H "Origin: https://chatkit-frontend-anjiaavaaq-uk.a.run.app" \
  -v
```

Should return 200 with CORS headers.

### Step 2: Check if it's a domain key issue

The domain key `domain_pk_localhost_dev` only works for localhost. For Cloud Run, you need:

1. Go to https://platform.openai.com/settings/organization/security/domain-allowlist
2. Add your frontend domain: `chatkit-frontend-anjiaavaaq-uk.a.run.app`
3. Copy the generated domain key
4. Update `.env.deploy`:
   ```
   CHATKIT_DOMAIN_KEY=domain_pk_your_actual_key_here
   ```
5. Redeploy frontend:
   ```bash
   ./deploy/deploy-frontend.sh
   ```

### Step 3: Check ChatKit SDK loading

In browser console:
```javascript
// Check if ChatKit SDK is loaded
console.log(window.ChatKit);

// If undefined, check script tags
document.querySelectorAll('script').forEach(s => 
  console.log(s.src)
);
```

## Most Likely Issue

Based on "Iframe not available" error, the issue is probably:

**❌ Invalid domain key**

The frontend is using `domain_pk_localhost_dev` which doesn't work for `chatkit-frontend-anjiaavaaq-uk.a.run.app`.

**Solution:**
1. Add domain to OpenAI allowlist
2. Get real domain key
3. Update CHATKIT_DOMAIN_KEY in .env.deploy
4. Redeploy frontend

## Quick Fix to Test

To test if everything else works, you can temporarily access via localhost:

```bash
# Port forward to test locally
gcloud run services proxy chatkit-frontend --region=us-east4 --port=8080
```

Then open http://localhost:8080 - this should work with `domain_pk_localhost_dev`.

If it works locally but not on Cloud Run, it confirms the domain key is the issue.
