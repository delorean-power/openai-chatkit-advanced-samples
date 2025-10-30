# Troubleshooting Guide

Common issues and solutions for ChatKit Cloud Run deployment.

## Build Issues

### Frontend: "vite: not found" Error

**Error:**
```
sh: 1: vite: not found
ERROR: failed to build: process "/bin/sh -c npm run build" did not complete successfully: exit code 127
```

**Cause:** `npm ci --only=production` excludes devDependencies, but `vite` is needed for the build.

**Solution:** ✅ Fixed in latest Dockerfile - now installs all dependencies for build.

**Verify:**
```bash
# Check frontend/Dockerfile line 10
# Should be: RUN npm ci && npm cache clean --force
# NOT: RUN npm ci --only=production && npm cache clean --force
```

### Backend: Python Dependencies Missing

**Error:**
```
ModuleNotFoundError: No module named 'fastapi'
```

**Solution:**
```bash
# Ensure backend/pyproject.toml has all dependencies
cd backend
uv sync
```

### Docker Build Warnings About Secrets

**Warning:**
```
SecretsUsedInArgOrEnv: Do not use ARG or ENV instructions for sensitive data
```

**Explanation:** This is expected for build-time variables like `VITE_CHATKIT_API_DOMAIN_KEY`. The domain key is embedded in the frontend JavaScript bundle (it's meant to be public for client-side use). The warning is informational.

**Note:** The domain key is NOT a secret - it's a public identifier that restricts which domains can use ChatKit. Your actual OpenAI API key is stored securely in Secret Manager and never exposed to the frontend.

## Deployment Issues

### Authentication Errors

**Error:**
```
ERROR: (gcloud.run.deploy) User does not have permission to access project
```

**Solution:**
```bash
# Re-authenticate
gcloud auth login
gcloud auth application-default login

# Set project
gcloud config set project YOUR_PROJECT_ID

# Verify
gcloud config list
```

### Secret Not Found

**Error:**
```
ERROR: Secret [openai-api-key] not found
```

**Solution:**
```bash
# Create the secret
echo -n "sk-proj-your-key" | gcloud secrets create openai-api-key \
  --data-file=- \
  --replication-policy="automatic"

# Or update existing
echo -n "sk-proj-your-key" | gcloud secrets versions add openai-api-key \
  --data-file=-
```

### Backend Deployment Fails

**Error:**
```
ERROR: (gcloud.run.deploy) Cloud Run error: Container failed to start
```

**Solution:**
```bash
# Check logs
gcloud run services logs read chatkit-backend --region=us-central1 --limit=50

# Common issues:
# 1. Missing OPENAI_API_KEY secret
# 2. Port not set to 8080
# 3. Health check failing

# Verify service configuration
gcloud run services describe chatkit-backend --region=us-central1
```

### Frontend Can't Connect to Backend

**Error:** Frontend shows connection errors or CORS issues

**Solution:**
```bash
# 1. Verify backend is running
curl https://your-backend-url/health

# 2. Check frontend environment variables
gcloud run services describe chatkit-frontend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"

# 3. Verify BACKEND_URL is correct
# Should match the backend service URL

# 4. Redeploy frontend with correct backend URL
./deploy/deploy-frontend.sh
```

## Domain Issues

### Domain Mapping Fails

**Error:**
```
ERROR: (gcloud.run.domain-mappings.create) Domain verification failed
```

**Solution:**
```bash
# 1. Verify you own the domain
# 2. Check DNS records are configured correctly
# 3. Wait for DNS propagation (can take up to 48 hours)

# Check domain mapping status
gcloud run domain-mappings describe \
  --domain=chatkit.lightshift.local \
  --region=us-central1
```

### DNS Not Resolving

**Error:** `chatkit.lightshift.local` doesn't resolve

**Solution:**
```bash
# 1. Verify DNS records are configured
nslookup chatkit.lightshift.local

# 2. Check with dig for more details
dig chatkit.lightshift.local +trace

# 3. Verify records match what setup-domain.sh provided
./deploy/setup-domain.sh

# 4. If using Cloud DNS, verify zone configuration
gcloud dns managed-zones list
```

### SSL Certificate Not Provisioning

**Error:** HTTPS not working on custom domain

**Solution:**
```bash
# Check certificate status
gcloud run domain-mappings describe \
  --domain=chatkit.lightshift.local \
  --region=us-central1 \
  --format="get(status.certificateStatus)"

# Certificate provisioning can take 15-60 minutes
# Requires:
# 1. DNS records correctly configured
# 2. Domain mapping created
# 3. DNS propagation complete
```

## ChatKit Issues

### Invalid Domain Key

**Error:** ChatKit shows "Invalid domain key" error

**Solution:**
```bash
# 1. Verify domain is in allowlist
# https://platform.openai.com/settings/organization/security/domain-allowlist

# 2. Check domain key is correct in .env.deploy
cat .env.deploy | grep CHATKIT_DOMAIN_KEY

# 3. Redeploy frontend with correct key
./deploy/deploy-frontend.sh

# 4. Clear browser cache and try again
```

### ChatKit Not Loading

**Error:** Blank screen or ChatKit component doesn't render

**Solution:**
```bash
# 1. Check browser console for errors
# 2. Verify frontend build succeeded
# 3. Check nginx is serving files correctly

# Test nginx directly
curl https://your-frontend-url/

# Check logs
gcloud run services logs read chatkit-frontend --region=us-central1
```

## Performance Issues

### Cold Start Latency

**Issue:** First request takes 5-10 seconds

**Solution:**
```bash
# Set minimum instances in .env.deploy
BACKEND_MIN_INSTANCES=1
FRONTEND_MIN_INSTANCES=1

# Redeploy
./deploy/deploy-backend.sh
./deploy/deploy-frontend.sh

# Note: This increases costs but eliminates cold starts
```

### Out of Memory

**Error:**
```
Container exceeded memory limit
```

**Solution:**
```bash
# Increase memory in .env.deploy
BACKEND_MEMORY=1Gi  # Default is 512Mi
FRONTEND_MEMORY=512Mi  # Default is 256Mi

# Redeploy
./deploy/deploy-backend.sh
./deploy/deploy-frontend.sh
```

### High CPU Usage

**Issue:** Service is slow or timing out

**Solution:**
```bash
# Increase CPU in .env.deploy
BACKEND_CPU=2  # Default is 1
FRONTEND_CPU=2  # Default is 1

# Redeploy
./deploy/deploy-backend.sh
./deploy/deploy-frontend.sh
```

## Local Testing Issues

### Docker Not Running

**Error:**
```
Cannot connect to the Docker daemon
```

**Solution:**
```bash
# Start Docker Desktop (macOS)
open -a Docker

# Or start Docker service (Linux)
sudo systemctl start docker

# Verify
docker info
```

### Port Already in Use

**Error:**
```
Bind for 0.0.0.0:8080 failed: port is already allocated
```

**Solution:**
```bash
# Find process using the port
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or use different ports in local-test.sh
```

### Local Build Fails

**Error:** Docker build fails locally but works in Cloud Build

**Solution:**
```bash
# Clear Docker cache
docker system prune -a

# Rebuild without cache
docker build --no-cache -t test-image .

# Check Docker resources
docker system df
```

## Monitoring & Debugging

### View Real-Time Logs

```bash
# Backend logs (live)
gcloud run services logs tail chatkit-backend --region=us-central1

# Frontend logs (live)
gcloud run services logs tail chatkit-frontend --region=us-central1

# Filter by severity
gcloud run services logs read chatkit-backend \
  --region=us-central1 \
  --filter="severity>=ERROR"
```

### Check Service Health

```bash
# Use monitoring script
./deploy/monitor.sh

# Or manually
gcloud run services describe chatkit-backend --region=us-central1
gcloud run services describe chatkit-frontend --region=us-central1
```

### Debug Container

```bash
# Get revision name
REVISION=$(gcloud run services describe chatkit-backend \
  --region=us-central1 \
  --format='value(status.latestReadyRevisionName)')

# View revision details
gcloud run revisions describe $REVISION --region=us-central1

# Check environment variables
gcloud run revisions describe $REVISION \
  --region=us-central1 \
  --format='value(spec.containers[0].env)'
```

## Cost Issues

### Unexpected Charges

**Issue:** Higher than expected Cloud Run costs

**Solution:**
```bash
# Check current usage
gcloud run services describe chatkit-backend \
  --region=us-central1 \
  --format='value(status.traffic)'

# Review metrics
# https://console.cloud.google.com/run

# Optimize:
# 1. Set min instances to 0 for dev/staging
# 2. Reduce memory/CPU if over-provisioned
# 3. Set appropriate concurrency limits
# 4. Review request patterns

# Update .env.deploy
BACKEND_MIN_INSTANCES=0  # For dev
BACKEND_MEMORY=512Mi  # Right-size
BACKEND_CONCURRENCY=80  # Optimize
```

## Getting Help

### Collect Debug Information

```bash
# Run this and share output when asking for help
echo "=== Configuration ==="
cat .env.deploy | grep -v "API_KEY"

echo "=== Backend Status ==="
gcloud run services describe chatkit-backend --region=us-central1

echo "=== Frontend Status ==="
gcloud run services describe chatkit-frontend --region=us-central1

echo "=== Recent Errors ==="
gcloud run services logs read chatkit-backend \
  --region=us-central1 \
  --filter="severity>=ERROR" \
  --limit=10
```

### Useful Commands

```bash
# Full service info
gcloud run services describe SERVICE_NAME --region=REGION

# List all revisions
gcloud run revisions list --service=SERVICE_NAME --region=REGION

# Check quotas
gcloud compute project-info describe --project=PROJECT_ID

# View billing
gcloud billing accounts list
```

## Quick Fixes

### Complete Reset

If everything is broken, start fresh:

```bash
# 1. Clean up existing deployment
./deploy/cleanup.sh

# 2. Verify configuration
./verify-setup.sh

# 3. Redeploy from scratch
./deploy/deploy-all.sh

# 4. Set up domain
./deploy/setup-domain.sh
```

### Rollback to Previous Version

```bash
# Use rollback script
./deploy/rollback.sh

# Or manually
gcloud run revisions list --service=chatkit-backend --region=us-central1
gcloud run services update-traffic chatkit-backend \
  --region=us-central1 \
  --to-revisions=REVISION_NAME=100
```

## Still Having Issues?

1. Check [CLOUD_RUN_DEPLOYMENT.md](CLOUD_RUN_DEPLOYMENT.md) for detailed documentation
2. Review [LIGHTSHIFT_SETUP.md](LIGHTSHIFT_SETUP.md) for domain-specific issues
3. Check Cloud Run logs for specific error messages
4. Verify all prerequisites are installed and configured
5. Test with Cloud Run default URLs before custom domains

---

**Last Updated:** January 2025
