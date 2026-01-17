# Advanced DevSecOps CI/CD Pipeline

A production-grade DevSecOps project demonstrating a complete CI/CD pipeline with security scanning, quality gates, containerization, and Kubernetes deployment for a Java Spring Boot REST API.

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

**Run Tests & Quality Checks:**
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
| `GCP_SA_KEY` | Google Cloud service account key (JSON) | GKE cluster authentication |

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

**For Google Cloud GKE:**
```bash
# Install gcloud CLI and authenticate
gcloud auth login

# Get cluster credentials
gcloud container clusters get-credentials your-cluster-name --region us-central1

# Export and encode
kubectl config view --minify --flatten | base64 | tr -d '\n'
```

**Then add to GitHub Secrets:**
- Copy the base64 encoded kubeconfig
- Add as `KUBE_CONFIG_DEV`, `KUBE_CONFIG_STAGING`, or `KUBE_CONFIG_PROD`

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

## 🔄 CI Pipeline Explanation

### CI Pipeline Architecture

The CI pipeline is triggered automatically on every push to `main` or `develop` branches and runs through 7 stages:

```
Developer Push → GitHub Actions
    ↓
Stage 1: Setup & Code Quality (30-60s)
    - Checkout code
    - Setup Java 17 + Maven cache
    - Run Checkstyle linting
    - Run unit tests
    ↓
Stage 2: Security Scanning - SCA (60-90s)
    - Trivy dependency scan
    - Check for HIGH/CRITICAL vulnerabilities
    - Upload results to GitHub Security
    ↓
Stage 3: SAST - CodeQL Analysis (2-5 min)
    - Initialize CodeQL
    - Build application
    - Analyze for security vulnerabilities
    ↓
Stage 4: Build & Package (1-2 min)
    - Maven build JAR
    - Upload artifact
    ↓
Stage 5: Docker Build & Scan (2-4 min)
    - Multi-stage Docker build
    - Trivy image vulnerability scan
    - Save Docker image as artifact
    ↓
Stage 6: Runtime Validation (30-60s)
    - Start container
    - Test /users endpoint
    - Validate response
    ↓
Stage 7: Publish to Registry (30-90s)
    - Push to Docker Hub (SHA + latest tags)
    - Create deployment metadata
    ↓
✅ CI Complete → Triggers CD Pipeline
```

### Pipeline Stages Breakdown

| Stage | Duration | Actions | Fails On |
|-------|----------|---------|----------|
| **Setup & Quality** | 30-60s | Checkstyle, Unit tests | Style violations, Test failures |
| **Security SCA** | 60-90s | Trivy dependency scan | HIGH/CRITICAL CVEs |
| **SAST** | 2-5 min | CodeQL analysis | Security vulnerabilities |
| **Build** | 1-2 min | Maven package | Build errors |
| **Container Scan** | 2-4 min | Docker build, Trivy scan | HIGH/CRITICAL in image |
| **Validation** | 30-60s | Smoke test endpoint | Runtime errors, timeout |
| **Publish** | 30-90s | Push to Docker Hub | Auth failure |
| **Total** | **~9.5 min** | End-to-end pipeline | - |

### Key Security Features

**Shift-Left Security**: Security checks run EARLY in the pipeline
- Catches issues before building artifacts (cheaper to fix)
- Prevents vulnerable code from progressing
- Fail-fast strategy saves time

**Defense in Depth**: Multiple overlapping security layers
- **Checkstyle**: Code quality and style enforcement
- **CodeQL SAST**: Finds code-level vulnerabilities (SQL injection, XSS, etc.)
- **Trivy SCA**: Scans dependencies for known CVEs
- **Trivy Image**: Scans final container image
- **Smoke Test**: Validates runtime behavior

**Zero Trust to Registry**: Only images that pass ALL gates are published
- ✅ Code quality (Checkstyle)
- ✅ Unit tests pass
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
- Automated security patching with `apk upgrade`

---

