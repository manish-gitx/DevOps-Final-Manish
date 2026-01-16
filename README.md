# Advanced DevSecOps CI/CD Pipeline

A production-grade DevSecOps project demonstrating a complete CI/CD pipeline with security scanning, quality gates, containerization, and Kubernetes deployment. Built with Java Spring Boot and GitHub Actions.

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
```

**Test the API:**
```bash
curl http://localhost:8080/users
```

**Expected Response:**
```json
[
  {
    "id": 1,
    "name": "Alice",
    "email": "alice@example.com"
  },
  {
    "id": 2,
    "name": "Bob",
    "email": "bob@example.com"
  },
  {
    "id": 3,
    "name": "Charlie",
    "email": "charlie@example.com"
  }
]
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
docker stop devops-api
docker rm devops-api
```

**Security Features in Dockerfile:**
- ✅ Multi-stage build (separates build and runtime)
- ✅ Alpine-based image (minimal attack surface)
- ✅ Non-root user execution (UID 1000)
- ✅ Security patches applied (`apk upgrade`)
- ✅ Health check configured

---

### Option 3: Run with Kubernetes (Full CD Experience)

**Prerequisites:**
- Docker Desktop
- **One of these**: minikube OR kind
- kubectl

**Install Prerequisites (macOS):**
```bash
# Install minikube (recommended)
brew install minikube

# Install kubectl
brew install kubectl

# Verify Docker is running
docker ps
```

**Deployment Steps:**

**Step 1: Setup Kubernetes Cluster**
```bash
./setup-local-k8s.sh
```

This will:
- Auto-detect minikube or kind
- Create a local Kubernetes cluster
- Enable necessary addons
- Verify cluster health

**Expected Output:**
```
=========================================
Local Kubernetes Cluster Setup
=========================================
✓ Detected: minikube
✓ kubectl is installed
Starting new minikube cluster...
✓ Minikube cluster started
✓ Local Kubernetes cluster is ready!
=========================================
```

**Step 2: Deploy Application to Kubernetes**

You have two options:

**Option A: Deploy from DockerHub (if image is pushed)**
```bash
# First push to DockerHub (requires secrets configured in GitHub)
# Then deploy
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml

# Update deployment with your DockerHub username
sed 's|IMAGE_NAME:latest|yourusername/devops-ci-api:latest|g' k8s/deployment.yaml | kubectl apply -f -

kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/networkpolicy.yaml
```

**Option B: Deploy local image (for testing)**
```bash
# Build image locally
docker build -t devops-ci-api:local .

# Load into minikube
minikube image load devops-ci-api:local

# Deploy (use local tag)
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/configmap.yaml
sed 's|IMAGE_NAME:latest|devops-ci-api:local|g' k8s/deployment.yaml | kubectl apply -f -
kubectl apply -f k8s/service.yaml
```

**Step 3: Access the Application**

**For Minikube:**
```bash
# Get URL
minikube service devops-ci-api-service -n devops-app --url

# Or open in browser
minikube service devops-ci-api-service -n devops-app
```

**For Kind:**
```bash
curl http://localhost:30080/users
```

**Check Deployment Status:**
```bash
# View all resources
kubectl get all -n devops-app

# View pods
kubectl get pods -n devops-app

# View logs
kubectl logs -l app=devops-ci-api -n devops-app

# Describe deployment
kubectl describe deployment devops-ci-api -n devops-app
```

**Scale the Application:**
```bash
# Scale to 3 replicas
kubectl scale deployment/devops-ci-api --replicas=3 -n devops-app

# Verify
kubectl get pods -n devops-app
```

**Clean Up:**
```bash
# Delete deployment
kubectl delete namespace devops-app

# Stop cluster (optional)
minikube stop

