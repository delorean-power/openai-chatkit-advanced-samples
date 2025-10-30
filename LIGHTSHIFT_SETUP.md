# Lightshift.local Domain Setup

This guide covers setting up ChatKit with your internal `lightshift.local` domain pattern, following the same configuration as your other services (e.g., `mage.lightshift.local`).

## Overview

Your ChatKit services will be accessible at:
- **Frontend**: `chatkit.lightshift.local`
- **Backend API**: `chatkit-api.lightshift.local`

This follows the same pattern as your other Cloud Run services.

## Quick Setup

### 1. Configure Deployment

Edit `.env.deploy`:

```bash
# Internal Domain Configuration
INTERNAL_DOMAIN=lightshift.local
BACKEND_SUBDOMAIN=chatkit-api
FRONTEND_SUBDOMAIN=chatkit

# Custom Domain (internal)
CUSTOM_DOMAIN=lightshift.local
BACKEND_CUSTOM_DOMAIN=chatkit-api.lightshift.local
FRONTEND_CUSTOM_DOMAIN=chatkit.lightshift.local
```

### 2. Deploy Services

```bash
# Deploy backend and frontend to Cloud Run
./deploy/deploy-all.sh
```

### 3. Set Up Domain Mapping

```bash
# Create domain mappings in Cloud Run
./deploy/setup-domain.sh
```

This will:
- Create domain mappings for both services
- Display the DNS records you need to configure
- Provide the exact DNS configuration needed

### 4. Configure DNS

Add the DNS records shown by `setup-domain.sh` to your `lightshift.local` DNS configuration.

**Example DNS records** (actual values will be provided by the script):

```
# Backend API
chatkit-api.lightshift.local.  A      216.239.32.21
chatkit-api.lightshift.local.  A      216.239.34.21
chatkit-api.lightshift.local.  A      216.239.36.21
chatkit-api.lightshift.local.  A      216.239.38.21
chatkit-api.lightshift.local.  AAAA   2001:4860:4802:32::15
chatkit-api.lightshift.local.  AAAA   2001:4860:4802:34::15
chatkit-api.lightshift.local.  AAAA   2001:4860:4802:36::15
chatkit-api.lightshift.local.  AAAA   2001:4860:4802:38::15

# Frontend
chatkit.lightshift.local.      A      216.239.32.21
chatkit.lightshift.local.      A      216.239.34.21
chatkit.lightshift.local.      A      216.239.36.21
chatkit.lightshift.local.      A      216.239.38.21
chatkit.lightshift.local.      AAAA   2001:4860:4802:32::15
chatkit.lightshift.local.      AAAA   2001:4860:4802:34::15
chatkit.lightshift.local.      AAAA   2001:4860:4802:36::15
chatkit.lightshift.local.      AAAA   2001:4860:4802:38::15
```

### 5. Configure ChatKit Domain Allowlist

1. Go to [OpenAI Domain Allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist)
2. Add: `chatkit.lightshift.local`
3. Copy the generated domain key
4. Update `.env.deploy`:
   ```bash
   CHATKIT_DOMAIN_KEY=your-domain-key-here
   ```
5. Redeploy frontend:
   ```bash
   ./deploy/deploy-frontend.sh
   ```

### 6. Test Your Deployment

```bash
# Test backend
curl https://chatkit-api.lightshift.local/health

# Test frontend
open https://chatkit.lightshift.local
```

## DNS Configuration Details

### If Using Cloud DNS

```bash
# Get your DNS zone
ZONE_NAME="lightshift-local"

# Add backend records
gcloud dns record-sets transaction start --zone=$ZONE_NAME

# Get the actual IPs from setup-domain.sh output
gcloud dns record-sets transaction add \
  --name=chatkit-api.lightshift.local. \
  --type=A \
  --zone=$ZONE_NAME \
  --ttl=300 \
  "216.239.32.21" "216.239.34.21" "216.239.36.21" "216.239.38.21"

gcloud dns record-sets transaction add \
  --name=chatkit.lightshift.local. \
  --type=A \
  --zone=$ZONE_NAME \
  --ttl=300 \
  "216.239.32.21" "216.239.34.21" "216.239.36.21" "216.239.38.21"

gcloud dns record-sets transaction execute --zone=$ZONE_NAME
```

### If Using Internal DNS Server

