# Azure DevOps Pipeline Quick Start Guide

This guide will walk you through setting up the complete CI/CD pipeline in Azure DevOps in under 10 minutes.

## Current Status

✅ Code pushed to Azure DevOps (main + develop branches)
✅ TestProject deployed to all three local environments
✅ All environments verified and healthy
⏳ Pipeline needs to be created in Azure DevOps UI

## Prerequisites

- Azure DevOps account with access to: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3
- Repository already contains `azure-pipelines.yml`

## Step 1: Create the Pipeline (2 minutes)

1. **Navigate to Pipelines**
   - Go to: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3/_build
   - Click "New Pipeline" (or "Create Pipeline" if this is your first)

2. **Select Repository Source**
   - Choose "Azure Repos Git"
   - Select repository: `poc_ignition_8.3`

3. **Configure Pipeline**
   - Choose "Existing Azure Pipelines YAML file"
   - Branch: `main`
   - Path: `/azure-pipelines.yml`
   - Click "Continue"

4. **Review and Create**
   - Click "Run" to create and run the pipeline for the first time
   - The pipeline will fail (expected!) because environments don't exist yet

## Step 2: Create Environments (3 minutes)

1. **Navigate to Environments**
   - Go to: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3/_environments
   - Click "Create environment"

2. **Create Development Environment**
   - Name: `Development`
   - Description: `Development environment (auto-deploy from develop branch)`
   - Resource: None (just click "Create")

3. **Create Staging Environment**
   - Name: `Staging`
   - Description: `Staging environment (auto-deploy from release branches)`
   - Resource: None
   - Click "Create"

4. **Create Production Environment**
   - Name: `Production`
   - Description: `Production environment (manual approval required)`
   - Resource: None
   - Click "Create"

5. **Add Production Approval**
   - Click on "Production" environment
   - Click "..." (three dots) → "Approvals and checks"
   - Click "+" → "Approvals"
   - Add yourself as approver
   - Instructions: "Review changes before deploying to production"
   - Click "Create"

## Step 3: Configure Pipeline Variables (2 minutes)

1. **Navigate to Pipeline Variables**
   - Go to your pipeline: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3/_build
   - Click on your pipeline (should be named "poc_ignition_8.3")
   - Click "Edit"
   - Click "Variables" (top right)

2. **Add Required Variables** (for local Docker setup)

   Click "+ Add" for each variable:

   | Variable Name | Value | Secret? |
   |--------------|-------|---------|
   | `DEV_GATEWAY_URL` | `http://localhost:8088` | No |
   | `DEV_GATEWAY_USER` | `admin` | No |
   | `DEV_GATEWAY_PASS` | `dev-password` | Yes |
   | `DEV_CONTAINER_NAME` | `ignition-dev` | No |
   | `STAGING_GATEWAY_URL` | `http://localhost:8188` | No |
   | `STAGING_GATEWAY_USER` | `admin` | No |
   | `STAGING_GATEWAY_PASS` | `staging-password` | Yes |
   | `STAGING_CONTAINER_NAME` | `ignition-staging` | No |
   | `PROD_GATEWAY_URL` | `http://localhost:8288` | No |
   | `PROD_GATEWAY_USER` | `admin` | No |
   | `PROD_GATEWAY_PASS` | `prod-password` | Yes |
   | `PROD_CONTAINER_NAME` | `ignition-prod` | No |
   | `DB_CONNECTION_STRING` | `postgresql://ignition:ignition-db-password@localhost:5432/ignition` | Yes |

   **Important**: Mark passwords and connection strings as "Secret" by clicking the lock icon!

3. **Save Variables**
   - Click "Save" in the variables dialog
   - Click "Save" again in the pipeline editor

## Step 4: Configure Branch Policies (2 minutes)

1. **Navigate to Branch Policies**
   - Go to: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3/_settings/repositories
   - Click on your repository: `poc_ignition_8.3`
   - Click "Policies" tab

