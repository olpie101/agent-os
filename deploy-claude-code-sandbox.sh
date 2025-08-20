#!/bin/bash
# Claude Code Sandbox Deployment Script
# Packages and installs the sandbox launcher and profile
# Version: 1.2.0

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation directory
INSTALL_DIR="${INSTALL_DIR:-$HOME/.claude-code-sandbox}"
BIN_DIR="${BIN_DIR:-$HOME/.local/bin}"

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check for sandbox-exec (macOS only)
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if ! command -v sandbox-exec &> /dev/null; then
            print_error "sandbox-exec not found. This tool requires macOS."
            exit 1
        fi
    else
        print_warning "This tool is designed for macOS. Installation continuing but may not work on other platforms."
    fi
    
    # Check for required commands
    local required_commands=("cp" "chmod" "ln" "mkdir")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            print_error "Required command '$cmd' not found."
            exit 1
        fi
    done
    
    print_success "Prerequisites check passed."
}

# Function to create installation directories
create_directories() {
    print_info "Creating installation directories..."
    
    # Create main installation directory
    if [[ ! -d "$INSTALL_DIR" ]]; then
        mkdir -p "$INSTALL_DIR"
        print_success "Created directory: $INSTALL_DIR"
    else
        print_info "Directory already exists: $INSTALL_DIR"
    fi
    
    # Create bin directory if it doesn't exist
    if [[ ! -d "$BIN_DIR" ]]; then
        mkdir -p "$BIN_DIR"
        print_success "Created directory: $BIN_DIR"
    else
        print_info "Directory already exists: $BIN_DIR"
    fi
    
    # Create docs directory
    mkdir -p "$INSTALL_DIR/docs"
    
    # Create examples directory
    mkdir -p "$INSTALL_DIR/examples"
}

