# Kamal Easy

**Unified deployment wrapper for Kamal.**
Simplifies multi-environment deployments (UAT/Production) and provides unified commands for logs and access to the remote console.

## 🚀 Installation

Add this line to your application's Gemfile:

```ruby
gem 'kamal-easy', git: 'https://github.com/overnet/kamal-easy.git'
# OR locally during development:
# gem 'kamal-easy', path: '../gems/kamal-easy'
```

And then execute:

```bash
bundle install
```

## ⚙️ Configuration

Run the installer to generate the configuration file:

```bash
bundle exec kamal-easy install
```

This will create `config/kamal-easy.yml`. Configure it for your project:

```yaml
# config/kamal-easy.yml
environments:
  uat:
    env_file: .env.uat
    credentials_file: config/credentials/uat.yml.enc
  staging:
    env_file: .env.staging
    credentials_file: config/credentials/staging.yml.enc
  production:
    env_file: .env.production
    credentials_file: config/credentials/production.yml.enc

components:
  backend:
    path: .
    kamal_cmd: "bundle exec kamal"
    container_name_pattern: "your-app-backend-api" # For console access
    mandatory_files:
      - config/deploy.yml
      - Dockerfile
  frontend:
    path: ../your-app-frontend
    kamal_cmd: "kamal"
    mandatory_files:
      - config/deploy.yml
```

### Mandatory Files
-   **`.env.uat` / `.env.staging` / `.env.production`**: Must exist in the component directory and contain necessary secrets (e.g., `RAILS_MASTER_KEY`).
-   **`config/deploy.yml`**: Standard Kamal configuration must be present in each component directory.
-   **`Dockerfile`**: Required for building images.

## 🛠️ Usage

### 1. Deployment (`kamal-easy deploy`)
Deploy specific components or the entire stack.

**Flags**:
- `--uat`: Deploy to UAT environment
- `--staging`: Deploy to Staging environment
- `--prod`: Deploy to Production environment
- `--all`: Deploy backend, frontend, and restart DB
- `--backend`: Deploy only backend
- `--frontend`: Deploy only frontend
- `--db`: Restart database accessory
- `--prune` / `-p`: Prune Docker system (images/containers) before deploy

```bash
# Deploy EVERYTHING (Backend + Frontend + DB)
bundle exec kamal-easy deploy --all --prod

# Deploy Specific Component
bundle exec kamal-easy deploy --backend --uat
bundle exec kamal-easy deploy --frontend --staging
bundle exec kamal-easy deploy --db --prod
```

### 2. Logs (`kamal-easy logs`)
Stream logs from the remote container.

**Aliases**:
- `--follow` -> `-f`
- `--lines` -> `-n`
- `--grep` -> `-g`

```bash
# Follow live logs (UAT)
bundle exec kamal-easy logs --uat -f

# View last 500 lines
bundle exec kamal-easy logs --prod -n 500

# Grep for errors
bundle exec kamal-easy logs --prod -g "Error"
```

### 3. Remote Console (`kamal-easy console`)
Securely access the remote Rails console.

**Aliases**:
- `console` -> `c`, `rails_console`

```bash
# Connect to UAT Console
bundle exec kamal-easy c --uat

# Connect to Production
bundle exec kamal-easy rails_console --prod
```

## 🏗️ Deployment Architecture (Reference)
This gem assumes a setup where:
1.  **Backend & Frontend** are in sibling directories.
2.  **Zero Downtime** is handled via Kamal Proxy / Traefik (internal port binding).
3.  **Credentials** are managed via `RAILS_MASTER_KEY`.
