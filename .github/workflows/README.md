# GitHub Actions CI/CD Setup

This directory contains GitHub Actions workflows for automated deployment to Cloud Run.

## Setup Instructions

### 1. Enable Workload Identity Federation

This is the recommended way to authenticate GitHub Actions with GCP (no service account keys needed).

```bash
# Set variables
export PROJECT_ID="your-project-id"
export POOL_NAME="github-actions-pool"
export PROVIDER_NAME="github-actions-provider"
export SERVICE_ACCOUNT_NAME="github-actions-sa"
export REPO="your-github-username/openai-chatkit-advanced-samples"

# Create service account
gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
  --display-name="GitHub Actions Service Account"

# Grant necessary roles
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.serviceAccountUser"

# Create Workload Identity Pool
gcloud iam workload-identity-pools create $POOL_NAME \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Create Workload Identity Provider
gcloud iam workload-identity-pools providers create-oidc $PROVIDER_NAME \
  --location="global" \
  --workload-identity-pool=$POOL_NAME \
  --display-name="GitHub Actions Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Allow GitHub Actions to impersonate service account
gcloud iam service-accounts add-iam-policy-binding \
  "$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/iam.workloadIdentityUser" \
  --member="principalSet://iam.googleapis.com/projects/$(gcloud projects describe $PROJECT_ID --format='value(projectNumber)')/locations/global/workloadIdentityPools/$POOL_NAME/attribute.repository/$REPO"

# Get the Workload Identity Provider resource name
gcloud iam workload-identity-pools providers describe $PROVIDER_NAME \
  --location="global" \
  --workload-identity-pool=$POOL_NAME \
  --format="value(name)"
```

### 2. Configure GitHub Secrets

Add these secrets to your GitHub repository (Settings → Secrets and variables → Actions):

- `GCP_PROJECT_ID`: Your GCP project ID
- `WIF_PROVIDER`: The Workload Identity Provider resource name (from step 1)
- `WIF_SERVICE_ACCOUNT`: `github-actions-sa@your-project-id.iam.gserviceaccount.com`
- `CHATKIT_DOMAIN_KEY`: Your ChatKit domain key (optional)

### 3. Enable Workflow

The workflow is triggered on:
- Push to `main` branch (production)
- Push to `staging` branch (staging)
- Manual trigger via GitHub Actions UI

## Workflow Overview

The deployment workflow consists of three jobs:

1. **deploy-backend**: Builds and deploys the backend service
2. **deploy-frontend**: Builds and deploys the frontend service (depends on backend)
3. **smoke-test**: Runs basic health checks on both services

## Manual Deployment

To manually trigger a deployment:

1. Go to Actions tab in GitHub
2. Select "Deploy to Cloud Run" workflow
3. Click "Run workflow"
4. Select branch and click "Run workflow"

## Monitoring Deployments

View deployment status:
- GitHub Actions tab shows workflow runs
- Cloud Run console shows service revisions
- Cloud Logging shows application logs

## Rollback

If a deployment fails or causes issues:

1. Go to Cloud Run console
2. Select the service
3. Go to "Revisions" tab
4. Select a previous revision
5. Click "Manage Traffic"
6. Route 100% traffic to the previous revision

Or use the rollback script:
```bash
./deploy/rollback.sh
```

## Environment-Specific Deployments

To set up separate staging and production environments:

1. Create separate GCP projects or use different service names
2. Update workflow to use environment-specific variables
3. Add environment protection rules in GitHub

Example:
```yaml
jobs:
  deploy-backend:
    environment:
      name: ${{ github.ref == 'refs/heads/main' && 'production' || 'staging' }}
```

## Troubleshooting

### Authentication Errors

If you see authentication errors:
1. Verify Workload Identity Federation is set up correctly
2. Check service account permissions
3. Ensure GitHub secrets are configured

### Build Failures

If builds fail:
1. Check Docker build logs in GitHub Actions
2. Test build locally: `./deploy/local-test.sh`
3. Verify all dependencies are in requirements files

### Deployment Failures

If deployments fail:
1. Check Cloud Run deployment logs
2. Verify secrets exist in Secret Manager
3. Check service quotas and limits

## Best Practices

1. **Use separate environments**: staging and production
2. **Enable branch protection**: require reviews before merging to main
3. **Monitor deployments**: set up alerts for failures
4. **Test locally first**: use `./deploy/local-test.sh`
5. **Review logs**: check both GitHub Actions and Cloud Run logs
