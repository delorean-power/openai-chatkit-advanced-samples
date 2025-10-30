# OpenAI ChatKit Cloud Run Deployment Guide

This guide provides comprehensive instructions for deploying the OpenAI ChatKit application to Google Cloud Run with custom agents and workflows.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Architecture Overview](#architecture-overview)
3. [Quick Start](#quick-start)
4. [Detailed Setup](#detailed-setup)
5. [Custom Agents & Workflows](#custom-agents--workflows)
6. [Domain Configuration](#domain-configuration)
7. [Monitoring & Logging](#monitoring--logging)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)

## Prerequisites

### Required Tools

- **Google Cloud SDK (gcloud)**: [Install Guide](https://cloud.google.com/sdk/docs/install)
- **Docker**: [Install Guide](https://docs.docker.com/get-docker/)
- **OpenAI API Key**: Get from [OpenAI Platform](https://platform.openai.com/api-keys)
- **GCP Project**: With billing enabled

### Required GCP APIs

The setup script will enable these automatically:
- Cloud Run API
- Cloud Build API
- Artifact Registry API
- Secret Manager API
- Cloud Logging API
- Cloud Monitoring API

### Permissions Required

Your GCP account needs these roles:
- `roles/run.admin` - Cloud Run Admin
- `roles/iam.serviceAccountUser` - Service Account User
- `roles/artifactregistry.admin` - Artifact Registry Admin
- `roles/secretmanager.admin` - Secret Manager Admin

## Architecture Overview

```
┌─────────────────┐
│   User Browser  │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Cloud Run (Frontend)           │
│  - Nginx serving React SPA      │
│  - Proxies API calls to backend │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  Cloud Run (Backend)            │
│  - FastAPI + ChatKit Server     │
│  - OpenAI Agents SDK            │
│  - Custom tools & workflows     │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│  OpenAI API                     │
│  - GPT Models                   │
│  - Agent Builder Workflows      │
└─────────────────────────────────┘
```

### Key Components

1. **Backend Service**
   - FastAPI application with ChatKit server
   - Handles chat requests and tool execution
   - Integrates with OpenAI Agents SDK
   - Stateless design for horizontal scaling

2. **Frontend Service**
   - React SPA with ChatKit web component
   - Nginx for serving static assets
   - Reverse proxy for API calls
   - Optimized for performance

3. **Secret Manager**
   - Stores OpenAI API keys securely
   - Manages ChatKit domain keys
   - Workflow IDs and other secrets

4. **Artifact Registry**
   - Stores Docker images
   - Version control for deployments
   - Fast image pulls for Cloud Run

## Quick Start

### 1. Clone and Configure

```bash
cd /Users/admac/Developer/github/openai-chatkit-advanced-samples

# Copy environment template
cp .env.deploy.template .env.deploy

# Edit configuration
nano .env.deploy
```

### 2. Update Configuration

Edit `.env.deploy` with your values:

```bash
# Required
GCP_PROJECT_ID=your-project-id
GCP_REGION=us-central1
OPENAI_API_KEY=sk-proj-your-key-here

# Optional (can be set later)
CHATKIT_DOMAIN_KEY=
CHATKIT_WORKFLOW_ID=
```

### 3. Deploy Everything

```bash
# Make scripts executable
chmod +x deploy/*.sh

# Run full deployment
./deploy/deploy-all.sh
```

This will:
1. Set up GCP infrastructure
2. Create secrets
3. Deploy backend service
4. Deploy frontend service

### 4. Configure Domain Allowlist

After deployment, you'll receive a frontend URL like:
```
https://chatkit-frontend-xxxxx-uc.a.run.app
```

1. Go to [OpenAI Domain Allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist)
2. Add your Cloud Run domain
3. Copy the generated domain key
4. Update `.env.deploy` with `CHATKIT_DOMAIN_KEY`
5. Redeploy frontend:
   ```bash
   ./deploy/deploy-frontend.sh
   ```

## Detailed Setup

### Step-by-Step Deployment

#### 1. Initial Setup

```bash
# Authenticate with GCP
gcloud auth login
gcloud auth application-default login

# Set your project
gcloud config set project YOUR_PROJECT_ID

# Run setup script
./deploy/setup.sh
```

This creates:
- Artifact Registry repository
- Secret Manager secrets
- Required service accounts

#### 2. Deploy Backend

```bash
./deploy/deploy-backend.sh
```

This will:
- Build Docker image from `backend/Dockerfile`
- Push to Artifact Registry
- Deploy to Cloud Run
- Configure secrets and environment variables
- Output the backend URL

**Backend URL Example:**
```
https://chatkit-backend-xxxxx-uc.a.run.app
```

#### 3. Deploy Frontend

```bash
./deploy/deploy-frontend.sh
```

This will:
- Build Docker image with backend URL
- Push to Artifact Registry
- Deploy to Cloud Run with Nginx
- Configure environment variables
- Output the frontend URL

**Frontend URL Example:**
```
https://chatkit-frontend-xxxxx-uc.a.run.app
```

### Manual Deployment Steps

If you prefer manual control:

#### Backend

```bash
cd backend

# Build image
docker build -t gcr.io/YOUR_PROJECT/chatkit-backend .

# Push image
docker push gcr.io/YOUR_PROJECT/chatkit-backend

# Deploy
gcloud run deploy chatkit-backend \
  --image=gcr.io/YOUR_PROJECT/chatkit-backend \
  --region=us-central1 \
  --allow-unauthenticated \
  --set-secrets="OPENAI_API_KEY=openai-api-key:latest"
```

#### Frontend

```bash
cd frontend

# Build with backend URL
docker build \
  --build-arg VITE_CHATKIT_API_URL=https://your-backend-url \
  -t gcr.io/YOUR_PROJECT/chatkit-frontend .

# Push image
docker push gcr.io/YOUR_PROJECT/chatkit-frontend

# Deploy
gcloud run deploy chatkit-frontend \
  --image=gcr.io/YOUR_PROJECT/chatkit-frontend \
  --region=us-central1 \
  --allow-unauthenticated
```

## Custom Agents & Workflows

### Using Agent Builder Workflows

1. **Create Workflow in Agent Builder**
   - Go to [OpenAI Platform](https://platform.openai.com/agent-builder)
   - Build your multi-agent workflow
   - Publish and get the workflow ID

2. **Configure Backend**

Update `backend/app/chat.py` to use your workflow:

```python
from openai import OpenAI

client = OpenAI()

# Use your workflow ID
WORKFLOW_ID = "your-workflow-id-here"

async def process_chat(message: str):
    response = await client.chat.completions.create(
        model=WORKFLOW_ID,  # Use workflow as model
        messages=[{"role": "user", "content": message}]
    )
    return response
```

3. **Update Environment**

```bash
# Add to .env.deploy
CHATKIT_WORKFLOW_ID=your-workflow-id

# Redeploy
./deploy/deploy-backend.sh
```

### Adding Custom Tools

Create new tools in `backend/app/`:

```python
# backend/app/custom_tool.py
from chatkit.server import Tool

class MyCustomTool(Tool):
    name = "my_custom_tool"
    description = "Description of what this tool does"
    
    async def execute(self, **kwargs):
        # Your tool logic here
        return {"result": "success"}
```

Register in `backend/app/chat.py`:

```python
from .custom_tool import MyCustomTool

# Add to tools list
tools = [
    RecordFactTool(),
    GetWeatherTool(),
    MyCustomTool(),  # Your custom tool
]
```

### Example: Email Finder Tool

```python
# backend/app/email_finder.py
from chatkit.server import Tool
import httpx

class EmailFinderTool(Tool):
    name = "find_email"
    description = "Find email addresses for a person at a company"
    
    parameters = {
        "type": "object",
        "properties": {
            "first_name": {"type": "string"},
            "last_name": {"type": "string"},
            "company_domain": {"type": "string"}
        },
        "required": ["first_name", "last_name", "company_domain"]
    }
    
    async def execute(self, first_name: str, last_name: str, company_domain: str):
        # Your email finding logic
        async with httpx.AsyncClient() as client:
            # Call your email finder API
            response = await client.post(
                "https://your-email-finder-api.com/find",
                json={
                    "first_name": first_name,
                    "last_name": last_name,
                    "domain": company_domain
                }
            )
            return response.json()
```

### Integrating with Existing Workflows

If you have existing agents/workflows:

1. **API Integration**
   ```python
   # backend/app/workflow_integration.py
   import httpx
   
   async def call_existing_workflow(input_data):
       async with httpx.AsyncClient() as client:
           response = await client.post(
               "https://your-workflow-api.com/execute",
               json=input_data,
               headers={"Authorization": f"Bearer {API_KEY}"}
           )
           return response.json()
   ```

2. **Add as ChatKit Tool**
   ```python
   class WorkflowTool(Tool):
       name = "execute_workflow"
       
       async def execute(self, **kwargs):
           result = await call_existing_workflow(kwargs)
           return result
   ```

## Domain Configuration

### Setting Up Custom Domain

1. **Register Domain in Cloud Run**

```bash
gcloud run domain-mappings create \
  --service=chatkit-frontend \
  --domain=chat.yourdomain.com \
  --region=us-central1
```

2. **Update DNS Records**

Add the DNS records provided by Cloud Run to your domain registrar.

3. **Update ChatKit Allowlist**

Add `chat.yourdomain.com` to your [OpenAI domain allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist).

4. **Update Configuration**

```bash
# Update .env.deploy
CUSTOM_DOMAIN=chat.yourdomain.com

# Redeploy
./deploy/deploy-frontend.sh
```

### SSL/TLS Configuration

Cloud Run automatically provides SSL certificates for:
- Default `*.run.app` domains
- Custom domains (via Google-managed certificates)

No additional configuration needed!

## Monitoring & Logging

### Using Monitor Script

```bash
./deploy/monitor.sh
```

This provides:
- Service health status
- Recent logs
- Quick access to metrics
- Interactive menu for common tasks

### View Logs

```bash
# Backend logs
gcloud run services logs read chatkit-backend \
  --region=us-central1 \
  --limit=100

# Frontend logs
gcloud run services logs read chatkit-frontend \
  --region=us-central1 \
  --limit=100

# Live tail
gcloud run services logs tail chatkit-backend \
  --region=us-central1
```

### Metrics & Monitoring

Access Cloud Run metrics:
- Request count
- Request latency
- Error rate
- Container CPU/Memory usage
- Instance count

```bash
# Open in browser
open "https://console.cloud.google.com/run?project=YOUR_PROJECT_ID"
```

### Setting Up Alerts

```bash
# Create alert for high error rate
gcloud alpha monitoring policies create \
  --notification-channels=CHANNEL_ID \
  --display-name="ChatKit High Error Rate" \
  --condition-display-name="Error rate > 5%" \
  --condition-threshold-value=0.05 \
  --condition-threshold-duration=300s
```

### Logging Best Practices

1. **Structured Logging**
   ```python
   import logging
   import json
   
   logger = logging.getLogger(__name__)
   
   logger.info(json.dumps({
       "event": "chat_request",
       "user_id": user_id,
       "duration_ms": duration
   }))
   ```

2. **Log Levels**
   - `ERROR`: Critical issues requiring attention
   - `WARNING`: Important but non-critical issues
   - `INFO`: General operational information
   - `DEBUG`: Detailed debugging information

## Troubleshooting

### Common Issues

#### 1. Backend Deployment Fails

**Error:** `OPENAI_API_KEY not found`

**Solution:**
```bash
# Verify secret exists
gcloud secrets describe openai-api-key

# Update secret
echo -n "sk-proj-your-key" | gcloud secrets versions add openai-api-key --data-file=-

# Redeploy
./deploy/deploy-backend.sh
```

#### 2. Frontend Can't Connect to Backend

**Error:** `Failed to fetch` or CORS errors

**Solution:**
```bash
# Check backend URL in frontend deployment
gcloud run services describe chatkit-frontend \
  --region=us-central1 \
  --format="value(spec.template.spec.containers[0].env)"

# Verify backend is accessible
curl https://your-backend-url/health

# Redeploy with correct backend URL
./deploy/deploy-frontend.sh
```

#### 3. ChatKit Domain Key Issues

**Error:** `Invalid domain key`

**Solution:**
1. Verify domain is in allowlist
2. Check domain key is correct in `.env.deploy`
3. Ensure frontend is deployed with the key:
   ```bash
   ./deploy/deploy-frontend.sh
   ```

#### 4. Memory/CPU Issues

**Error:** Container running out of memory

**Solution:**
```bash
# Increase memory in .env.deploy
BACKEND_MEMORY=1Gi
BACKEND_CPU=2

# Redeploy
./deploy/deploy-backend.sh
```

#### 5. Cold Start Latency

**Issue:** First request is slow

**Solution:**
```bash
# Set minimum instances in .env.deploy
BACKEND_MIN_INSTANCES=1

# Redeploy
./deploy/deploy-backend.sh
```

### Debugging Commands

```bash
# Check service status
gcloud run services describe chatkit-backend --region=us-central1

# View recent errors
gcloud run services logs read chatkit-backend \
  --region=us-central1 \
  --filter="severity>=ERROR" \
  --limit=50

# Test backend directly
curl -X POST https://your-backend-url/chatkit \
  -H "Content-Type: application/json" \
  -d '{"message": "test"}'

# Check container health
gcloud run revisions describe REVISION_NAME \
  --region=us-central1
```

### Rollback Procedure

If a deployment causes issues:

```bash
./deploy/rollback.sh
```

Or manually:

```bash
# List revisions
gcloud run revisions list \
  --service=chatkit-backend \
  --region=us-central1

# Rollback to specific revision
gcloud run services update-traffic chatkit-backend \
  --region=us-central1 \
  --to-revisions=REVISION_NAME=100
```

## Best Practices

### Security

1. **Never Commit Secrets**
   - Use `.env.deploy` (gitignored)
   - Use Secret Manager for production

2. **Least Privilege**
   - Use service accounts with minimal permissions
   - Restrict API access

3. **Network Security**
   - Use VPC connectors for private resources
   - Enable Cloud Armor for DDoS protection

4. **Authentication**
   ```bash
   # Require authentication
   gcloud run services update chatkit-backend \
     --no-allow-unauthenticated
   ```

### Performance

1. **Optimize Container Size**
   - Use multi-stage builds
   - Minimize dependencies
   - Use `.dockerignore`

2. **Configure Scaling**
   ```bash
   # In .env.deploy
   BACKEND_MIN_INSTANCES=1  # Reduce cold starts
   BACKEND_MAX_INSTANCES=100  # Handle traffic spikes
   BACKEND_CONCURRENCY=80  # Requests per container
   ```

3. **Enable CDN**
   ```bash
   gcloud compute backend-services update BACKEND_SERVICE \
     --enable-cdn
   ```

### Cost Optimization

1. **Right-Size Resources**
   - Start small (256Mi, 1 CPU)
   - Monitor and adjust based on metrics

2. **Use Minimum Instances Wisely**
   - Set to 0 for dev/staging
   - Set to 1+ for production (reduces cold starts)

3. **Monitor Costs**
   ```bash
   # View Cloud Run costs
   gcloud billing accounts list
   ```

### Development Workflow

1. **Local Development**
   ```bash
   # Use local setup for development
   npm run backend  # Terminal 1
   npm run frontend  # Terminal 2
   ```

2. **Staging Environment**
   ```bash
   # Create staging deployment
   cp .env.deploy .env.staging
   # Update with staging values
   # Deploy to staging
   ```

3. **CI/CD Integration**
   - Use Cloud Build for automated deployments
   - Implement automated testing
   - Use staging → production promotion

### Monitoring Strategy

1. **Key Metrics to Track**
   - Request latency (p50, p95, p99)
   - Error rate
   - Request count
   - Container instances
   - Memory/CPU usage

2. **Set Up Alerts**
   - Error rate > 5%
   - Latency p95 > 2s
   - Memory usage > 80%

3. **Regular Reviews**
   - Weekly metric reviews
   - Monthly cost analysis
   - Quarterly architecture review

## Additional Resources

- [OpenAI ChatKit Documentation](https://platform.openai.com/docs/guides/chatkit)
- [OpenAI Agent Builder](https://platform.openai.com/agent-builder)
- [OpenAI Agents SDK](https://github.com/openai/openai-agents-python)
- [Cloud Run Documentation](https://cloud.google.com/run/docs)
- [AgentKit Walkthrough](https://cookbook.openai.com/examples/agentkit/agentkit_walkthrough)

## Support

For issues and questions:
- OpenAI: [OpenAI Help Center](https://help.openai.com/)
- Cloud Run: [GCP Support](https://cloud.google.com/support)
- This Project: Create an issue in the repository

---

**Last Updated:** January 2025
**Version:** 1.0.0
