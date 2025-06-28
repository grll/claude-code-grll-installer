#!/bin/bash

# Claude Code OAuth Installer Script
# Author: Guillaume Raille <guillaume.raille@gmail.com>

set -e

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${CYAN}ℹ ${WHITE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ ${WHITE}$1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠ ${WHITE}$1${NC}"
}

log_error() {
    echo -e "${RED}✗ ${WHITE}$1${NC}"
}

log_step() {
    echo -e "${MAGENTA}${BOLD}▶ $1${NC}"
}

# Helper functions for reading input when piped from curl
read_from_tty() {
    local prompt="$1"
    local input
    if [ -t 0 ]; then
        # Running interactively
        read -p "$prompt" input
    else
        # Running from pipe, use /dev/tty
        printf "%s" "$prompt" >/dev/tty
        read input </dev/tty
    fi
    echo "$input"
}

read_secret_from_tty() {
    local input
    if [ -t 0 ]; then
        # Running interactively
        read -s input
    else
        # Running from pipe, use /dev/tty
        read -s input </dev/tty
    fi
    echo "$input"
}

# ASCII Art Header
show_header() {
    clear
    echo -e "${CYAN}"
    cat << 'EOF'
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

EOF
    echo -e "${NC}"
}

# Parse command line arguments
REPO_ARG=""
while [[ $# -gt 0 ]]; do
    case $1 in
        --repo)
            REPO_ARG="$2"
            shift 2
            ;;
        *)
            log_error "Unknown option: $1"
            echo "Usage: $0 [--repo owner/repo-name]"
            exit 1
            ;;
    esac
done

# Show header
show_header

# Step 1: Check gh CLI installation
log_step "STEP 1: Checking GitHub CLI Installation"
if ! command -v gh &> /dev/null; then
    log_error "GitHub CLI (gh) is not installed or not in PATH"
    echo
    log_info "Please install GitHub CLI first:"
    echo "  • Visit: https://cli.github.com/"
    echo "  • Or use: brew install gh (macOS) or apt install gh (Ubuntu)"
    exit 1
fi
log_success "GitHub CLI is installed"

# Check jq installation
if ! command -v jq &> /dev/null; then
    log_error "jq is not installed or not in PATH"
    echo
    log_info "Please install jq first:"
    echo "  • Visit: https://jqlang.github.io/jq/"
    echo "  • Or use: brew install jq (macOS) or apt install jq (Ubuntu)"
    exit 1
fi
log_success "jq is installed"

# Step 2: Get GitHub username
log_step "STEP 2: Getting GitHub Username"
GITHUB_USERNAME=$(gh api user | jq -r '.login' 2>/dev/null)
if [ $? -ne 0 ] || [ "$GITHUB_USERNAME" = "null" ] || [ -z "$GITHUB_USERNAME" ]; then
    log_error "Failed to get GitHub username. Please ensure you're logged in to GitHub CLI"
    echo
    log_info "Run: gh auth login"
    exit 1
fi
log_success "Authenticated as: $GITHUB_USERNAME"

# Step 3: Repository detection/selection
log_step "STEP 3: Repository Setup"
if [ -n "$REPO_ARG" ]; then
    REPO_NAME="$REPO_ARG"
    log_info "Using repository from --repo flag: $REPO_NAME"
else
    # Try to get current repo
    CURRENT_REPO=$(gh repo view --json name -q ".name" 2>/dev/null)
    if [ $? -eq 0 ] && [ -n "$CURRENT_REPO" ]; then
        REPO_OWNER=$(gh repo view --json owner -q ".owner.login" 2>/dev/null)
        REPO_NAME="${REPO_OWNER}/${CURRENT_REPO}"
        log_success "Found current repository: $REPO_NAME"
    else
        log_warning "No current repository found"
        echo
        echo -e "${BOLD}Please enter repository name (format: owner/repo-name):${NC}"
        echo -e "${CYAN}Example: $GITHUB_USERNAME/claude-code-login${NC}"
        REPO_NAME=$(read_from_tty "Repository: ")
        
        if [ -z "$REPO_NAME" ]; then
            log_error "Repository name cannot be empty"
            exit 1
        fi
        
        # Validate repository format
        if [[ ! "$REPO_NAME" =~ ^[^/]+/[^/]+$ ]]; then
            log_error "Invalid repository format. Use: owner/repo-name"
            exit 1
        fi
    fi
fi