Add the A records to your internal DNS server configuration. The exact method depends on your DNS server (BIND, dnsmasq, etc.).

### Verification

```bash
# Check DNS resolution
nslookup chatkit.lightshift.local
nslookup chatkit-api.lightshift.local

# Or with dig
dig chatkit.lightshift.local
dig chatkit-api.lightshift.local
```

## Architecture with Internal Domain

```
User (Internal Network)
    ↓
chatkit.lightshift.local (Frontend)
    ↓
chatkit-api.lightshift.local (Backend)
    ↓
OpenAI API
```

## Updating Services

When you update your services, the domain mappings remain intact:

```bash
# Update backend
./deploy/deploy-backend.sh

# Update frontend
./deploy/deploy-frontend.sh

# No need to reconfigure DNS
```

## Troubleshooting

### Domain Mapping Not Working

```bash
# Check domain mapping status
gcloud run domain-mappings describe \
  --domain=chatkit.lightshift.local \
  --region=us-central1

# Check service status
gcloud run services describe chatkit-frontend \
  --region=us-central1
```

### DNS Not Resolving

```bash
# Verify DNS records are configured
nslookup chatkit.lightshift.local

# Check DNS propagation
dig chatkit.lightshift.local +trace
```

### SSL Certificate Issues

Cloud Run automatically provisions SSL certificates for custom domains. This may take a few minutes after DNS configuration.

```bash
# Check certificate status
gcloud run domain-mappings describe \
  --domain=chatkit.lightshift.local \
  --region=us-central1 \
  --format="get(status.certificateStatus)"
```

### Backend Connection Issues

If frontend can't connect to backend:

1. Verify backend domain mapping:
   ```bash
   curl https://chatkit-api.lightshift.local/health
   ```

2. Check frontend environment variables:
   ```bash
   gcloud run services describe chatkit-frontend \
     --region=us-central1 \
     --format="value(spec.template.spec.containers[0].env)"
   ```

3. Redeploy frontend with correct backend URL:
   ```bash
   # Update .env.deploy
   BACKEND_URL=https://chatkit-api.lightshift.local
   
   # Redeploy
   ./deploy/deploy-frontend.sh
   ```

## Consistent with Other Services

This setup follows the same pattern as your other internal services:

| Service | Domain |
|---------|--------|
| Mage | `mage.lightshift.local` |
| ChatKit Frontend | `chatkit.lightshift.local` |
| ChatKit Backend | `chatkit-api.lightshift.local` |

All services use:
- Cloud Run for hosting
- Custom domain mapping
- Internal DNS resolution
- Automatic SSL certificates

## Security Considerations

### Internal Network Access

If `lightshift.local` is only accessible on your internal network:

1. **VPC Configuration**: Ensure Cloud Run services can communicate
2. **Firewall Rules**: Configure appropriate ingress/egress rules
3. **Service Accounts**: Use proper IAM permissions

### External Access

If you need external access while maintaining internal domains:

1. Use Cloud Run's built-in authentication
2. Set up Cloud IAP (Identity-Aware Proxy)
3. Configure VPN access to internal network

## Monitoring

Monitor your services at the internal domains:

```bash
# View logs
gcloud run services logs read chatkit-frontend --region=us-central1
gcloud run services logs read chatkit-backend --region=us-central1

# Check metrics
./deploy/monitor.sh
```

## Cost Optimization

Using custom domains doesn't incur additional costs. You only pay for:
- Cloud Run usage (requests, CPU, memory)
- Cloud DNS queries (if using Cloud DNS)
- Data transfer

## Next Steps

1. ✅ Deploy services to Cloud Run
2. ✅ Set up domain mapping
3. ✅ Configure DNS
4. ✅ Add to ChatKit allowlist
5. ✅ Test internal access
6. 📝 Document for your team
7. 📝 Set up monitoring alerts
8. 📝 Configure backup/disaster recovery

## Support

For issues specific to `lightshift.local` configuration:
- Check your internal DNS server logs
- Verify network connectivity to Cloud Run
- Review firewall rules
- Test with Cloud Run's default URLs first

For general deployment issues, see:
- [CLOUD_RUN_DEPLOYMENT.md](CLOUD_RUN_DEPLOYMENT.md)
- [QUICKSTART.md](QUICKSTART.md)