# Delete cluster (optional)
minikube delete
```

**For detailed Kubernetes documentation, see [k8s/README.md](k8s/README.md)**

---

## 🔐 Secrets Configuration

To run the CI/CD pipeline in GitHub Actions, you must configure the following repository secrets:

### Setting Up GitHub Secrets

1. **Go to your GitHub repository**
2. **Navigate to**: Settings → Secrets and variables → Actions
3. **Click**: "New repository secret"
4. **Add the following secrets:**

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `DOCKERHUB_USERNAME` | Your Docker Hub username | Your Docker Hub account username |
| `DOCKERHUB_TOKEN` | Docker Hub access token | Create at: Docker Hub → Account Settings → Security → New Access Token |

### How to Create Docker Hub Access Token

```bash
# 1. Log in to Docker Hub: https://hub.docker.com/
# 2. Go to Account Settings → Security
# 3. Click "New Access Token"
# 4. Name: "GitHub Actions CI"
# 5. Permissions: Read, Write, Delete
# 6. Copy the token (you won't see it again!)
# 7. Add as DOCKERHUB_TOKEN in GitHub Secrets
```

### Security Best Practices for Secrets

✅ **DO:**
- Use Docker Hub **access tokens** (not passwords)
- Set minimal required permissions on tokens
- Rotate tokens periodically (every 90 days)
- Use separate tokens for different services
- Store secrets only in GitHub Secrets (never in code)

❌ **DON'T:**
- Commit secrets to Git (ever!)
- Share secrets in plain text
- Use the same password for everything
- Store secrets in environment variables permanently
- Use personal passwords as tokens

### Verifying Secrets Are Working

After configuring secrets, trigger the CI pipeline:

```bash
# Push to main branch
git push origin main

# Or manually trigger workflow
# Go to Actions tab → CI workflow → Run workflow
```

Check the workflow logs:
- "Log in to Docker Hub" step should succeed
- "Push image to Docker Hub" step should complete
- Image should appear in your Docker Hub repository

---

## 🔄 CI Pipeline Explanation

The CI pipeline is defined in `.github/workflows/ci.yml` and implements a **security-first, shift-left** approach with multiple quality gates.

### Pipeline Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     GitHub Push/PR Event                         │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 1: Checkout & Setup                                      │
│  - Clone repository                                              │
│  - Setup Java 17 with Maven cache                                │
│  - Initialize CodeQL for SAST                                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 2: Quality & Security Gates (Shift-Left Security)        │
│  ┌─────────────────────────────────────────────────────────┐   │
│  │ 1. Checkstyle Lint    → Code quality standards           │   │
│  │ 2. Trivy SCA          → Dependency vulnerabilities       │   │
│  │ 3. Unit Tests         → Business logic validation        │   │
│  └─────────────────────────────────────────────────────────┘   │
│  ⚠️  Pipeline FAILS if any gate fails                           │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 3: Build & SAST Analysis                                 │
│  - Build JAR with Maven                                          │
│  - Run CodeQL SAST analysis                                      │
│  - Upload findings to GitHub Security                            │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 4: Container Build & Scan                                │
│  - Build Docker image (multi-stage)                              │
│  - Tag with git SHA + latest                                     │
│  - Scan image with Trivy (OS + libraries)                        │
│  ⚠️  Fails on HIGH/CRITICAL vulnerabilities                     │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 5: Runtime Validation (Smoke Test)                       │
│  - Start container                                               │
│  - Wait for health check                                         │
│  - Test /users endpoint                                          │
│  - Verify JSON response                                          │
│  ⚠️  Fails if app doesn't respond in 60s                        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│  Stage 6: Publish to Registry                                   │
│  - Login to Docker Hub (using secrets)                           │
│  - Push image:SHA                                                │
│  - Push image:latest                                             │
│  ✅ Only trusted, scanned images reach registry                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│              📦 Trusted Image in Docker Hub                      │
│           Ready for deployment to any environment                │
└─────────────────────────────────────────────────────────────────┘
```

### Detailed Stage Breakdown

#### **Stage 1: Checkout & Setup**

```yaml
- name: Checkout source
  uses: actions/checkout@v4
```
**Purpose**: Clone the exact commit being built to ensure reproducibility.

```yaml
- name: Set up Java
  uses: actions/setup-java@v4
  with:
    distribution: temurin
    java-version: '17'
    cache: maven
```
**Purpose**: 
- Install OpenJDK 17 (Temurin distribution)
- Enable Maven dependency caching for faster builds
- Ensure consistent build environment

```yaml
- name: Initialize CodeQL
  uses: github/codeql-action/init@v3
  with:
    languages: java
```
**Purpose**: Initialize GitHub's CodeQL SAST engine to analyze code for security vulnerabilities.

---

#### **Stage 2: Quality & Security Gates**

**2.1 Code Linting with Checkstyle**
```yaml
- name: Lint with Checkstyle
  run: mvn -B checkstyle:check
```
**Purpose**:
- Enforce coding standards (Sun style guide)
- Catch common code quality issues
- Fail fast on style violations
- **Why it matters**: Consistent code is easier to review and audit for security issues

