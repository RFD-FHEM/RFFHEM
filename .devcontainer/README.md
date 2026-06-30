## Devcontainer# RFFHEM Development Environment

## Overview

Welcome to the RFFHEM development environment! 
This setup uses VSCode DevContainers to provide a consistent and seamless development experience.

### What are DevContainers?

DevContainers are a feature in VSCode that allows you to develop within a Docker container.
This ensures that your development environment is consistent across different machines and setups.
By defining a containerized environment, you can eliminate the "works only my machine" problem.

### Advantages of DevContainers

- **Consistency**: Same environment for all developers.
- **Isolation**: Separate development environment from your local machine.
- **Reproducibility**: Easily recreate the environment on any machine.
- **Pre-configured Tools**: Include all necessary tools and dependencies in the container.
- **Pre-configured Tasks**: Tasks for common operations like running tests are provided.

## DevContainer Setup

The DevContainer configuration provides up all the necessary services for a mininal fhem setup.

Data is not stored persistent to ensure clean container restarts.

## Configuration Files

`compose.local.yml` contains the repo-specific parts of the previous
devcontainer compose setup.

`compose.override.yml` carries the repo-specific FHEM start configuration.

The setup includes tasks (`tasks.json`) to help you running tests and working
with the optional SVN addon:

- **Testing:**
  - `run prove FHEM module tests`
  - `run proove all FHEM tests`
  - `run prove Perl module files`
- **SVN:**
  - `run SVN checkout`
  - `sync module to SVN`

The post-start hook now runs `.devcontainer/scripts/bootstrap-worktree.sh`,
which keeps the existing symlink-based runtime setup intact while matching the
toolkit-style entry point.

To bring up the optional SVN add-on outside VS Code, layer
`.devcontainer/compose.addon-svn.yml` on top of the composed base/local files:

```bash
docker compose -f .devcontainer/compose.yml -f .devcontainer/compose.override.yml -f .devcontainer/compose.local.yml -f .devcontainer/compose.addon-svn.yml up -d
```

The main compose stack is:

```bash
docker compose -f .devcontainer/compose.yml -f .devcontainer/compose.override.yml -f .devcontainer/compose.local.yml up -d
```

In VS Code, `forwardPorts` exposes container ports `8083` and `7072` without
binding fixed host ports, so the devcontainer does not collide with a live FHEM
instance or other containers.

The devcontainer image creates a non-root development user by default:

- user: `dev`
- uid: `1000`
- gid: `1000`

You can override those values at build time with:

- `DEVCONTAINER_USER`
- `DEVCONTAINER_UID`
- `DEVCONTAINER_GID`

VS Code connects as that user by default, while the image bootstrap still
starts FHEM with the root-required init flow from the base image.

If you start Compose manually and want to inspect the assigned host port, use:

```bash
docker compose -f .devcontainer/compose.yml -f .devcontainer/compose.override.yml -f .devcontainer/compose.local.yml port fhem-dev 8083
```

## Getting Started

### Step 1: Running the DevContainer

To start the DevContainer:

1. Open VSCode.
2. Open the project folder.
3. Open the command palette and choose `Dev Containers: Rebuild and Reopen in Container`.

VSCode will build and start the DevContainer environment.

### Step 2: Developing

Once the DevContainer is up and running, you can edit all project files directly in VSCode and run tests withhin Perl or FHEM.
