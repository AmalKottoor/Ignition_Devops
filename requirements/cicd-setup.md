
---

## 🧭 1. Repository Structure (Monorepo for All Projects)

Here’s a practical layout for an Ignition multi-project repo:

```
/.github/workflows/
│   ├── ci.yml             ← CI for validation + build
│   ├── deploy.yml         ← CD for staging/production
│   └── promote.yml        ← Optional promotion flow
/projects/
│   ├── project-a/
│   ├── project-b/
│   ├── project-c/
│   └── shared-libs/       ← optional shared code/scripts
/config/
│   ├── environments/
│   │   ├── test.yaml
│   │   ├── staging.yaml
│   │   └── production.yaml
│   ├── deploy.sh
│   └── fetch-artifacts.sh
/scripts/
│   ├── package-project.sh
│   ├── lint-projects.sh
│   ├── smoke-test.sh
│   └── validate-names.sh
```

---

## 🧱 2. GitFlow Branching Model

GitFlow pattern:

```
feature/* → develop → release/* → main
```

| Branch      | Purpose                   | Environment | Deployment Trigger   |
| ----------- | ------------------------- | ----------- | -------------------- |
| `develop`   | Integration / internal QA | Test        | Auto-deploy          |
| `release/*` | Stabilization, UAT        | Staging     | Auto-deploy          |
| `main`      | Stable production code    | Production  | Tag-triggered deploy |
| `hotfix/*`  | Critical production fix   | Production  | Tag-triggered deploy |

---

## ⚙️ 3. GitHub Actions CI Workflow (`.github/workflows/ci.yml`)

Runs for all pushes to `develop`, `release/*`, and PRs.
Validates, packages, and produces build artifacts.

```yaml
name: CI Build for Ignition Projects

on:
  push:
    branches:
      - develop
      - 'release/*'
      - main
  pull_request:

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Lint naming and folder structure
        run: ./scripts/validate-names.sh

      - name: Package all projects
        run: |
          for dir in projects/*/; do
            ./scripts/package-project.sh "$dir"
          done

      - name: Upload build artifacts
        uses: actions/upload-artifact@v3
        with:
          name: ignition-projects
          path: build/
```

✅ **Purpose:** ensures everything builds and follows Ignition folder conventions
✅ **CI runs automatically** for every PR or branch change
✅ **Artifacts uploaded** for later deploy jobs

---

## 🚀 4. Deployment Workflow (`.github/workflows/deploy.yml`)

Automatically deploys based on GitFlow branch → environment mapping.

```yaml
name: Deploy Ignition Environment

on:
  push:
    branches:
      - develop
      - 'release/*'
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Determine environment
        id: env
        run: |
          if [[ $GITHUB_REF == refs/heads/develop ]]; then
            echo "environment=test" >> $GITHUB_OUTPUT
          elif [[ $GITHUB_REF == refs/heads/release/* ]]; then
            echo "environment=staging" >> $GITHUB_OUTPUT
          elif [[ $GITHUB_REF == refs/tags/v* ]]; then
            echo "environment=production" >> $GITHUB_OUTPUT
          fi

      - name: Load environment configuration
        run: |
          ENV=${{ steps.env.outputs.environment }}
          echo "Deploying to $ENV"
          cat config/environments/${ENV}.yaml

      - name: Deploy to Ignition Gateway
        run: ./config/deploy.sh ${{ steps.env.outputs.environment }}
```

✅ **Auto-deploys** to:

* **Test** when pushing to `develop`
* **Staging** when pushing to `release/*`
* **Production** when tagging (e.g., `v1.3.0`)

✅ **Environment configs** in `/config/environments/` hold gateway URLs and credentials
✅ Secrets like passwords go into **GitHub Environments**

---

## 🧠 5. Promotion Workflow (`.github/workflows/promote.yml`)

Optional, but helps with traceability.
Allows you to “promote” from one environment to the next **without merging branches** — keeping GitFlow clean.

```yaml
name: Promote Release

on:
  workflow_dispatch:
    inputs:
      from:
        description: "Source branch/environment"
        required: true
        default: "release/1.2.0"
      to:
        description: "New release tag"
        required: true
        default: "v1.2.0"

jobs:
  promote:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - run: |
          git tag ${{ github.event.inputs.to }} ${{ github.event.inputs.from }}
          git push origin ${{ github.event.inputs.to }}

      - name: Merge to main after successful deploy
        if: success()
        run: |
          git checkout main
          git merge ${{ github.event.inputs.from }}
          git push origin main
```

✅ **No merges needed** — just promote the same commit from `release/*` to a production tag.
✅ This keeps **main stable**, **GitFlow intact**, and **CI/CD automatic**.

---

## 🧩 6. Environment Config Example

`config/environments/staging.yaml`:

```yaml
gateway:
  url: https://staging-gateway.mustry.io
  username: ${{ secrets.STAGING_USER }}
  password: ${{ secrets.STAGING_PASS }}
projects:
  project-a: build/project-a-1.2.0.zip
  project-b: build/project-b-1.2.0.zip
```

The `deploy.sh` script can parse this and use the Ignition Gateway REST API to import projects, or SSH into the server to replace `/data/projects`.

---

## 🧱 7. Ignition-Specific Deployment Notes

* Always **exclude** `/data/var`, `/data/config/local`, and similar runtime folders.
* Store deployable packages as `.zip` or `.gwbk` artifacts per project.
* Use Ignition’s REST API (`/system/gateway/projects/import`) for safe remote deployment.
* Maintain backups before replacing projects (`/system/gateway/projects/export?name=projectName`).
* Use GitHub Environments for credentials:

  * `TEST_GATEWAY_URL`, `STAGING_GATEWAY_URL`, `PROD_GATEWAY_URL`
  * `IGNITION_USERNAME`, `IGNITION_PASSWORD`

---

## ✅ 8. Summary: GitFlow + CI/CD

| Git Branch          | Environment | Trigger  | Deploys To         |
| ------------------- | ----------- | -------- | ------------------ |
| `develop`           | Test        | Push     | Test gateway       |
| `release/*`         | Staging     | Push     | Staging gateway    |
| `main` + Tag (`v*`) | Production  | Tag push | Production gateway |

**Advantages:**

* True **GitFlow compliance**
* **One repo** = simple coordination across all projects
* CI/CD fully automated based on branch/tag
* No manual merges between environments
* Traceability via tags, logs, and environment configs

---
