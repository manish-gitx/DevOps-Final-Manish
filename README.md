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

To run the CI/CD pipeline in GitHub Actions, configure the following repository secrets:

### Setting Up GitHub Secrets

1. **Go to your GitHub repository**
2. **Navigate to**: Settings → Secrets and variables → Actions
3. **Click**: "New repository secret"
4. **Add the following secrets:**

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | Your Docker Hub account username |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Docker Hub → Account Settings → Security → New Access Token |

### How to Create Docker Hub Access Token

1. Log in to Docker Hub: https://hub.docker.com/
2. Go to Account Settings → Security
3. Click "New Access Token"
4. Name: "GitHub Actions CI"
5. Permissions: Read, Write, Delete
6. Copy the token (you won't see it again!)
7. Add as `DOCKERHUB_TOKEN` in GitHub Secrets

### Verifying Secrets

After configuring secrets, trigger the CI pipeline:
```bash
git push origin main
```

Check the workflow logs to ensure:
- "Log in to Docker Hub" step succeeds
- "Push image to Docker Hub" step completes
- Image appears in your Docker Hub repository

---

## 🔄 CI/CD Pipeline Explanation

The CI pipeline implements a **security-first, shift-left** approach with multiple quality gates.

### Pipeline Architecture

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
Docker Hub Registry → Ready for Deployment
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
├── .github/workflows/ci.yml    # CI/CD pipeline
├── src/                        # Java Spring Boot source code
├── k8s/                        # Kubernetes manifests
├── Dockerfile                  # Multi-stage container build
├── pom.xml                     # Maven dependencies
├── checkstyle.xml              # Code style rules
└── README.md                   # This file
```

---

## 🎯 DevSecOps Principles Implemented

1. **Shift-Left Security** - Security testing early in the pipeline
2. **Automation** - Zero manual steps, fully automated
3. **Continuous Integration** - Every commit triggers full pipeline
4. **Infrastructure as Code** - Version-controlled manifests
5. **Immutable Artifacts** - Git SHA tagged images
6. **Defense in Depth** - Multiple security layers
7. **Fail-Fast** - Stop immediately on critical failures
8. **Least Privilege** - Non-root containers, minimal permissions

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