## 🚢 CD Pipeline Explanation

### CD Pipeline Architecture

The CD pipeline deploys the application to Kubernetes across three environments with progressive delivery:

```
CI Success → CD Pipeline Triggered
    ↓
Stage 1: Prepare Deployment
    - Determine environment (dev/staging/prod)
    - Set image tag (latest or specific SHA)
    - Set namespace based on environment
    ↓
Stage 2: Environment Selection & Approval
    - Development: Auto-deploy (no approval)
    - Staging: Manual trigger + approval required
    - Production: Manual trigger + approval required
    ↓
Stage 3: Kubernetes Configuration
    - Install kubectl
    - Setup Google Cloud SDK + GKE auth plugin
    - Authenticate to GCP
    - Configure kubeconfig from secrets
    - Verify cluster connection
    ↓
Stage 4: Deploy to Kubernetes
    - Create/update namespace
    - Apply ConfigMaps (environment variables)
    - Deploy application (update image)
    - Apply services (LoadBalancer/NodePort)
    - Apply network policies (if exists)
    ↓
Stage 5: Health Checks & Validation
    - Wait for rollout completion (5-10 min timeout)
    - Verify pods are running
    - Run health checks on /users endpoint
    - Get service URL
    ↓
Stage 6: Deployment Summary
    - Display deployment status
    - Show environment, namespace, image
    - Provide service URL
    ↓
✅ CD Complete → Application Live
```

### Deployment Environments

| Environment | Auto-Deploy | Requires Approval | Replicas | Namespace |
|-------------|-------------|-------------------|----------|-----------|
| Development | ✅ Yes (on main push) | ❌ No | 2 | devops-app-dev |
| Staging | ❌ Manual | ✅ Yes (1 reviewer) | 2 | devops-app-staging |
| Production | ❌ Manual | ✅ Yes (2 reviewers) | 3 | devops-app-prod |

### CD Workflows

**1. Automated Deployment (Development)**
```bash
# Automatically triggered on successful CI build from main branch
git push origin main
# → CI runs → Image published → Auto-deploys to dev
```

**2. Manual Deployment (Staging/Production)**
```bash
# Via GitHub UI:
# 1. Go to Actions → "CD - Deploy to Kubernetes"
# 2. Click "Run workflow"
# 3. Select environment (staging/production)
# 4. Select image tag (default: latest)
# 5. Click "Run workflow"
# 6. Approve deployment (for staging/production)
```

**3. Rollback**
```bash
# Via GitHub UI:
# 1. Go to Actions → "Rollback Deployment"
# 2. Click "Run workflow"
# 3. Select environment
# 4. Select revision (0 = previous, 1 = before that)
# 5. Click "Run workflow"
```

### Key CD Features

**Progressive Delivery**
- Development → Staging → Production flow
- Approval gates for production environments
- Different replica counts per environment

**Infrastructure as Code**
- All Kubernetes manifests version-controlled
- Declarative configuration with kubectl apply
- Idempotent deployments

**Health Checks & Validation**
- Automatic rollout status monitoring
- Pod health verification
- Endpoint testing before completion
- Timeout protection (5-10 min)

**Production Safeguards**
- Pre-deployment verification (image exists)
- Final security scan before deployment
- Backup of current deployment
- Comprehensive health checks (5 iterations)
- Extended rollout timeout (10 min)

**Cloud-Native Deployment**
- Google Cloud GKE integration
- Service account authentication
- Cross-platform gke-gcloud-auth-plugin support
- LoadBalancer service type for external access

---

## 📚 Resources

- **GitHub Actions**: https://docs.github.com/en/actions
- **CodeQL**: https://codeql.github.com/docs/
- **Trivy**: https://aquasecurity.github.io/trivy/
- **Spring Boot**: https://spring.io/projects/spring-boot
- **Kubernetes**: https://kubernetes.io/docs/home/
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/

---

## 📄 License

This project is for educational purposes as part of a DevOps course assessment.