**2.2 Dependency Vulnerability Scanning (SCA)**
```yaml
- name: Dependency vulnerability scan (SCA)
  uses: aquasecurity/trivy-action@0.24.0
  with:
    scan-type: 'fs'
    scan-ref: '.'
    format: 'table'
    severity: 'HIGH,CRITICAL'
    exit-code: '1'
    ignore-unfixed: true
```
**Purpose**:
- Scan Maven dependencies for known CVEs
- Check against vulnerability databases (NVD, OSV, etc.)
- Fail on HIGH/CRITICAL severity issues
- Ignore unfixed vulnerabilities (no remediation available)
- **Why it matters**: Prevents supply chain attacks (OWASP Top 10 2021 - A06:2021)

**2.3 Unit Tests**
```yaml
- name: Run unit tests
  run: mvn -B test
```
**Purpose**:
- Validate business logic
- Prevent regressions
- Ensure code quality
- **Why it matters**: Broken functionality is a security risk

---

#### **Stage 3: Build & SAST**

**3.1 Package Application**
```yaml
- name: Package application
  run: mvn -B -DskipTests package
```
**Purpose**:
- Compile Java code
- Create executable JAR
- Prepare artifact for containerization
- Serves as the "build" step for CodeQL

**3.2 CodeQL SAST Analysis**
```yaml
- name: Analyze with CodeQL
  uses: github/codeql-action/analyze@v3
```
**Purpose**:
- Perform static analysis on compiled code
- Detect security vulnerabilities:
  - SQL Injection
  - XSS (Cross-Site Scripting)
  - Path Traversal
  - Insecure Deserialization
  - Authentication/Authorization flaws
- Upload findings to GitHub Security tab
- **Why it matters**: Catches OWASP Top 10 vulnerabilities before deployment

---

#### **Stage 4: Container Build & Scan**

**4.1 Build Docker Image**
```yaml
- name: Build Docker image
  run: |
    docker build --pull -t $IMAGE_NAME:${{ github.sha }} .
    docker tag $IMAGE_NAME:${{ github.sha }} $IMAGE_NAME:latest
```
**Purpose**:
- Build container using multi-stage Dockerfile
- Tag with git SHA for immutability and traceability
- Create rolling `latest` tag for convenience
- `--pull` ensures base images are up-to-date

**4.2 Trivy Image Scan**
```yaml
- name: Scan image with Trivy
  uses: aquasecurity/trivy-action@0.24.0
  with:
    image-ref: $IMAGE_NAME:${{ github.sha }}
    format: table
    vuln-type: 'os,library'
    severity: 'HIGH,CRITICAL'
    exit-code: '1'
```
**Purpose**:
- Scan OS packages (Alpine apk packages)
- Scan application libraries (JAR dependencies)
- Detect vulnerabilities in final runtime image
- Fail on HIGH/CRITICAL findings
- **Why it matters**: Defense in depth - catches vulnerabilities that slipped through earlier stages

---

#### **Stage 5: Runtime Validation**

```yaml
- name: Container smoke test
  run: |
    docker run -d -p 8080:8080 --name app-under-test $IMAGE_NAME:${{ github.sha }}
    for _ in {1..12}; do
      if curl -fsS http://localhost:8080/users > /tmp/response.json; then
        cat /tmp/response.json
        exit 0
      fi
      sleep 5
    done
    echo "Application did not become healthy in time" >&2
    exit 1
```
**Purpose**:
- Start the actual container
- Wait up to 60 seconds for app to be healthy
- Test real HTTP endpoint
- Validate JSON response
- **Why it matters**: 
  - Catches runtime errors (misconfigured ports, missing env vars)
  - Validates health check configuration
  - Ensures image actually works before publishing

---

#### **Stage 6: Publish to Registry**

**6.1 Docker Hub Login**
```yaml
- name: Log in to Docker Hub
  uses: docker/login-action@v3
  with:
    username: ${{ secrets.DOCKERHUB_USERNAME }}
    password: ${{ secrets.DOCKERHUB_TOKEN }}
```
**Purpose**:
- Authenticate with Docker Hub using GitHub Secrets
- No credentials in code (security best practice)
- Use access token (not password)

**6.2 Push Images**
```yaml
- name: Push image to Docker Hub
  run: |
    docker push $IMAGE_NAME:${{ github.sha }}
    docker push $IMAGE_NAME:latest
```
**Purpose**:
- Publish SHA-tagged image (immutable, traceable)
- Update latest tag (convenience)
- **Why it matters**: Only images that passed ALL gates are published

**6.3 Cleanup**
```yaml
- name: Cleanup container
  if: always()
  run: docker rm -f app-under-test || true
```
**Purpose**: Clean up test container regardless of success/failure