2. **Protect Main Branch**
   - Find `main` branch
   - Enable "Require a minimum number of reviewers": 1
   - Enable "Check for linked work items": Optional
   - Enable "Build Validation"
     - Click "+"
     - Select your pipeline
     - Build expiration: 12 hours
     - Click "Save"

3. **Protect Develop Branch**
   - Find or create policy for `develop` branch
   - Same settings as main (but you can make reviewers optional for develop)

## Step 5: Test the Pipeline (1 minute)

### Test Auto-Deploy to Development

1. Make a small change on the develop branch:
   ```bash
   git checkout develop
   echo "# Test deployment" >> README.md
   git add README.md
   git commit -m "Test auto-deployment to Development"
   git push origin develop
   ```

2. Watch the pipeline run:
   - Go to: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3/_build
   - You should see a new build triggered by the push to develop
   - It should automatically deploy to Development environment

### Test Release Flow to Staging

1. Create a release branch:
   ```bash
   git checkout develop
   git checkout -b release/v1.0.0
   git push -u origin release/v1.0.0
   ```

2. Watch the pipeline:
   - Should automatically deploy to Staging environment

### Test Production Deploy with Approval

1. Merge to main (in a real scenario, you'd merge release → main):
   ```bash
   git checkout main
   git merge release/v1.0.0 --no-ff -m "Release v1.0.0"
   git tag -a v1.0.0 -m "Release version 1.0.0"
   git push origin main --tags
   ```

2. Watch the pipeline:
   - Should pause at Production deployment
   - You'll receive an approval notification
   - Click "Review" → "Approve" to deploy to production

## Step 6: Verify Everything Works

1. **Check Pipeline Dashboard**
   - Go to: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3/_build
   - All stages should be green ✅

2. **Check Deployed Projects**
   - Dev: http://localhost:8088/web/home
   - Staging: http://localhost:8188/web/home
   - Production: http://localhost:8288/web/home

3. **Verify TestProject is loaded** in each gateway:
   - Login with credentials (admin / [env]-password)
   - Navigate to Designer
   - You should see "TestProject" in the project list

## GitFlow Automation Summary

Once setup is complete, the pipeline will automatically:

| Branch Pattern | Trigger | Deploys To | Approval Required |
|---------------|---------|------------|-------------------|
| `develop` | Push | Development | No (auto) |
| `release/*` | Push | Staging | No (auto) |
| `main` + tag | Push | Production | Yes (manual) |
| `feature/*` | PR to develop | Validation only | N/A |
| `hotfix/*` | PR to main | Validation only | N/A |

## Troubleshooting

### Pipeline fails with "Environment not found"
- Make sure you created all three environments (Development, Staging, Production)
- Environment names are case-sensitive

### Deployment fails with connection error
- Verify Docker containers are running: `docker-compose ps`
- Check gateway URLs are correct in pipeline variables
- For remote deployments, ensure network connectivity

### Project doesn't appear in Ignition
- Check gateway logs: `docker logs ignition-dev -f`
- Verify project was copied: `docker exec ignition-dev ls -la /usr/local/bin/ignition/data/projects/`
- Try manual gateway restart: `docker restart ignition-dev`

### Approval notifications not received
- Check your Azure DevOps notification settings
- Go to: https://dev.azure.com/Wilms-ICT/_usersSettings/notifications
- Enable "A deployment requires your approval"

## Next Steps

- [ ] Set up self-hosted agent for Docker access (if deploying to local Docker)
- [ ] Configure remote gateway URLs for actual deployment servers
- [ ] Add more projects to the repository
- [ ] Customize validation rules in `scripts/validate-names.sh`
- [ ] Add database migration scripts in `migrations/`
- [ ] Set up monitoring and alerting

## Support

For issues or questions:
- Check the main documentation: `AZURE_DEVOPS_SETUP.md`
- Review pipeline logs in Azure DevOps
- Check local deployment with: `./scripts/test-full-pipeline.sh`

---

**Last Updated**: 2025-11-17
**Status**: Ready for pipeline creation
**Repository**: https://dev.azure.com/Wilms-ICT/poc_ignition_8.3
