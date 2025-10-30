# Deployment Checklist

Use this checklist to ensure successful deployment to Cloud Run.

## Pre-Deployment

### ✅ Prerequisites
- [ ] Google Cloud account with billing enabled
- [ ] gcloud CLI installed and authenticated (`gcloud auth login`)
- [ ] Docker installed and running (`docker info`)
- [ ] OpenAI API key obtained

### ✅ Configuration
- [ ] Copied `.env.deploy.template` to `.env.deploy`
- [ ] Set `GCP_PROJECT_ID` in `.env.deploy`
- [ ] Set `GCP_REGION` in `.env.deploy` (default: us-central1)
- [ ] Set `OPENAI_API_KEY` in `.env.deploy`
- [ ] Configured lightshift.local domains (optional):
  - [ ] `BACKEND_CUSTOM_DOMAIN=chatkit-api.lightshift.local`
  - [ ] `FRONTEND_CUSTOM_DOMAIN=chatkit.lightshift.local`

### ✅ Files Verification
- [ ] `frontend/nginx.conf.template` exists (NOT nginx.conf)
- [ ] `frontend/docker-entrypoint.sh` exists
- [ ] `frontend/Dockerfile` uses ENTRYPOINT
- [ ] `backend/Dockerfile` exists
- [ ] All deployment scripts in `deploy/` directory

## Deployment Steps

### ✅ Initial Setup
- [ ] Run `chmod +x deploy/*.sh` to make scripts executable
- [ ] Run `./verify-setup.sh` to check prerequisites
- [ ] Run `./deploy/setup.sh` to create GCP infrastructure
  - [ ] Artifact Registry repository created
  - [ ] Secret Manager secrets created
  - [ ] Required APIs enabled

### ✅ Backend Deployment
- [ ] Run `./deploy/deploy-backend.sh`
- [ ] Backend builds successfully
- [ ] Backend image pushed to Artifact Registry
- [ ] Backend deployed to Cloud Run
- [ ] Backend health check passes
- [ ] Note backend URL for frontend deployment

### ✅ Frontend Deployment
- [ ] Backend URL is available (from previous step)
- [ ] Run `./deploy/deploy-frontend.sh`
- [ ] Frontend builds successfully (vite runs)
- [ ] Frontend image pushed to Artifact Registry
- [ ] Frontend deployed to Cloud Run
- [ ] Frontend container starts on port 8080
- [ ] Note frontend URL

### ✅ Domain Configuration (lightshift.local)
- [ ] Run `./deploy/setup-domain.sh`
- [ ] Domain mappings created for both services
- [ ] DNS records displayed
- [ ] Add DNS records to lightshift.local DNS server
- [ ] Wait for DNS propagation
- [ ] Verify DNS resolution:
  ```bash
  nslookup chatkit.lightshift.local
  nslookup chatkit-api.lightshift.local
  ```

### ✅ ChatKit Configuration
- [ ] Go to [OpenAI Domain Allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist)
- [ ] Add `chatkit.lightshift.local` (or Cloud Run URL)
- [ ] Copy generated domain key
- [ ] Update `CHATKIT_DOMAIN_KEY` in `.env.deploy`
- [ ] Redeploy frontend: `./deploy/deploy-frontend.sh`

## Post-Deployment Verification

### ✅ Backend Tests
- [ ] Health check responds:
  ```bash
  curl https://chatkit-api.lightshift.local/health
  # or
  curl https://[BACKEND_URL]/health
  ```
- [ ] Returns: `{"status":"healthy"}`
- [ ] Check logs for errors:
  ```bash
  gcloud run services logs read chatkit-backend --region=us-central1 --limit=20
  ```

### ✅ Frontend Tests
- [ ] Health check responds:
  ```bash
  curl https://chatkit.lightshift.local/health
  # or
  curl https://[FRONTEND_URL]/health
  ```
- [ ] Returns: `healthy`
- [ ] Open frontend URL in browser
- [ ] ChatKit UI loads
- [ ] No console errors in browser
- [ ] Check logs:
  ```bash
  gcloud run services logs read chatkit-frontend --region=us-central1 --limit=20
  ```