# Verify repository exists
log_info "Verifying repository access: $REPO_NAME"
if ! gh repo view "$REPO_NAME" &>/dev/null; then
    log_error "Cannot access repository: $REPO_NAME"
    echo
    log_info "Please ensure:"
    echo "  • The repository exists"
    echo "  • You have access to the repository"
    echo "  • You're authenticated with the correct GitHub account"
    exit 1
fi
log_success "Repository verified: $REPO_NAME"

# Step 4: Check for existing secret
log_step "STEP 4: Checking Repository Secrets"
SECRET_EXISTS=false
if gh secret list --repo "$REPO_NAME" | grep -q "SECRETS_ADMIN_PAT"; then
    SECRET_EXISTS=true
    log_success "SECRETS_ADMIN_PAT already exists"
else
    log_warning "SECRETS_ADMIN_PAT not found"
    echo
    echo -e "${BOLD}You need to provide a Personal Access Token (PAT) for secrets management.${NC}"
    echo
    log_info "How to create a SECRETS_ADMIN_PAT:"
    echo "  • Visit: https://github.com/grll/claude-code-login?tab=readme-ov-file#prerequisites-setting-up-secrets_admin_pat"
    echo
    echo -e "${BOLD}Enter your SECRETS_ADMIN_PAT (input will be hidden):${NC}"
    PAT_TOKEN=$(read_secret_from_tty)
    echo
    
    if [ -z "$PAT_TOKEN" ]; then
        log_error "Personal Access Token cannot be empty"
        exit 1
    fi
    
    # Set the secret
    log_info "Setting SECRETS_ADMIN_PAT secret..."
    if echo "$PAT_TOKEN" | gh secret set SECRETS_ADMIN_PAT --repo "$REPO_NAME"; then
        log_success "SECRETS_ADMIN_PAT secret has been set"
    else
        log_error "Failed to set SECRETS_ADMIN_PAT secret"
        exit 1
    fi
fi

# Step 5: Git repository setup
log_step "STEP 5: Setting up Git Repository"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    log_info "Not in a git repository, initializing..."
    git init
    log_success "Git repository initialized"
fi

# Save current branch and any uncommitted changes
ORIGINAL_BRANCH=$(git branch --show-current)
if [ -z "$ORIGINAL_BRANCH" ]; then
    # If detached HEAD or no branch, get the commit SHA
    ORIGINAL_BRANCH=$(git rev-parse HEAD 2>/dev/null || echo "main")
    IS_DETACHED=true
else
    IS_DETACHED=false
fi
log_info "Current branch/commit: $ORIGINAL_BRANCH"

# Stash any existing changes (including untracked files)
log_info "Stashing existing changes..."
STASH_RESULT=$(git stash push -u -m "Pre-Claude-OAuth-setup stash" 2>&1)
if echo "$STASH_RESULT" | grep -q "No local changes to save"; then
    STASH_CREATED=false
    log_info "No existing changes to stash"
else
    STASH_CREATED=true
    log_success "Existing changes stashed"
fi

# Check if main branch exists locally
if git show-ref --verify --quiet refs/heads/main; then
    MAIN_BRANCH="main"
elif git show-ref --verify --quiet refs/heads/master; then
    MAIN_BRANCH="master"
else
    # Create main branch if it doesn't exist
    log_info "Creating main branch..."
    git checkout -b main
    MAIN_BRANCH="main"
    CREATED_MAIN=true
fi

# Switch to main branch
if [ "$ORIGINAL_BRANCH" != "$MAIN_BRANCH" ]; then
    log_info "Switching to $MAIN_BRANCH branch..."
    git checkout "$MAIN_BRANCH"
fi

# Step 6: Create workflows
log_step "STEP 6: Creating GitHub Workflows"
mkdir -p .github/workflows

# Create claude_code_login.yml
log_info "Creating claude_code_login.yml..."
cat > .github/workflows/claude_code_login.yml << 'EOF'
name: Claude OAuth

on:
  workflow_dispatch:
    inputs:
      code:
        description: 'Authorization code (leave empty for step 1)'
        required: false

permissions:
  actions: write  # Required for cache management
  contents: read  # Required for basic repository access

jobs:
  auth:
    runs-on: ubuntu-latest
    steps:
      - uses: grll/claude-code-login@v1
        with:
          code: ${{ inputs.code }}
          secrets_admin_pat: ${{ secrets.SECRETS_ADMIN_PAT }}
EOF

