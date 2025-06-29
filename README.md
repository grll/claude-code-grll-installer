# @claude OAuth Installer

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Easy installer for Claude Code OAuth workflows - Set up @claude mentions in your GitHub repositories with a single script.

```
╔══════════════════════════════════════════════════════════════════════════╗
║                                                                          ║
║                   ✨ @claude OAuth Installer ✨                          ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

  ██████╗██╗      █████╗ ██╗   ██╗██████╗ ███████╗
 ██╔════╝██║     ██╔══██╗██║   ██║██╔══██╗██╔════╝
 ██║     ██║     ███████║██║   ██║██║  ██║█████╗  
 ██║     ██║     ██╔══██║██║   ██║██║  ██║██╔══╝  
 ╚██████╗███████╗██║  ██║╚██████╔╝██████╔╝███████╗
  ╚═════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚═════╝ ╚══════╝
 ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     ███████╗██████╗ 
 ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     ██╔════╝██╔══██╗
 ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     █████╗  ██████╔╝
 ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     ██╔══╝  ██╔══██╗
 ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗███████╗██║  ██║
 ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝╚═╝  ╚═╝

 by @grll
```

## What This Does

This installer automatically sets up Claude Code OAuth integration for your GitHub repositories, allowing you to use @claude mentions in issues and PRs. The script:

✅ **Checks prerequisites** (GitHub CLI, jq)  
✅ **Detects your GitHub username**  
✅ **Sets up repository secrets**  
✅ **Creates GitHub workflows**  
✅ **Commits and pushes everything**  
✅ **Provides step-by-step instructions**  

## Quick Start

### One-liner installation:

Make sure you `cd` into your repo, have `gh` and `jq` available in your environment.

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/grll/claude-installer/main/installer.sh)
```

### Manual installation:

```bash
# Download the installer
curl -fsSL https://raw.githubusercontent.com/grll/claude-installer/main/installer.sh -o installer.sh

# Make it executable
chmod +x installer.sh

# Run it
./installer.sh
```

### With specific repository:

```bash
./installer.sh --repo your-username/your-repo
```

## Prerequisites

Before running the installer, make sure you have:

1. **GitHub CLI** installed and authenticated
   ```bash
   # Install GitHub CLI
   brew install gh  # macOS
   # or
   sudo apt install gh  # Ubuntu/Debian
   
   # Authenticate
   gh auth login
   ```

2. **jq** for JSON parsing
   ```bash
   brew install jq  # macOS
   # or
   sudo apt install jq  # Ubuntu/Debian
   ```

3. **Personal Access Token** for secrets management
   - Visit: [SECRETS_ADMIN_PAT Setup Guide](https://github.com/grll/claude-code-login?tab=readme-ov-file#prerequisites-setting-up-secrets_admin_pat)
   - The installer will prompt you for this token

## What Gets Created

The installer creates two GitHub workflows:

### 1. `claude_code_login.yml`
OAuth authentication workflow for Claude Code login process.

### 2. `claude_code.yml`
PR assistant workflow that responds to @claude mentions (restricted to your username).

## After Installation

Once the installer completes, follow these steps:

1. **Run OAuth workflow** (without code)
   - Go to: `https://github.com/your-repo/actions/workflows/claude_code_login.yml`
   - Click "Run workflow" → "Run workflow" (leave code empty)

2. **Get login URL**
   - Wait for workflow completion
   - Find the login URL in the action summary

3. **Authenticate with Claude**
   - Visit the generated URL
   - Log in to Claude
   - Copy the authorization code

4. **Complete setup**
   - Run the workflow again with the authorization code
   - Paste your code and run the workflow

5. **Start using Claude**
   - Create issues or PRs and mention @claude
   - Only your username can trigger Claude responses

## Features

- 🎨 **Beautiful terminal UI** with colors and ASCII art
- 🔍 **Smart repository detection** 
- 🔐 **Secure secret management**
- 📝 **Comprehensive error handling**
- 🚀 **Automatic git operations** (stash, commit, push)
- 🎯 **Personalized workflows** (uses your GitHub username)
- 📋 **Step-by-step instructions**

## Command Line Options

```bash
./installer.sh [OPTIONS]

OPTIONS:
  --repo OWNER/REPO    Specify repository (default: auto-detect current repo)
  --help              Show this help message
```

## Troubleshooting

### Common Issues

**"gh: command not found"**
- Install GitHub CLI: https://cli.github.com/

**"jq: command not found"**
- Install jq: https://jqlang.github.io/jq/

**"Failed to get GitHub username"**
- Run: `gh auth login`

**"Cannot access repository"**
- Ensure repository exists and you have access
- Check authentication: `gh auth status`

### Getting Help

- 📖 [Claude Code Login Documentation](https://github.com/grll/claude-code-login)
- 🐛 [Report Issues](https://github.com/grll/claude-installer/issues)
- 💬 [Discussions](https://github.com/grll/claude-installer/discussions)

## Related Projects

- [claude-code-login](https://github.com/grll/claude-code-login) - The underlying OAuth action
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) - Official Claude Code documentation

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions welcome! Please read our contributing guidelines and submit pull requests.

---

<div align="center">

**Made by [@grll](https://github.com/grll)**

*Simplifying Claude Code OAuth setup, one repo at a time.*

</div>
