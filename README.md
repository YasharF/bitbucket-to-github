# Bitbucket to GitHub Migration Script

Automates the migration of all accessible Bitbucket repositories to GitHub as private mirrors.
Supports multiple workspaces, handles pagination, and renames default branches to `main` when appropriate.

## Features

- Fetches all Bitbucket workspaces the user has access to
- Iterates through all Git-based repositories in each workspace
- Creates corresponding private repositories on GitHub
- Clones each repo with `--mirror` and pushes all refs
- Detects and renames default branches to `main` if needed
- Cleans up local clones after migration

## Requirements

- Bash
- curl, jq, git installed and available in $PATH
- Bitbucket App Password with appropriate scopes
- GitHub Personal Access Token with repo scope

### Installing jq

This script uses jq to parse JSON responses from the Bitbucket API.  
If it's not already installed, you can install it on Debian/Ubuntu-based systems with:

```
    sudo apt-get update
    sudo apt-get install jq
```

## Authentication Notes

### Bitbucket App Password

Must be generated from your Bitbucket account settings.  
Ensure the following scopes are enabled:

- Repository: Read — to access repo contents
- Workspace membership: Read — to list workspaces
- Account: Read — required to enumerate accessible workspaces

### GitHub Token

Must be a Personal Access Token with the following scope
(Personal Account Settings -> Developer Settings -> Fine-grained tokens) :

- Read and Write access to administration and code

## Usage

1. Set the script permissions if needed:

```
chmod +x migrate-bitbucket-to-github.sh
```

2. Set the following environment variables at the top of the script:

   BITBUCKET_USERNAME="your-bitbucket-username"
   BITBUCKET_APP_PASSWORD="your-bitbucket-app-password"
   GITHUB_USERNAME="your-github-username"
   GITHUB_TOKEN="your-github-token"

3. Run the script:

   ./migrate-bitbucket-to-github.sh

### Windows Support

If you are using Windows, install WSL (Windows Subsystem for Linux) to run the Script. Use of the latest LTS Ubuntu as the distribution for WSL is recommended.

## Troubleshooting

- If no workspaces are detected despite having access in Bitbucket, it's likely due to incorrect credentials or missing scopes in your Bitbucket App Password.  
  Double-check that Account: Read is enabled — without it, workspace enumeration will silently fail.

- Only Git-based repositories are migrated (Mercurial is ignored).
- Repositories are cloned using --mirror, preserving all refs and branches.
- If the default branch is not main, and main does not already exist, it will be renamed accordingly.
- All migrated repositories are created as private on GitHub.

## License

Copyright © 2025 Yashar Fakhari — [Apache License 2.0](LICENSE)