log_success "Created claude_code_login.yml"

# Create claude_code.yml with username replacement
log_info "Creating claude_code.yml..."
cat > .github/workflows/claude_code.yml << EOF
name: Claude PR Assistant - Authorized Users Only

on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
  issues:
    types: [opened, assigned]
  pull_request_review:
    types: [submitted]

jobs:
  claude-code-action:
    # Only respond to @claude mentions from $GITHUB_USERNAME
    if: |
      (
        (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
        (github.event_name == 'pull_request_review_comment' && contains(github.event.comment.body, '@claude')) ||
        (github.event_name == 'pull_request_review' && contains(github.event.review.body, '@claude')) ||
        (github.event_name == 'issues' && contains(github.event.issue.body, '@claude'))
      ) && github.actor == '$GITHUB_USERNAME'
    runs-on: ubuntu-latest
    permissions:
      contents: read
      pull-requests: read
      issues: read
      id-token: write
      actions: write
    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 1

      - name: Run Claude PR Action
        uses: grll/claude-code-action@beta
        with:
          use_oauth: true
          claude_access_token: \${{ secrets.CLAUDE_ACCESS_TOKEN }}
          claude_refresh_token: \${{ secrets.CLAUDE_REFRESH_TOKEN }}
          claude_expires_at: \${{ secrets.CLAUDE_EXPIRES_AT }}
          secrets_admin_pat: \${{ secrets.SECRETS_ADMIN_PAT }}
          timeout_minutes: "60"
EOF

log_success "Created claude_code.yml"

# Step 7: Commit and push workflows
log_step "STEP 7: Committing and Pushing Workflows"

# Add the workflow files
log_info "Adding workflow files to git..."
git add .github/workflows/claude_code_login.yml .github/workflows/claude_code.yml

# Check if there are changes to commit
if git diff --cached --quiet; then
    log_warning "No changes to commit (workflows may already exist)"
    COMMITTED=false
    USER_CONSENTED=true  # No need to ask since nothing to commit
else
    # Ask for user consent before committing
    echo
    echo -e "${BOLD}${YELLOW}⚠️  Permission Required${NC}"
    echo -e "${BOLD}The installer needs to commit and push workflow files to the $MAIN_BRANCH branch.${NC}"
    echo
    echo -e "${GREEN}✓ Recommended:${NC} Give consent for a smoother experience"
    echo -e "  • We'll automatically switch to $MAIN_BRANCH branch"
    echo -e "  • Commit the workflow files"
    echo -e "  • Push to remote repository"
    echo -e "  • ${BOLD}Return you to your current branch/state${NC}"
    echo
    echo -e "${YELLOW}✗ Without consent:${NC}"
    echo -e "  • You'll need to manually commit and push the workflows"
    echo -e "  • The setup instructions will include these manual steps"
    echo
    echo -e "${BOLD}Allow automatic commit and push to $MAIN_BRANCH? (y/N):${NC} "
    CONSENT=$(read_from_tty "")
    
    if [[ "$CONSENT" =~ ^[Yy]$ ]]; then
        USER_CONSENTED=true
        log_success "Consent granted. Proceeding with automatic commit and push."
        
        # Commit the changes
        log_info "Committing workflow files to $MAIN_BRANCH branch..."
        git commit -m "Add Claude Code OAuth workflows

- claude_code_login.yml: OAuth authentication workflow
- claude_code.yml: PR assistant workflow for @$GITHUB_USERNAME

🤖 Generated with Claude OAuth Installer

Co-authored-by: grll <noreply@github.com>"
        
        log_success "Workflows committed to $MAIN_BRANCH branch"
        COMMITTED=true
        
        # Push to remote
        log_info "Pushing to remote repository..."
        
        # Check if we have a remote
        if ! git remote | grep -q origin; then
            log_warning "No remote 'origin' found. You may need to set up a remote and push manually."
            log_info "To set up remote: git remote add origin https://github.com/$REPO_NAME.git"
            PUSHED=false
        else
            # Try to push main branch
            if git push origin "$MAIN_BRANCH"; then
                log_success "Workflows pushed to remote repository ($MAIN_BRANCH branch)"
                PUSHED=true
            else
                log_warning "Failed to push. You may need to push manually:"
                echo "  git push origin $MAIN_BRANCH"
                PUSHED=false
            fi
        fi
    else
        USER_CONSENTED=false
        COMMITTED=false
        PUSHED=false
        log_warning "Consent not granted. You'll need to manually commit and push the workflows."
        
        # Reset the staged files
        git reset HEAD .github/workflows/claude_code_login.yml .github/workflows/claude_code.yml
    fi
fi

# Return to original branch/commit
if [ "$ORIGINAL_BRANCH" != "$MAIN_BRANCH" ]; then
    log_info "Returning to original branch/commit: $ORIGINAL_BRANCH"
    if [ "$IS_DETACHED" = true ]; then
        git checkout "$ORIGINAL_BRANCH" 2>/dev/null || log_warning "Could not return to original commit"
    else
        git checkout "$ORIGINAL_BRANCH"
    fi
fi

# Pop stashed changes if we created a stash
if [ "$STASH_CREATED" = true ]; then
    log_info "Restoring stashed changes..."
    if git stash pop; then
        log_success "Stashed changes restored"
    else
        log_warning "Failed to restore stashed changes. Check 'git stash list'"
    fi
fi

# Step 8: Final instructions
log_step "SETUP COMPLETE! Next Steps:"
echo

# Show manual commit instructions if user didn't consent
if [ "$USER_CONSENTED" = false ]; then
    echo -e "${RED}${BOLD}⚠️  MANUAL ACTION REQUIRED ⚠️${NC}"
    echo -e "${BOLD}You chose not to automatically commit the workflows. Please run these commands:${NC}"
    echo
    echo -e "${CYAN}# 1. Switch to $MAIN_BRANCH branch${NC}"
    echo -e "   git checkout $MAIN_BRANCH"
    echo
    echo -e "${CYAN}# 2. Add and commit the workflow files${NC}"
    echo -e "   git add .github/workflows/claude_code_login.yml .github/workflows/claude_code.yml"
    echo -e "   git commit -m \"Add Claude Code OAuth workflows\""
    echo
    echo -e "${CYAN}# 3. Push to remote${NC}"
    echo -e "   git push origin $MAIN_BRANCH"
    echo
    echo -e "${CYAN}# 4. Return to your branch (optional)${NC}"
    echo -e "   git checkout $ORIGINAL_BRANCH"
    echo
    echo -e "${YELLOW}Complete these steps before continuing with the instructions below!${NC}"
    echo
fi

echo -e "${RED}${BOLD}⚠️  IMPORTANT: GitHub App Required ⚠️${NC}"
echo -e "${BOLD}For @claude to work, you MUST install the official Anthropic GitHub App:${NC}"
echo -e "   • Install here: ${CYAN}https://github.com/settings/installations/68058532${NC}"
echo -e "   • Grant access to: ${GREEN}$REPO_NAME${NC}"
echo -e "   • Without this app, @claude mentions will fail!"
echo
echo -e "${BOLD}1. Run the OAuth workflow (without code):${NC}"
echo -e "   • Go to: https://github.com/$REPO_NAME/actions/workflows/claude_code_login.yml"
echo -e "   • Click ${GREEN}'Run workflow'${NC} → ${GREEN}'Run workflow'${NC} (leave code empty)"
echo
echo -e "${BOLD}2. Get the login URL:${NC}"
echo -e "   • Wait for the workflow to complete"
echo -e "   • Click on the workflow run"
echo -e "   • Look for the login URL in the action summary"
echo
echo -e "${BOLD}3. Authenticate with Claude:${NC}"
echo -e "   • Visit the generated URL"
echo -e "   • Log in to Claude"
echo -e "   • Copy the authorization code"
echo
echo -e "${BOLD}4. Complete setup:${NC}"
echo -e "   • Run the workflow again with the authorization code"
echo -e "   • Go to: https://github.com/$REPO_NAME/actions/workflows/claude_code_login.yml"
echo -e "   • Click ${GREEN}'Run workflow'${NC} → paste your code → ${GREEN}'Run workflow'${NC}"
echo
echo -e "${BOLD}5. Start using Claude:${NC}"
echo -e "   • Create issues or PRs and mention ${CYAN}@claude${NC}"
echo -e "   • Only ${GREEN}$GITHUB_USERNAME${NC} can trigger Claude responses"
echo -e "   • Customize your workflow in ${CYAN}claude_code.yml${NC}"
echo
log_success "Installation complete! 🎉"
echo
echo -e "${CYAN}For more information and troubleshooting:${NC}"
echo -e "https://github.com/grll/claude-code-login"
echo -e "https://github.com/grll/claude-code-action"