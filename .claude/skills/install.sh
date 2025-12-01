#!/bin/bash
# Skills Installation Script for Linux/macOS
# Installs all dependencies for Claude Code skills

set -e

# Parse command line arguments
SKIP_CONFIRM=false
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -y|--yes) SKIP_CONFIRM=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Check for NON_INTERACTIVE environment variable
if [[ -n "${NON_INTERACTIVE}" ]]; then
    SKIP_CONFIRM=true
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"

# Detect OS
detect_os() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        echo "linux"
    else
        echo "unknown"
    fi
}

OS=$(detect_os)

# Print functions
print_header() {
    echo -e "\n${BLUE}===================================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}===================================================${NC}\n"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and install system package manager
check_package_manager() {
    if [[ "$OS" == "macos" ]]; then
        if ! command_exists brew; then
            print_warning "Homebrew not found. Installing Homebrew..."
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
            print_success "Homebrew installed"
        else
            print_success "Homebrew found"
        fi
    elif [[ "$OS" == "linux" ]]; then
        if command_exists apt-get; then
            print_success "apt-get found"
        elif command_exists yum; then
            print_success "yum found"
        else
            print_error "No supported package manager found (apt-get or yum)"
            exit 1
        fi
    fi
}

# Install system dependencies
install_system_deps() {
    print_header "Installing System Dependencies"

    # FFmpeg
    if command_exists ffmpeg; then
        print_success "FFmpeg already installed ($(ffmpeg -version 2>&1 | head -n1))"
    else
        print_info "Installing FFmpeg..."
        if [[ "$OS" == "macos" ]]; then
            brew install ffmpeg
        elif [[ "$OS" == "linux" ]]; then
            sudo apt-get update && sudo apt-get install -y ffmpeg
        fi
        print_success "FFmpeg installed"
    fi

    # ImageMagick
    if command_exists magick || command_exists convert; then
        print_success "ImageMagick already installed"
    else
        print_info "Installing ImageMagick..."
        if [[ "$OS" == "macos" ]]; then
            brew install imagemagick
        elif [[ "$OS" == "linux" ]]; then
            sudo apt-get install -y imagemagick
        fi
        print_success "ImageMagick installed"
    fi

    # PostgreSQL client (optional)
    if command_exists psql; then
        print_success "PostgreSQL client already installed"
    else
        print_warning "PostgreSQL client not found. Skipping (optional)..."
    fi

    # Docker (optional)
    if command_exists docker; then
        print_success "Docker already installed ($(docker --version))"
    else
        print_warning "Docker not found. Skipping (optional)..."
        print_info "Install Docker from: https://docs.docker.com/get-docker/"
    fi
}

# Install Node.js and npm packages
install_node_deps() {
    print_header "Installing Node.js Dependencies"

    # Check Node.js
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js already installed ($NODE_VERSION)"
    else
        print_info "Installing Node.js..."
        if [[ "$OS" == "macos" ]]; then
            brew install node
        elif [[ "$OS" == "linux" ]]; then
            curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
            sudo apt-get install -y nodejs
        fi
        print_success "Node.js installed"
    fi

    # Install global npm packages
    print_info "Installing global npm packages..."

    # Package name to CLI command mapping (some packages have different CLI names)
    declare -A npm_packages=(
        ["rmbg-cli"]="rmbg"
        ["pnpm"]="pnpm"
        ["wrangler"]="wrangler"
        ["repomix"]="repomix"
    )

    for package in "${!npm_packages[@]}"; do
        cmd="${npm_packages[$package]}"

        # Check CLI command first (handles standalone installs like brew, curl, etc.)
        if command_exists "$cmd"; then
            version=$("$cmd" --version 2>&1 | head -n1 || echo "available")
            print_success "$package already installed ($version)"
        # Fallback: check if installed via npm registry
        elif npm list -g "$package" >/dev/null 2>&1; then
            print_success "$package already installed via npm"
        else
            print_info "Installing $package..."
            npm install -g "$package" 2>/dev/null || {
                print_warning "Failed to install $package globally. Trying with sudo..."
                sudo npm install -g "$package"
            }
            print_success "$package installed"
        fi
    done

    # Install local npm packages for skills
    print_info "Installing local npm packages for skills..."

    # chrome-devtools
    if [ -d "$SCRIPT_DIR/chrome-devtools/scripts" ] && [ -f "$SCRIPT_DIR/chrome-devtools/scripts/package.json" ]; then
        print_info "Installing chrome-devtools dependencies..."
        (cd "$SCRIPT_DIR/chrome-devtools/scripts" && npm install --quiet)
        print_success "chrome-devtools dependencies installed"
    fi

    # sequential-thinking
    if [ -d "$SCRIPT_DIR/sequential-thinking" ] && [ -f "$SCRIPT_DIR/sequential-thinking/package.json" ]; then
        print_info "Installing sequential-thinking dependencies..."
        (cd "$SCRIPT_DIR/sequential-thinking" && npm install --quiet)
        print_success "sequential-thinking dependencies installed"
    fi

    # mcp-management
    if [ -d "$SCRIPT_DIR/mcp-management/scripts" ] && [ -f "$SCRIPT_DIR/mcp-management/scripts/package.json" ]; then
        print_info "Installing mcp-management dependencies..."
        (cd "$SCRIPT_DIR/mcp-management/scripts" && npm install --quiet)
        print_success "mcp-management dependencies installed"
    fi

    # Optional: Shopify CLI (ask user unless auto-confirming)
    if [ -d "$SCRIPT_DIR/shopify" ]; then
        if [[ "$SKIP_CONFIRM" == "true" ]]; then
            print_info "Skipping Shopify CLI installation (optional, use --yes to install all)"
        else
            read -p "Install Shopify CLI for Shopify skill? (y/N) " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_info "Installing Shopify CLI..."
                npm install -g @shopify/cli @shopify/theme 2>/dev/null || {
                    print_warning "Failed to install Shopify CLI globally. Trying with sudo..."
                    sudo npm install -g @shopify/cli @shopify/theme
                }
                print_success "Shopify CLI installed"
            fi
        fi
    fi
}

# Setup Python virtual environment
setup_python_env() {
    print_header "Setting Up Python Environment"

    # Check Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version)
        print_success "Python3 found ($PYTHON_VERSION)"
    else
        print_error "Python3 not found. Please install Python 3.7+"
        exit 1
    fi

    # Create virtual environment
    if [ -d "$VENV_DIR" ]; then
        print_success "Virtual environment already exists at $VENV_DIR"
    else
        print_info "Creating virtual environment at $VENV_DIR..."
        python3 -m venv "$VENV_DIR"
        print_success "Virtual environment created"
    fi

    # Activate and install packages
    print_info "Activating virtual environment..."
    source "$VENV_DIR/bin/activate"

    # Upgrade pip
    print_info "Upgrading pip..."
    pip install --upgrade pip >/dev/null 2>&1

    # Install dependencies from all skills' requirements.txt files
    print_info "Installing Python dependencies from all skills..."

    local installed_count=0
    for skill_dir in "$SCRIPT_DIR"/*; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")

            # Skip .venv and document-skills
            if [ "$skill_name" == ".venv" ] || [ "$skill_name" == "document-skills" ]; then
                continue
            fi

            # Install main requirements.txt
            if [ -f "$skill_dir/scripts/requirements.txt" ]; then
                print_info "Installing $skill_name dependencies..."
                pip install -r "$skill_dir/scripts/requirements.txt" --quiet 2>&1 || {
                    print_warning "Some $skill_name dependencies failed to install (may be optional)"
                }
                ((installed_count++))
            fi

            # Install test requirements.txt
            if [ -f "$skill_dir/scripts/tests/requirements.txt" ]; then
                pip install -r "$skill_dir/scripts/tests/requirements.txt" --quiet 2>&1 || {
                    print_warning "Some $skill_name test dependencies failed to install (may be optional)"
                }
            fi
        fi
    done

    if [ $installed_count -eq 0 ]; then
        print_warning "No skill requirements.txt files found"
    else
        print_success "Installed Python dependencies from $installed_count skills"
    fi

    deactivate
}

# Verify installations
verify_installations() {
    print_header "Verifying Installations"

    declare -a system_tools=(
        "ffmpeg:FFmpeg"
        "magick:ImageMagick"
        "node:Node.js"
        "npm:npm"
    )

    for tool_pair in "${system_tools[@]}"; do
        IFS=':' read -r cmd name <<< "$tool_pair"
        if command_exists "$cmd"; then
            print_success "$name is available"
        else
            print_warning "$name is not available"
        fi
    done

    declare -a npm_packages=(
        "rmbg"
        "pnpm"
        "wrangler"
        "repomix"
    )

    for package in "${npm_packages[@]}"; do
        if command_exists "$package"; then
            print_success "$package CLI is available"
        else
            print_warning "$package CLI is not available"
        fi
    done

    # Check Python packages
    if [ -d "$VENV_DIR" ]; then
        source "$VENV_DIR/bin/activate"
        if python -c "import google.genai" 2>/dev/null; then
            print_success "google-genai Python package is available"
        else
            print_warning "google-genai Python package is not available"
        fi
        deactivate
    fi
}

# Print usage instructions
print_usage() {
    print_header "Installation Complete!"

    echo -e "${GREEN}To use the Python virtual environment:${NC}"
    echo -e "  source .claude/skills/.venv/bin/activate"
    echo ""
    echo -e "${GREEN}To verify installations:${NC}"
    echo -e "  ffmpeg -version"
    echo -e "  magick -version"
    echo -e "  rmbg --version"
    echo -e "  node --version"
    echo ""
    echo -e "${GREEN}To run tests:${NC}"
    echo -e "  source .claude/skills/.venv/bin/activate"
    echo -e "  cd .claude/skills/<skill-name>/scripts"
    echo -e "  pytest tests/ -v"
    echo ""
    echo -e "${GREEN}Environment variables:${NC}"
    echo -e "  Create .claude/skills/.env for shared config"
    echo -e "  Create .claude/skills/<skill-name>/.env for skill-specific config"
    echo ""
    echo -e "${BLUE}For more information, see:${NC}"
    echo -e "  .claude/skills/INSTALLATION.md"
    echo ""
}

# Main installation flow
main() {
    clear
    print_header "Claude Code Skills Installation"
    print_info "OS: $OS"
    print_info "Script directory: $SCRIPT_DIR"
    echo ""

    if [[ "$OS" == "unknown" ]]; then
        print_error "Unsupported operating system"
        exit 1
    fi

    # Confirm installation (skip if --yes flag or NON_INTERACTIVE env is set)
    if [[ "$SKIP_CONFIRM" == "false" ]]; then
        read -p "This will install system packages and Node.js dependencies. Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_warning "Installation cancelled"
            exit 0
        fi
    else
        print_info "Auto-confirming installation (--yes flag or NON_INTERACTIVE mode)"
    fi

    check_package_manager
    install_system_deps
    install_node_deps
    setup_python_env
    verify_installations
    print_usage
}

# Run main function
main
