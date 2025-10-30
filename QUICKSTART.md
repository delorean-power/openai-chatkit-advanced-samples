# Quick Start Guide - Cloud Run Deployment

Get your ChatKit application running on Cloud Run with `lightshift.local` domain in under 10 minutes.

## Prerequisites Checklist

- [ ] Google Cloud account with billing enabled
- [ ] [gcloud CLI](https://cloud.google.com/sdk/docs/install) installed
- [ ] [Docker](https://docs.docker.com/get-docker/) installed
- [ ] OpenAI API key from [platform.openai.com](https://platform.openai.com/api-keys)

## 5-Minute Deployment

### 1. Configure (2 minutes)

```bash
# Navigate to project
cd /Users/admac/Developer/github/openai-chatkit-advanced-samples

# Copy environment template
cp .env.deploy.template .env.deploy

# Edit with your values
nano .env.deploy
```

**Minimum required configuration:**
```bash
GCP_PROJECT_ID=your-project-id
GCP_REGION=us-central1
OPENAI_API_KEY=sk-proj-your-key-here

# Internal domain (lightshift.local pattern)
BACKEND_CUSTOM_DOMAIN=chatkit-api.lightshift.local
FRONTEND_CUSTOM_DOMAIN=chatkit.lightshift.local
```

### 2. Deploy (3 minutes)

```bash
# Make scripts executable
chmod +x deploy/*.sh

# Authenticate with GCP
gcloud auth login

# Deploy everything
./deploy/deploy-all.sh
```

### 3. Set Up Internal Domain

```bash
# Configure domain mapping for lightshift.local
./deploy/setup-domain.sh

# Follow the instructions to add DNS records
```

### 4. Access Your App

After deployment and DNS configuration:
```
Frontend: https://chatkit.lightshift.local
Backend:  https://chatkit-api.lightshift.local
```

Or use the Cloud Run URLs directly:
```
Frontend URL: https://chatkit-frontend-xxxxx-uc.a.run.app
Backend URL: https://chatkit-backend-xxxxx-uc.a.run.app
```

Open the Frontend URL in your browser and start chatting!

## Post-Deployment Setup

### Configure ChatKit Domain Key (Required)

Add your internal domain to the allowlist:

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

### Configure DNS

Add the DNS records provided by `setup-domain.sh` to your `lightshift.local` DNS configuration. See [LIGHTSHIFT_SETUP.md](LIGHTSHIFT_SETUP.md) for detailed instructions.

## Common Commands

```bash
# View service status
./deploy/monitor.sh

# View logs
gcloud run services logs read chatkit-backend --region=us-central1

# Redeploy backend
./deploy/deploy-backend.sh

# Redeploy frontend
./deploy/deploy-frontend.sh

# Rollback if needed
./deploy/rollback.sh
```

## Testing Your Deployment

Try these prompts:
1. "My name is [Your Name]" - Tests fact recording
2. "What's the weather in San Francisco?" - Tests weather widget
3. "Change the theme to dark mode" - Tests theme switching

## Next Steps

- [ ] Read [CLOUD_RUN_DEPLOYMENT.md](CLOUD_RUN_DEPLOYMENT.md) for detailed documentation
- [ ] Add custom agents and workflows
- [ ] Set up custom domain
- [ ] Configure monitoring and alerts
- [ ] Review security best practices

## Troubleshooting

### Deployment fails?

```bash
# Check GCP authentication
gcloud auth list

# Verify project
gcloud config get-value project

# Check API enablement
gcloud services list --enabled
```

### Can't access the app?

```bash
# Check service status
gcloud run services describe chatkit-frontend --region=us-central1

# Test backend health
curl https://your-backend-url/health
```

### Need help?

- Full documentation: [CLOUD_RUN_DEPLOYMENT.md](CLOUD_RUN_DEPLOYMENT.md)
- OpenAI docs: [platform.openai.com/docs](https://platform.openai.com/docs)
- Cloud Run docs: [cloud.google.com/run/docs](https://cloud.google.com/run/docs)

## Cost Estimate

With default settings (0 minimum instances):
- **Development/Testing**: ~$0-5/month
- **Low Traffic**: ~$10-20/month
- **Medium Traffic**: ~$50-100/month

Costs scale with:
- Request volume
- Minimum instances
- Memory/CPU allocation
- Data transfer

Monitor costs: [GCP Billing Console](https://console.cloud.google.com/billing)
