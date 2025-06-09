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

The setup includes tasks (`tasks.json`) to help you running tests:

- **Testing:**
  - `run prove FHEM module tests`
  - `run proove all FHEM tests`
  - `run prove Perl module files`

## Getting Started

### Step 1: Running the DevContainer

To start the DevContainer:

1. Open VSCode.
2. Open the project folder.
3. Open the command palette and choose `Dev Containers: Rebuild and Reopen in Container`.

VSCode will build and start the DevContainer environment.

### Step 2: Developing

Once the DevContainer is up and running, you can edit all project files directly in VSCode and run tests withhin Perl or FHEM.