# Function to copy files
install_files() {
    print_info "Installing sandbox files..."
    
    # Copy launcher script
    if [[ -f "claude-code-sandbox-launcher.sh" ]]; then
        cp claude-code-sandbox-launcher.sh "$INSTALL_DIR/"
        chmod +x "$INSTALL_DIR/claude-code-sandbox-launcher.sh"
        print_success "Installed launcher script"
    else
        print_error "Launcher script not found: claude-code-sandbox-launcher.sh"
        exit 1
    fi
    
    # Copy sandbox profile
    if [[ -f "extensions/sandbox/profiles/claude-code-sandbox.sb" ]]; then
        cp extensions/sandbox/profiles/claude-code-sandbox.sb "$INSTALL_DIR/"
        print_success "Installed sandbox profile"
    else
        print_error "Sandbox profile not found: claude-code-sandbox.sb"
        exit 1
    fi
    
    # Copy documentation if available
    if [[ -d "docs" ]]; then
        cp -r docs/* "$INSTALL_DIR/docs/" 2>/dev/null || true
        print_success "Installed documentation"
    fi
    
    # Copy test files if available
    if [[ -d "tests" ]]; then
        cp -r tests "$INSTALL_DIR/" 2>/dev/null || true
        print_success "Installed test files"
    fi
    
    # Create README in install directory
    cat > "$INSTALL_DIR/README.md" << 'EOF'
# Claude Code Sandbox

## Version
1.2.0 - Full implementation with security boundaries

## Installation Location
This sandbox has been installed to this directory.

## Quick Start

Run Claude Code with the sandbox:
```bash
claude-code-sandbox claude-code
```

Or with custom settings:
```bash
DEV_WORKSPACE="/path/to/projects" claude-code-sandbox claude-code
```

## Documentation

See the `docs/` directory for:
- Usage guide
- Parameter reference
- Security boundaries
- Troubleshooting guide
- Examples

## Configuration

Set these environment variables in your shell profile:
```bash
export DEV_WORKSPACE="$HOME/dev"
export AGENT_OS_DIR="$HOME/.agent-os"
```

## Support

For issues or questions, see the troubleshooting guide in `docs/`.
EOF
    
    print_success "Created README.md"
}

# Function to create symlink
create_symlink() {
    print_info "Creating command symlink..."
    
    local link_path="$BIN_DIR/claude-code-sandbox"
    local target_path="$INSTALL_DIR/claude-code-sandbox-launcher.sh"
    
    # Remove existing symlink if it exists
    if [[ -L "$link_path" ]]; then
        rm "$link_path"
        print_info "Removed existing symlink"
    elif [[ -f "$link_path" ]]; then
        print_warning "File exists at $link_path (not a symlink). Please remove it manually."
        return 1
    fi
    
    # Create new symlink
    ln -s "$target_path" "$link_path"
    chmod +x "$link_path"
    print_success "Created symlink: $link_path -> $target_path"
    
    # Check if BIN_DIR is in PATH
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_warning "$BIN_DIR is not in your PATH."
        print_info "Add this line to your shell profile (.bashrc, .zshrc, etc.):"
        echo "    export PATH=\"$BIN_DIR:\$PATH\""
    fi
}

# Function to create example configuration
create_examples() {
    print_info "Creating example configurations..."
    
    # Basic example
    cat > "$INSTALL_DIR/examples/basic-setup.sh" << 'EOF'
#!/bin/bash
# Basic Claude Code Sandbox Setup

# Set workspace to your development directory
export DEV_WORKSPACE="$HOME/dev"

# Run Claude Code
claude-code-sandbox claude-code
EOF
    chmod +x "$INSTALL_DIR/examples/basic-setup.sh"
    
    # Advanced example
    cat > "$INSTALL_DIR/examples/advanced-setup.sh" << 'EOF'
#!/bin/bash
# Advanced Claude Code Sandbox Setup

# Configure all parameters
export DEV_WORKSPACE="$HOME/projects"
export WORKING_DIR="$(pwd)"
export AGENT_OS_DIR="$HOME/.agent-os"
export NATS_URL="nats://localhost:4222"
export SANDBOX_VERBOSE="true"

# Run with verbose output
claude-code-sandbox --verbose claude-code
EOF
    chmod +x "$INSTALL_DIR/examples/advanced-setup.sh"
    
    print_success "Created example configurations"
}

# Function to verify installation
verify_installation() {
    print_info "Verifying installation..."
    
    local errors=0
    
    # Check launcher script
    if [[ ! -f "$INSTALL_DIR/claude-code-sandbox-launcher.sh" ]]; then
        print_error "Launcher script not found"
        ((errors++))
    fi
    
    # Check sandbox profile
    if [[ ! -f "$INSTALL_DIR/claude-code-sandbox.sb" ]]; then
        print_error "Sandbox profile not found"
        ((errors++))
    fi
    
    # Check symlink
    if [[ ! -L "$BIN_DIR/claude-code-sandbox" ]]; then
        print_warning "Symlink not created"
    fi
    
    # Test sandbox execution (dry run)
    if command -v sandbox-exec &> /dev/null; then
        if ! "$INSTALL_DIR/claude-code-sandbox-launcher.sh" --dry-run echo "test" &> /dev/null; then
            print_warning "Sandbox dry run test failed (may be normal if environment not configured)"
        fi
    fi
    
    if [[ $errors -eq 0 ]]; then
        print_success "Installation verified successfully"
        return 0
    else
        print_error "Installation verification failed with $errors errors"
        return 1
    fi
}

# Function to print post-installation instructions
print_instructions() {
    echo ""
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${GREEN}    Claude Code Sandbox Installation Complete!${NC}"
    echo -e "${GREEN}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "Installation directory: $INSTALL_DIR"
    echo "Command location: $BIN_DIR/claude-code-sandbox"
    echo ""
    echo "Next steps:"
    echo "1. Add to your shell profile (.bashrc, .zshrc, etc.):"
    echo ""
    echo "   export PATH=\"$BIN_DIR:\$PATH\""
    echo "   export DEV_WORKSPACE=\"\$HOME/dev\""
    echo ""
    echo "2. Reload your shell configuration:"
    echo "   source ~/.zshrc  # or ~/.bashrc"
    echo ""
    echo "3. Test the installation:"
    echo "   claude-code-sandbox --help"
    echo ""
    echo "4. Run Claude Code with sandbox:"
    echo "   claude-code-sandbox claude-code"
    echo ""
    echo "Documentation available at: $INSTALL_DIR/docs/"
    echo ""
}

# Function to uninstall (for completeness)
uninstall() {
    print_warning "Uninstalling Claude Code Sandbox..."
    
    # Remove symlink
    if [[ -L "$BIN_DIR/claude-code-sandbox" ]]; then
        rm "$BIN_DIR/claude-code-sandbox"
        print_success "Removed symlink"
    fi
    
    # Remove installation directory
    if [[ -d "$INSTALL_DIR" ]]; then
        rm -rf "$INSTALL_DIR"
        print_success "Removed installation directory"
    fi
    
    print_success "Uninstallation complete"
}

# Main installation flow
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║         Claude Code Sandbox Deployment Script v1.2.0          ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    # Parse command line arguments
    case "${1:-}" in
        --uninstall)
            uninstall
            exit 0
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --help       Show this help message"
            echo "  --uninstall  Remove Claude Code Sandbox"
            echo ""
            echo "Environment variables:"
            echo "  INSTALL_DIR  Installation directory (default: ~/.claude-code-sandbox)"
            echo "  BIN_DIR      Binary directory (default: ~/.local/bin)"
            exit 0
            ;;
    esac
    
    # Run installation steps
    check_prerequisites
    create_directories
    install_files
    create_symlink
    create_examples
    verify_installation
    
    # Print completion message
    print_instructions
}

# Run main function
main "$@"
