# GitLab CE Docker Setup

Self-hosted GitLab Community Edition running in containers.

## Prerequisites

- Podman and Podman Compose installed
- Add `127.0.0.1 gitlab.local` to your hosts file:
  - **Windows:** `C:\Windows\System32\drivers\etc\hosts`
  - **Linux/Mac:** `/etc/hosts`

## Quick Start

```bash
# Start GitLab
podman compose up -d

# Watch startup logs (takes 3-5 minutes on first boot)
podman logs -f gitlab
```

Access GitLab at: `https://gitlab.local:8443`

**Default login:**
- Username: `root`
- Password: See `GITLAB_ROOT_PASSWORD` in `.env`

## Configuration

### Environment Variables (.env)

| Variable | Description |
|----------|-------------|
| `GITLAB_HOSTNAME` | Hostname for GitLab (must match hosts file) |
| `GITLAB_ROOT_PASSWORD` | Initial root password (first boot only) |
| `GITLAB_HTTP_PORT` | HTTP port mapping |
| `GITLAB_HTTPS_PORT` | HTTPS port mapping |
| `GITLAB_SSH_PORT` | SSH port for git operations |
| `TZ` | Timezone |
| `GITLAB_RUNNER_TOKEN` | Shared runner registration token |

### GitLab Configuration (config/gitlab.rb)

Edit `config/gitlab.rb` to customize GitLab settings, then apply:

```bash
podman exec -it gitlab gitlab-ctl reconfigure
```

Or restart the container:

```bash
podman compose restart
```

## Reset / Troubleshooting

### Reset Root Password

```bash
podman exec -it gitlab gitlab-rake "gitlab:password:reset[root]"
```

Or via Rails console:

```bash
podman exec -it gitlab gitlab-rails console -e production
```

```ruby
user = User.find_by_username('root')
user.password = 'NewPassword123!'
user.password_confirmation = 'NewPassword123!'
user.save!
exit
```

### Full Reset (Delete All Data)

```bash
# Stop and remove containers + volumes
podman compose down -v

# Clean local directories
Remove-Item -Recurse -Force data\*, logs\*
Get-ChildItem config -Exclude gitlab.rb | Remove-Item -Recurse -Force

# Start fresh
podman compose up -d
```

### Check Service Status

```bash
podman exec -it gitlab gitlab-ctl status
```

### View Logs

```bash
# Container logs
podman logs -f gitlab

# GitLab internal logs
podman exec -it gitlab gitlab-ctl tail
```

## Ports

| Service | Container Port | Host Port |
|---------|---------------|-----------|
| HTTP | 80 | 8080 |
| HTTPS | 443 | 8443 |
| SSH | 22 | 2222 |

## Git SSH Access

```bash
git clone ssh://git@gitlab.local:2222/username/repo.git
```

## GitLab Runner

A GitLab Runner container is included for CI/CD pipelines.

### Auto-Registration

The runner automatically registers with GitLab on startup using the `GITLAB_RUNNER_TOKEN` from `.env`. It will:

1. Wait for GitLab to be available
2. Register itself as a shared runner
3. Start processing jobs

View registration progress:

```bash
podman logs -f gitlab-runner
```

### Manual Registration (Optional)

If you need to register manually or add additional runners:

```bash
podman exec -it gitlab-runner gitlab-runner register \
  --url "https://gitlab.local:8443" \
  --registration-token "YOUR_TOKEN" \
  --executor "docker" \
  --docker-image "alpine:latest" \
  --tls-verify=false
```

### Runner Commands

```bash
# Check runner status
podman exec -it gitlab-runner gitlab-runner status

# List registered runners
podman exec -it gitlab-runner gitlab-runner list

# Verify runner connection
podman exec -it gitlab-runner gitlab-runner verify

# View runner logs
podman logs -f gitlab-runner
```

### Unregister Runner

```bash
podman exec -it gitlab-runner gitlab-runner unregister --all-runners
```
