# Advanced DevSecOps CI Pipeline (Java Spring Boot)

A minimal Java 17 Spring Boot REST API exposing `/users`, built with Maven and delivered through a security-first GitHub Actions CI pipeline. The workflow enforces code quality, SAST, SCA, container scanning, runtime validation, and trusted publishing to Docker Hub.

## Application Overview
- Java 17 / Spring Boot 3.2
- Endpoint: `GET /users` returns a static list of sample users
- Packaging: executable JAR via Maven
- Container: multi-stage build on Alpine-based Temurin JRE, port 8080

## CI Pipeline (GitHub Actions)
Workflow: `.github/workflows/ci.yml`
Triggers: push to `master`, manual `workflow_dispatch`.

Stages (in order) and purpose:
1. **Checkout** – build and scan the exact commit.
2. **Setup Java with Maven cache** – reproducible toolchain and faster builds.
3. **CodeQL init** – enable SAST with results in GitHub Security.
4. **Checkstyle lint** – enforce coding standards and fail fast on style drift.
5. **OWASP Dependency-Check** – SCA gate; fails on CVSS ≥ 7 (HIGH/CRITICAL).
6. **Unit tests** – prevent regressions; ensures business logic holds.
7. **Package JAR** – produces artifact and serves as the CodeQL build step.
8. **CodeQL analyze** – uploads SAST findings; breaks on unresolved issues.
9. **Docker build** – builds image with immutable SHA + `latest` tags.
10. **Trivy scan** – blocks on HIGH/CRITICAL image vulnerabilities (OS & libs).
11. **Container smoke test** – runs the image, curls `/users`, and fails on health issues.
12. **Docker Hub push** – publishes only after all quality and security gates pass.

## Security Controls
- **Secrets:** `DOCKERHUB_USERNAME`, `DOCKERHUB_TOKEN` consumed via GitHub Secrets; no hardcoded credentials.
- **SAST:** GitHub CodeQL for Java.
- **SCA:** OWASP Dependency-Check with CVSS fail threshold (>= 7).
- **Container scanning:** Trivy with HIGH/CRITICAL gate and `ignore-unfixed=true` to focus on actionable items.
- **Minimal image:** Alpine-based Temurin JRE, non-root `app` user, and healthcheck hitting `/users`.
- **Fail-fast:** Each gate blocks downstream stages; workflow exits on first critical failure.

## Local Development
Prerequisites: Java 17, Maven, Docker (optional for container steps).

### Run locally
```bash
mvn spring-boot:run
# then hit http://localhost:8080/users
```

### Run tests and lint locally
```bash
mvn checkstyle:check
mvn test
```

### Build and run container locally
```bash
mvn -DskipTests package
docker build -t devops-ci-api:local .
docker run -p 8080:8080 devops-ci-api:local
curl http://localhost:8080/users
```

## CI Secrets Configuration
Set the following repository secrets before running the workflow:
- `DOCKERHUB_USERNAME` – Docker Hub username.
- `DOCKERHUB_TOKEN` – Docker Hub access token or password (token recommended).

## Why This Pipeline (Assessment Notes)
- **Shift-left security:** SAST and SCA run before build/package, preventing vulnerable code from progressing.
- **Supply-chain trust:** Dependency-Check + Trivy provide layered checks across code, libraries, and container OS.
- **Operational readiness:** Smoke test confirms the container actually serves `/users` before publishing.
- **Reproducibility:** Maven cache + pinned Java version; image tagged with SHA for traceability.
- **Least privilege:** Non-root runtime user in container; credentials sourced from secrets only.
