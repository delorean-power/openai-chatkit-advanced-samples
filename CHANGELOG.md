# Changelog

All notable changes to this project will be documented in this file.

## [1.0.0] - 2025-01-30

### Added - Cloud Run Deployment Support

#### Infrastructure
- Multi-stage Dockerfiles for backend (Python/FastAPI) and frontend (Node/React/Nginx)
- Docker ignore files for optimized builds
- Nginx configuration with SPA routing and API proxy support
- Health check endpoints for both services

#### Deployment Scripts
- `deploy/setup.sh` - GCP infrastructure setup (APIs, secrets, Artifact Registry)
- `deploy/deploy-backend.sh` - Backend deployment automation
- `deploy/deploy-frontend.sh` - Frontend deployment automation
- `deploy/deploy-all.sh` - One-command full deployment
- `deploy/setup-domain.sh` - Internal domain mapping for lightshift.local
- `deploy/monitor.sh` - Interactive monitoring and management
- `deploy/rollback.sh` - Easy service rollback
- `deploy/cleanup.sh` - Resource cleanup
- `deploy/local-test.sh` - Local Docker testing
- `deploy/local-cleanup.sh` - Local Docker cleanup
- `verify-setup.sh` - Setup verification script

#### CI/CD
- GitHub Actions workflow for automated deployments
- Workload Identity Federation setup guide
- Automated smoke tests and health checks

#### Documentation
- `QUICKSTART.md` - 5-minute deployment guide
- `LIGHTSHIFT_SETUP.md` - Internal domain setup guide (lightshift.local pattern)
- `CLOUD_RUN_DEPLOYMENT.md` - Comprehensive 60+ page deployment guide
- `CUSTOM_AGENTS.md` - Custom agents and workflows integration guide
- `DEPLOYMENT_SUMMARY.md` - Overview and quick reference
- Updated main `README.md` with Cloud Run deployment section

#### Configuration
- `.env.deploy.template` - Environment configuration template with lightshift.local defaults
- Support for internal domain pattern (chatkit.lightshift.local, chatkit-api.lightshift.local)
- Secret Manager integration for secure credential storage

#### Features
- **Production-Ready**: Auto-scaling, zero-downtime deployments, health checks
- **Internal Domain Support**: Follows lightshift.local pattern (e.g., mage.lightshift.local)
- **Custom Agents**: Integration with OpenAI Agent Builder workflows
- **DevOps Best Practices**: CI/CD, Infrastructure as Code, automated testing
- **Cost Optimization**: Scales to zero, pay-per-use pricing
- **Monitoring**: Cloud Logging and Cloud Monitoring integration

### Changed
- Updated `.gitignore` to exclude `.env.deploy` and deployment configuration files

### Architecture
```
User (Internal Network)
    ↓
chatkit.lightshift.local (Frontend - Cloud Run)
    ↓
chatkit-api.lightshift.local (Backend - Cloud Run)
    ↓
OpenAI Platform (GPT Models + Agent Builder)
```

### Domain Configuration
- Frontend: `chatkit.lightshift.local`
- Backend API: `chatkit-api.lightshift.local`
- Follows same pattern as other internal services (e.g., `mage.lightshift.local`)

### Security
- Secrets stored in Google Secret Manager
- HTTPS by default via Cloud Run
- Security headers configured in Nginx
- Multi-stage Docker builds for minimal attack surface
- No hardcoded credentials in code

### Compatibility
- OpenAI ChatKit SDK
- Google Cloud Run
- Docker
- Python 3.11+
- Node.js 20+

---

## Notes

This release adds complete Google Cloud Run deployment capabilities to the OpenAI ChatKit Advanced Samples, following the AgentKit best practices from the OpenAI cookbook. The implementation is designed to work seamlessly with internal infrastructure using the lightshift.local domain pattern.
