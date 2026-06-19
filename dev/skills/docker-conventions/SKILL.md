---
name: docker-conventions
description: |
  Auto-load when reading, creating, or modifying container and image build files: Dockerfiles,
  compose files, .dockerignore, or orchestrator manifests that define image builds or runtime
  configuration. Covers build hygiene, image layering, environment variable handling, health
  checks, tagging, and local development compose setups.

  English triggers: "Dockerfile", "docker", "container", "image build", "docker compose",
  "compose file", ".dockerignore", "multi-stage build", "base image", "container health check",
  "image tag", "docker secret", "/dev:docker-conventions"

  České spouštěče: "Dockerfile", "docker", "kontejner", "build image", "docker compose",
  "compose soubor", ".dockerignore", "multi-stage build", "base image", "health check kontejneru",
  "tag image", "docker secret", "/dev:docker-conventions"

  Do NOT apply when: working on application code that runs inside a container but does not touch
  container configuration, or reading a Dockerfile only to understand the runtime environment
  while working on unrelated code.
---

# Docker & Containerization Conventions

## Dockerfile Standards

- Use multi-stage builds: a build stage (with dev/build dependencies) separate from the production stage (runtime only).
- Pin base image versions with a specific tag or SHA digest — never use `latest`.
- Order layers from least to most frequently changed: system dependencies → package installation → source copy → build step. This maximises cache reuse.
- Copy dependency manifests and lockfiles before source code to enable layer caching when only source changes.
- Run the process as a non-root user in the production stage.
- Use `COPY` rather than `ADD` unless you specifically need archive extraction.

## .dockerignore

- Always include a `.dockerignore` file. At minimum exclude: dependency directories (`node_modules`, `vendor`), `.git`, build output (`dist`, `build`), `*.md`, `.env*`, test fixtures, and IDE configs.

## Health Checks

- Define a `HEALTHCHECK` instruction in the Dockerfile or in the orchestrator configuration.
- The health endpoint must verify critical dependencies (data store, cache) — not just return a success status unconditionally.

## Environment Variables

- Never bake secrets or environment-specific configuration into images.
- Use `ENV` for non-sensitive defaults only. Inject secrets at runtime via the orchestrator (Kubernetes secrets, runtime secret stores, etc.).
- Document all required environment variables in a `.env.example` file committed to the repository.

## Image Tagging

- Tag images with the commit SHA for full traceability: `registry/app:<sha>`.
- Use semantic version tags for releases: `registry/app:1.2.3`.
- Never deploy an unversioned or `latest`-tagged image to production.

## Compose (Development)

- Use a compose file for local development dependencies (database, cache, message broker).
- Mount source code as volumes for hot reload during development.
- Use named volumes for persistent data (database files).
- Define explicit networks to isolate service communication.
- Use `depends_on` with service health checks to ensure dependencies are ready before the application starts.
- Expose debugger ports for local step-through debugging.
- Pass private registry credentials as build arguments — never bake them into an image layer.
- Read all configuration from a `.env` file — never hardcode values directly in the compose file.

## Image Size

- Use slim or distroless base images for production stages.
- Remove build artifacts, package manager caches, and unnecessary files in the same layer they were created.
- Minimize the production image footprint — fewer layers, smaller attack surface.
