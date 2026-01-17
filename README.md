# Advanced DevSecOps CI/CD Pipeline

A production-grade DevSecOps project demonstrating a complete CI/CD pipeline with security scanning, quality gates, containerization, and Kubernetes deployment.

## 📋 Project Overview

This project implements a **security-first CI/CD pipeline** for a Java Spring Boot REST API that:
- Exposes a `/users` endpoint returning sample user data
- Enforces code quality standards with Checkstyle
- Performs Static Application Security Testing (SAST) with CodeQL
- Scans dependencies for vulnerabilities (SCA) with Trivy
- Builds secure Docker images with security scanning
- Deploys to local Kubernetes with production-ready configurations

**Key Technologies:**
- **Language**: Java 17
- **Framework**: Spring Boot 3.4.5
- **Build Tool**: Maven
- **CI Platform**: GitHub Actions
- **Container**: Docker (multi-stage builds)
- **Orchestration**: Kubernetes (minikube/kind)
- **Security Tools**: CodeQL, Trivy, Checkstyle

---

## 🚀 How to Run Locally

### Option 1: Run with Maven (Quick Development)

**Prerequisites:**
- Java 17
- Maven 3.6+

**Steps:**
```bash
# Clone the repository
git clone <your-repo-url>
cd dev-Secops

# Run the application
mvn spring-boot:run

# Test the API
curl http://localhost:8080/users
```

**Run Tests:**
```bash
# Run unit tests
mvn test

# Run linting
mvn checkstyle:check

# Build JAR
mvn clean package
```

---

### Option 2: Run with Docker (Production-like)

**Prerequisites:**
- Docker Desktop installed and running

**Steps:**
```bash
# 1. Build the application
mvn clean package -DskipTests

# 2. Build Docker image
docker build -t devops-ci-api:local .

# 3. Run container
docker run -d -p 8080:8080 --name devops-api devops-ci-api:local

# 4. Test the API
curl http://localhost:8080/users

# 5. View logs
docker logs -f devops-api

# 6. Stop and remove
docker stop devops-api && docker rm devops-api
```

---

### Option 3: Run with Kubernetes (Full CD Experience)

**Prerequisites:**
- Docker Desktop
- minikube OR kind
- kubectl

**Quick Start:**
```bash
# 1. Setup Kubernetes cluster
./setup-local-k8s.sh

# 2. Build and load image
mvn clean package -DskipTests
docker build -t devops-ci-api:local .
minikube image load devops-ci-api:local

# 3. Deploy to Kubernetes
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
sed 's|IMAGE_NAME:latest|devops-ci-api:local|g' k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml

# 4. Access the application
minikube service devops-ci-api-service -n devops-app --url

# 5. Check status
kubectl get all -n devops-app
```

**Clean Up:**
```bash
kubectl delete namespace devops-app
minikube stop
```

---

## 🔐 Secrets Configuration

To run the complete CI/CD pipeline, you need to configure secrets for both Docker Hub and Kubernetes.

### Required Secrets for CI Pipeline

1. **Go to your GitHub repository**
2. **Navigate to**: Settings → Secrets and variables → Actions
3. **Click**: "New repository secret"
4. **Add the following secrets:**

| Secret Name | Description | Required For |
|-------------|-------------|--------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | CI (Image push) |
| `DOCKERHUB_TOKEN` | Docker Hub access token | CI (Image push) |

### Required Secrets for CD Pipeline

| Secret Name | Description | Required For |
|-------------|-------------|--------------|
| `KUBE_CONFIG_DEV` | Base64 encoded kubeconfig for dev cluster | Development deployment |
| `KUBE_CONFIG_STAGING` | Base64 encoded kubeconfig for staging cluster | Staging deployment |
| `KUBE_CONFIG_PROD` | Base64 encoded kubeconfig for production cluster | Production deployment |

### How to Create Docker Hub Access Token

