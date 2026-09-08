# GitHub Actions Runners

Deploys self-hosted GitHub Actions runners for the `OSWatcher/osw-builder` repository (20 by default).

## Setup

1. Set the target host in `inventory.yml`.

2. Set GitHub token:
   ```bash
   export GITHUB_TOKEN="your_token"
   ```

3. Deploy runners:
   ```bash
   ansible-playbook -i inventory.yml site.yml
   ```

## Configuration

- **Target**: `OSWatcher/osw-builder`
- **Count**: 20 runners (`builder-1` to `builder-20`)
- **Location**: `/home/{user}/runners/`

Edit `roles/runner/vars/main.yml` to modify settings.

## Management

- **Stop**: Set `runner_state: "stopped"` and re-run playbook
- **Remove**: Set `runner_state: "absent"` and re-run playbook