### ✅ Integration Tests
- [ ] Send test message: "Hello"
- [ ] ChatKit responds
- [ ] Try fact recording: "My name is [Your Name]"
- [ ] Widget appears and works
- [ ] Try weather: "What's the weather in San Francisco?"
- [ ] Weather widget displays
- [ ] Try theme: "Change to dark mode"
- [ ] Theme changes

### ✅ Monitoring Setup
- [ ] Run `./deploy/monitor.sh` to check status
- [ ] Both services show as "Ready"
- [ ] No errors in recent logs
- [ ] Metrics are being collected

## Common Issues Checklist

### ❌ If Backend Fails to Deploy
- [ ] Check `OPENAI_API_KEY` secret exists
- [ ] Verify API key is valid
- [ ] Check backend logs for errors
- [ ] Verify port 8080 is exposed
- [ ] See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#backend-deployment-fails)

### ❌ If Frontend Fails to Build
- [ ] Check `vite` is in devDependencies
- [ ] Verify `npm ci` (not `npm ci --only=production`)
- [ ] Check build logs for errors
- [ ] See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#frontend-vite-not-found-error)

### ❌ If Frontend Fails to Start
- [ ] Verify `nginx.conf.template` exists (not `nginx.conf`)
- [ ] Check `docker-entrypoint.sh` exists and is executable
- [ ] Verify `BACKEND_URL` environment variable is set
- [ ] Check nginx logs in Cloud Run
- [ ] See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#frontend-container-failed-to-start-on-port-8080)

### ❌ If Frontend Can't Reach Backend
- [ ] Verify backend URL is correct
- [ ] Check `BACKEND_URL` in frontend deployment
- [ ] Test backend health endpoint directly
- [ ] Check CORS configuration
- [ ] See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#frontend-cant-connect-to-backend)

### ❌ If Domain Mapping Fails
- [ ] Verify DNS records are configured
- [ ] Wait for DNS propagation (up to 48 hours)
- [ ] Check domain ownership
- [ ] Verify SSL certificate status
- [ ] See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#domain-mapping-fails)

### ❌ If ChatKit Shows Errors
- [ ] Verify domain is in allowlist
- [ ] Check domain key is correct
- [ ] Clear browser cache
- [ ] Check browser console for errors
- [ ] See [TROUBLESHOOTING.md](TROUBLESHOOTING.md#invalid-domain-key)

## Rollback Plan

### ✅ If Deployment Fails
- [ ] Run `./deploy/rollback.sh`
- [ ] Select service to rollback
- [ ] Choose previous revision
- [ ] Verify rollback succeeded
- [ ] Check service is working

### ✅ Complete Cleanup (if needed)
- [ ] Run `./deploy/cleanup.sh`
- [ ] Confirm deletion of services
- [ ] Optionally delete images
- [ ] Optionally delete secrets
- [ ] Start fresh deployment

## Success Criteria

### ✅ Deployment is Successful When:
- [ ] Both services show "Ready" status
- [ ] Health checks pass for both services
- [ ] Frontend loads in browser
- [ ] ChatKit UI is functional
- [ ] Test messages work
- [ ] Widgets display correctly
- [ ] No errors in logs
- [ ] Custom domain resolves (if configured)
- [ ] SSL certificates are active
- [ ] Monitoring shows healthy metrics

## Documentation

### ✅ For Team Reference
- [ ] Document your backend URL
- [ ] Document your frontend URL
- [ ] Document your custom domains
- [ ] Save DNS configuration
- [ ] Document any custom configurations
- [ ] Share access with team members
- [ ] Set up monitoring alerts

## Maintenance

### ✅ Regular Tasks
- [ ] Weekly: Review logs for errors
- [ ] Weekly: Check cost reports
- [ ] Monthly: Update dependencies
- [ ] Monthly: Review security advisories
- [ ] Quarterly: Review architecture
- [ ] Quarterly: Update documentation

---

## Quick Commands Reference

```bash
# Deploy everything
./deploy/deploy-all.sh

# Deploy backend only
./deploy/deploy-backend.sh

# Deploy frontend only
./deploy/deploy-frontend.sh

# Set up domains
./deploy/setup-domain.sh

# Monitor services
./deploy/monitor.sh

# View logs
gcloud run services logs read chatkit-backend --region=us-central1
gcloud run services logs read chatkit-frontend --region=us-central1

# Rollback
./deploy/rollback.sh

# Cleanup
./deploy/cleanup.sh
```

---

**Last Updated:** January 2025