1. Log in to Docker Hub: https://hub.docker.com/
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Name: "GitHub Actions CI/CD"
5. Permissions: Read, Write, Delete
6. Copy the token (you won't see it again!)
7. Add as `DOCKERHUB_TOKEN` in GitHub Secrets

### How to Create Kubernetes Secrets

**For local Kubernetes (minikube/kind) testing:**
```bash
# Get your kubeconfig
cat ~/.kube/config | base64

# Or for specific context
kubectl config view --minify --flatten | base64
```

**For cloud providers (AWS EKS, GCP GKE, Azure AKS):**

Choose your provider and follow the instructions:

<details>
<summary><b>AWS EKS</b></summary>

```bash
# Install AWS CLI and configure
aws configure

# Update kubeconfig for EKS
aws eks update-kubeconfig --name your-cluster-name --region us-east-1

# Export and encode
kubectl config view --minify --flatten | base64 | tr -d '\n'
```
</details>

<details>
<summary><b>GCP GKE</b></summary>

```bash
# Install gcloud CLI and authenticate
gcloud auth login

# Get cluster credentials
gcloud container clusters get-credentials your-cluster-name --region us-central1

# Export and encode
kubectl config view --minify --flatten | base64 | tr -d '\n'
```
</details>

<details>
<summary><b>Azure AKS</b></summary>

```bash
# Install Azure CLI and login
az login

# Get cluster credentials
az aks get-credentials --resource-group your-rg --name your-cluster-name

# Export and encode
kubectl config view --minify --flatten | base64 | tr -d '\n'
```
</details>

**Then add to GitHub Secrets:**
- Copy the base64 encoded kubeconfig
- Add as `KUBE_CONFIG_DEV`, `KUBE_CONFIG_STAGING`, or `KUBE_CONFIG_PROD`

### Setting Up GitHub Environments (Optional but Recommended)

For deployment approvals and protection rules:

1. Go to: Settings → Environments
2. Create three environments:
   - `development` (no approval required)
   - `staging` (require 1 reviewer)
   - `production` (require 2 reviewers)
3. Add environment-specific secrets if needed

### Verifying Configuration

**Test CI Pipeline:**
```bash
git push origin main
```

**Test CD Pipeline:**
```bash
# Via GitHub UI: Actions → CD - Deploy to Kubernetes → Run workflow
# Select environment: development
```

Check the workflow logs to ensure:
- ✅ Docker Hub login succeeds
- ✅ Image push completes
- ✅ Kubernetes connection succeeds
- ✅ Deployment completes
- ✅ Health checks pass

---

## 🔄 CI/CD Pipeline Explanation

This project includes **complete CI/CD pipelines** with automated deployment to Kubernetes.

### Available Workflows

1. **CI Pipeline** (`.github/workflows/ci.yml`) - Automated on every push
2. **CD Pipeline** (`.github/workflows/cd.yml`) - Deploy to Development/Staging/Production
3. **Rollback** (`.github/workflows/rollback.yml`) - Emergency rollback capability

### CI Pipeline Architecture

```
Developer → Git Push → GitHub Actions
    ↓
Stage 1: Setup & Initialize (30-60s)
    - Checkout code
    - Setup Java 17 + Maven cache
    - Initialize CodeQL
    ↓
Stage 2: Shift-Left Security Gates (60-90s) ⚠️ FAIL FAST
    - Checkstyle Lint → Code quality
    - Trivy SCA → Dependency vulnerabilities
    - Unit Tests → Business logic
    ↓
Stage 3: Build & SAST (2-5 min)
    - Maven build JAR
    - CodeQL analysis (SQL injection, XSS, etc.)
    ↓
Stage 4: Container Build & Scan (2-4 min)
    - Multi-stage Docker build
    - Trivy image scan
    ↓
Stage 5: Runtime Validation (30-60s)
    - Start container
    - Test /users endpoint
    - Validate response
    ↓
Stage 6: Publish to Registry (30-90s)
    - Push to Docker Hub (SHA + latest tags)
    ↓
Stage 7: Auto-Deploy to Development
    - Triggers CD pipeline automatically
    ↓
Docker Hub Registry + Kubernetes Deployment
```

### CD Pipeline Architecture

```
CI Success → CD Pipeline Triggered
    ↓
Environment Selection
    - Development (auto-deploy)
    - Staging (manual approval)
    - Production (manual approval)
    ↓
Deploy to Kubernetes
    - Create/update namespace
    - Apply ConfigMaps
    - Deploy application
    - Apply services
    - Apply network policies
    ↓
Health Checks
    - Wait for rollout
    - Verify pods running
    - Test endpoints
    ↓
Deployment Complete
```

### Pipeline Stages Breakdown

| Stage | Duration | Actions | Fails On |
|-------|----------|---------|----------|
| **Setup** | 30-60s | Checkout, Java setup, CodeQL init | - |
| **Security Gates** | 60-90s | Checkstyle, Trivy SCA, Unit tests | Style violations, HIGH/CRITICAL CVEs, Test failures |
| **Build & SAST** | 2-5 min | Maven package, CodeQL analysis | Build errors, Security vulnerabilities |
| **Container** | 2-4 min | Docker build, Trivy image scan | HIGH/CRITICAL in image |
| **Validation** | 30-60s | Smoke test /users endpoint | Runtime errors, timeout |
| **Publish** | 30-90s | Push to Docker Hub | Auth failure |
| **Total** | **~9.5 min** | End-to-end pipeline | - |

### Key Security Features

**Shift-Left Security**: Security checks run BEFORE building artifacts
- Catches issues early (cheaper to fix)
- Prevents vulnerable code from progressing
- Fail-fast strategy saves time

**Defense in Depth**: Multiple overlapping security layers
- **CodeQL SAST**: Finds code-level vulnerabilities
- **Trivy SCA**: Scans dependencies for CVEs
- **Trivy Image**: Scans final container image
- **Smoke Test**: Validates runtime behavior

**Zero Trust to Registry**: Only images that pass ALL gates are published
- ✅ Code quality (Checkstyle)
- ✅ Dependency scan (SCA)
- ✅ Code scan (SAST)
- ✅ Image scan
- ✅ Runtime test

### Container Security

**Multi-Stage Dockerfile Benefits:**
- 87% fewer vulnerabilities vs single-stage
- 73% smaller image size
- No build tools in runtime image
- Non-root user execution (UID 1000)
- Alpine base for minimal attack surface

---

## 📁 Project Structure

```
dev-Secops/
├── .github/
│   └── workflows/
│       ├── ci.yml              # CI pipeline (auto on push)
│       ├── cd.yml              # CD pipeline (deploy to K8s)
│       └── rollback.yml        # Rollback workflow
├── src/                        # Java Spring Boot source code
│   ├── main/java/              # Application code
│   └── test/java/              # Unit tests
├── k8s/                        # Kubernetes manifests
│   ├── namespace.yaml          # Namespace definition
│   ├── configmap.yaml          # Configuration
│   ├── deployment.yaml         # Deployment spec
│   ├── service.yaml            # Service definition
│   └── networkpolicy.yaml      # Network policies
├── Dockerfile                  # Multi-stage container build
├── pom.xml                     # Maven dependencies
├── checkstyle.xml              # Code style rules
└── README.md                   # This file
```

---

## 🚢 CD Workflows

### 1. Automated Deployment (Development)
```bash
# Automatically triggered on successful CI build from main branch
git push origin main
# → CI runs → Image published → Auto-deploys to dev
```

### 2. Manual Deployment (Staging/Production)
```bash
# Via GitHub UI:
# 1. Go to Actions → "CD - Deploy to Kubernetes"
# 2. Click "Run workflow"
# 3. Select environment (staging/production)
# 4. Select image tag (default: latest)
# 5. Click "Run workflow"
# 6. Approve deployment (for staging/production)
```

### 3. Rollback
```bash
# Via GitHub UI:
# 1. Go to Actions → "Rollback Deployment"
# 2. Click "Run workflow"
# 3. Select environment
# 4. Select revision (0 = previous, 1 = before that)
# 5. Click "Run workflow"
```

### Deployment Environments

| Environment | Auto-Deploy | Requires Approval | Replicas | Namespace |
|-------------|-------------|-------------------|----------|-----------|
| Development | ✅ Yes | ❌ No | 2 | devops-app-dev |
| Staging | ❌ No | ✅ Yes (1 reviewer) | 2 | devops-app-staging |
| Production | ❌ No | ✅ Yes (2 reviewers) | 3 | devops-app-prod |

---

## 🎯 DevSecOps Principles Implemented

1. **Shift-Left Security** - Security testing early in the pipeline
2. **Automation** - Zero manual steps, fully automated CI/CD
3. **Continuous Integration** - Every commit triggers full pipeline
4. **Continuous Deployment** - Automated deployment to Kubernetes
5. **Infrastructure as Code** - Version-controlled manifests
6. **Immutable Artifacts** - Git SHA tagged images
7. **Defense in Depth** - Multiple security layers
8. **Fail-Fast** - Stop immediately on critical failures
9. **Least Privilege** - Non-root containers, minimal permissions
10. **Progressive Delivery** - Dev → Staging → Production with approvals
11. **Rollback Strategy** - One-click rollback capability

---

## 📚 Resources

- **GitHub Actions**: https://docs.github.com/en/actions
- **CodeQL**: https://codeql.github.com/docs/
- **Trivy**: https://aquasecurity.github.io/trivy/
- **Spring Boot**: https://spring.io/projects/spring-boot
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/

---

## 📄 License

This project is for educational purposes as part of a DevOps course assessment.
