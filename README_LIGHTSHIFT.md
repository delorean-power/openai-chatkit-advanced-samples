# ChatKit on Lightshift.local

Quick reference for deploying ChatKit following your internal domain pattern.

## Your Services

| Service | Domain | Purpose |
|---------|--------|---------|
| Mage | `mage.lightshift.local` | Data pipeline orchestration |
| ChatKit Frontend | `chatkit.lightshift.local` | AI chat interface |
| ChatKit Backend | `chatkit-api.lightshift.local` | API and agent logic |

## Quick Deploy

```bash
# 1. Configure
cp .env.deploy.template .env.deploy

# Edit these values:
# GCP_PROJECT_ID=your-project-id
# OPENAI_API_KEY=sk-proj-your-key
# BACKEND_CUSTOM_DOMAIN=chatkit-api.lightshift.local
# FRONTEND_CUSTOM_DOMAIN=chatkit.lightshift.local

# 2. Deploy to Cloud Run
chmod +x deploy/*.sh
./deploy/deploy-all.sh

# 3. Set up domain mapping
./deploy/setup-domain.sh

# 4. Configure DNS (add records shown by setup-domain.sh)

# 5. Add to ChatKit allowlist
# https://platform.openai.com/settings/organization/security/domain-allowlist
# Add: chatkit.lightshift.local

# 6. Update domain key and redeploy
# Edit .env.deploy with CHATKIT_DOMAIN_KEY
./deploy/deploy-frontend.sh
```

## Access

- **Frontend**: https://chatkit.lightshift.local
- **Backend API**: https://chatkit-api.lightshift.local
- **Health Check**: https://chatkit-api.lightshift.local/health

## Common Tasks

```bash
# View logs
gcloud run services logs read chatkit-backend --region=us-central1

# Monitor services
./deploy/monitor.sh

# Update backend
./deploy/deploy-backend.sh

# Update frontend
./deploy/deploy-frontend.sh

# Rollback if needed
./deploy/rollback.sh
```

## DNS Configuration

After running `./deploy/setup-domain.sh`, add the provided DNS records to your lightshift.local DNS configuration. The records will look like:

```
chatkit.lightshift.local.      A    216.239.32.21
chatkit.lightshift.local.      A    216.239.34.21
chatkit-api.lightshift.local.  A    216.239.32.21
chatkit-api.lightshift.local.  A    216.239.34.21
# (plus additional A and AAAA records)
```

## Documentation

- **[LIGHTSHIFT_SETUP.md](LIGHTSHIFT_SETUP.md)** - Detailed setup guide
- **[QUICKSTART.md](QUICKSTART.md)** - 5-minute deployment
- **[CLOUD_RUN_DEPLOYMENT.md](CLOUD_RUN_DEPLOYMENT.md)** - Complete reference

## Troubleshooting

**DNS not resolving?**
```bash
nslookup chatkit.lightshift.local
```

**Service not accessible?**
```bash
# Check domain mapping
gcloud run domain-mappings describe \
  --domain=chatkit.lightshift.local \
  --region=us-central1

# Check service status
gcloud run services describe chatkit-frontend \
  --region=us-central1
```

**Frontend can't reach backend?**
```bash
# Test backend directly
curl https://chatkit-api.lightshift.local/health

# Check frontend environment
gcloud run services describe chatkit-frontend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"
```

## Architecture

```
Internal Network (lightshift.local)
    ↓
chatkit.lightshift.local
    ↓
chatkit-api.lightshift.local
    ↓
OpenAI API
```

## Cost

With default settings (0 minimum instances):
- Development: ~$0-5/month
- Production: Scales with usage

## Support

See [LIGHTSHIFT_SETUP.md](LIGHTSHIFT_SETUP.md) for detailed configuration and troubleshooting.