---

### Why This Pipeline Design?

#### **1. Shift-Left Security**
Security checks (linting, SCA, SAST) run **before** building artifacts. This:
- Catches issues early (cheaper to fix)
- Prevents vulnerable code from progressing
- Reduces attack surface from the start

#### **2. Defense in Depth**
Multiple overlapping security controls:
- **CodeQL**: Finds code-level vulnerabilities
- **Trivy (filesystem)**: Finds dependency vulnerabilities
- **Trivy (image)**: Finds OS and runtime vulnerabilities
- **Smoke test**: Validates runtime behavior

#### **3. Fail-Fast Strategy**
Pipeline stops at first critical failure:
- Saves compute resources
- Provides faster feedback
- Each stage gate blocks progression

#### **4. Supply Chain Security**
- Maven cache verified
- Base images pulled fresh (`--pull`)
- Dependencies scanned (SCA)
- Only trusted images reach registry

#### **5. Reproducibility & Traceability**
- Images tagged with git SHA
- Exact commit is scannable
- Build environment is pinned (Java 17, Maven versions)
- Audit trail in GitHub Actions logs

#### **6. Zero Trust to Registry**
Only images that pass:
- ✅ Code quality (Checkstyle)
- ✅ Dependency scan (SCA)
- ✅ Code scan (SAST)
- ✅ Image scan
- ✅ Runtime test

...are published to Docker Hub.

---

### Pipeline Metrics

| Stage | Typical Duration | Can Fail? | Critical? |
|-------|-----------------|-----------|-----------|
| Checkout & Setup | 30-60s | No | - |
| Lint | 10-20s | Yes | No (quality) |
| SCA Scan | 30-60s | Yes | Yes (security) |
| Unit Tests | 10-30s | Yes | Yes (quality) |
| Build JAR | 30-60s | Yes | Yes (build) |
| CodeQL SAST | 2-5 min | Yes | Yes (security) |
| Docker Build | 1-3 min | Yes | Yes (build) |
| Image Scan | 30-90s | Yes | Yes (security) |
| Smoke Test | 30-60s | Yes | Yes (validation) |
| Push to Registry | 30-60s | Yes | No (delivery) |
| **Total** | **~8-12 min** | - | - |

---

## 🔒 Security Features

### Application Security
- ✅ No hardcoded credentials
- ✅ Minimal dependencies (reduced attack surface)
- ✅ Updated Spring Boot & Tomcat versions (CVE fixes)
- ✅ Input validation on endpoints
- ✅ CORS configuration ready

### Container Security
- ✅ Multi-stage build (build artifacts not in runtime)
- ✅ Alpine Linux base (minimal OS)
- ✅ Non-root user (UID 1000)
- ✅ Security patches applied (`apk upgrade`)
- ✅ Health check configured
- ✅ Minimal layers (optimized Dockerfile)

### Kubernetes Security
- ✅ Security contexts (drop all capabilities)
- ✅ Read-only root filesystem
- ✅ Non-root pod execution
- ✅ Resource limits (CPU/memory)
- ✅ Network policies (traffic restriction)
- ✅ Namespace isolation
- ✅ Liveness and readiness probes

### CI/CD Security
- ✅ Secrets in GitHub Secrets (not code)
- ✅ SAST with CodeQL
- ✅ SCA with Trivy
- ✅ Container scanning with Trivy
- ✅ Fail on HIGH/CRITICAL vulnerabilities
- ✅ Smoke test before publishing
- ✅ Minimal pipeline permissions

---

## 📁 Project Structure

```
dev-Secops/
├── .github/
│   └── workflows/
│       └── ci.yml                  # CI/CD pipeline definition
│
├── src/
│   ├── main/
│   │   └── java/
│   │       └── com/example/devops/
│   │           ├── Application.java           # Spring Boot main class
│   │           ├── controller/
│   │           │   └── UserController.java    # REST controller
│   │           └── model/
│   │               └── User.java              # User model
│   └── test/
│       └── java/
│           └── com/example/devops/
│               └── controller/
│                   └── UserControllerTest.java # Unit tests
│
├── k8s/                            # Kubernetes manifests
│   ├── README.md                   # K8s deployment guide
│   ├── namespace.yaml              # Namespace definition
│   ├── deployment.yaml             # Deployment (2 replicas)
│   ├── service.yaml                # Service (NodePort 30080)
│   ├── configmap.yaml              # Configuration
│   └── networkpolicy.yaml          # Network security
│
├── Dockerfile                      # Multi-stage container build
├── pom.xml                         # Maven dependencies
├── checkstyle.xml                  # Code style rules
├── setup-local-k8s.sh              # K8s cluster setup script
├── cleanup-k8s.sh                  # K8s cleanup script
└── README.md                       # This file
```

---

## 🎯 DevSecOps Principles Implemented

### 1. **Shift-Left Security**
Security testing happens early in the pipeline (before build), not at the end.

### 2. **Automation**
Zero manual steps - everything is automated and repeatable.

### 3. **Continuous Integration**
Every commit triggers the full pipeline with all quality gates.

### 4. **Infrastructure as Code**
Kubernetes manifests and pipeline definition are version-controlled.

### 5. **Immutable Artifacts**
Docker images are tagged with git SHA and never modified.

### 6. **Defense in Depth**
Multiple layers of security controls (code, dependencies, container, runtime).

### 7. **Fail-Fast**
Pipeline stops immediately on critical failures.

### 8. **Least Privilege**
Containers run as non-root, minimal permissions everywhere.

### 9. **Observability**
Health checks, logs, and metrics built-in from the start.

### 10. **Supply Chain Security**
Dependencies and base images are scanned and verified.

---

## 🚧 Troubleshooting

### CI Pipeline Failures

**"Checkstyle check failed"**
```bash
# Run locally to see errors
mvn checkstyle:check

# Auto-fix some issues
# (Unfortunately Checkstyle doesn't auto-fix, review manually)
```

**"Trivy found HIGH/CRITICAL vulnerabilities"**
```bash
# Run Trivy locally
docker run --rm -v $(pwd):/app aquasecurity/trivy fs /app

# Update dependencies in pom.xml
# Check for newer versions: https://mvnrepository.com/
```

**"Unit tests failed"**
```bash
# Run tests locally
mvn test

# Run specific test
mvn test -Dtest=UserControllerTest
```

**"Image scan failed"**
```bash
# Scan local image
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasecurity/trivy image devops-ci-api:local

# Update base image in Dockerfile
# Update dependencies in pom.xml
```

**"Docker Hub push failed - authentication"**
- Verify `DOCKERHUB_USERNAME` secret is set correctly
- Verify `DOCKERHUB_TOKEN` is a valid access token (not password)
- Check token hasn't expired
- Verify token has Read, Write permissions

### Local Development Issues

**"Port 8080 already in use"**
```bash
# Find what's using the port
lsof -i :8080

# Kill the process
kill -9 <PID>

# Or use a different port
mvn spring-boot:run -Dspring-boot.run.arguments=--server.port=8081
```

**"Docker build fails"**
```bash
# Check Docker is running
docker ps

# Clean up Docker system
docker system prune -a

# Rebuild with no cache
docker build --no-cache -t devops-ci-api:local .
```

### Kubernetes Issues

**See [k8s/README.md](k8s/README.md) for detailed Kubernetes troubleshooting.**

---

## 📚 Additional Resources

- **Kubernetes Guide**: [k8s/README.md](k8s/README.md)
- **Spring Boot Docs**: https://spring.io/projects/spring-boot
- **GitHub Actions**: https://docs.github.com/en/actions
- **CodeQL**: https://codeql.github.com/docs/
- **Trivy**: https://aquasecurity.github.io/trivy/
- **Docker Security**: https://docs.docker.com/engine/security/
- **OWASP Top 10**: https://owasp.org/www-project-top-ten/

---

## 📝 For Project Report

### Highlights for Assessment

1. **Complete CI/CD Pipeline**: From code commit to production-ready image
2. **Security Integration**: SAST, SCA, container scanning at every stage
3. **DevSecOps Principles**: Shift-left security, fail-fast, automation
4. **Production-Ready**: Multi-stage builds, health checks, resource limits
5. **Kubernetes Deployment**: Local CD with security hardening
6. **Documentation**: Comprehensive guides and inline comments

### Demonstration Checklist

- [ ] Show GitHub Actions workflow running
- [ ] Explain each pipeline stage and its purpose
- [ ] Show security scan results (CodeQL, Trivy)
- [ ] Show Docker image in Docker Hub
- [ ] Deploy to local Kubernetes
- [ ] Show running pods and services
- [ ] Test the API endpoint
- [ ] Explain security features implemented
- [ ] Show scalability (scale replicas)
- [ ] Show logs and monitoring

---

## 👨‍💻 Author

Built for Advanced DevOps CI/CD Project demonstrating production-grade DevSecOps practices.

---

## 📄 License

This project is for educational purposes as part of a DevOps course assessment.
