# Skills Installation Script for Windows (PowerShell)
# Installs all dependencies for Claude Code skills

param(
    [switch]$SkipChocolatey = $false,
    [switch]$Help = $false,
    [switch]$Y = $false  # Skip all prompts and auto-confirm
)

# Configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$VenvDir = Join-Path $ScriptDir ".venv"

# Check for NON_INTERACTIVE environment variable
if ($env:NON_INTERACTIVE -eq "1") {
    $Y = $true
}

# Colors for output
function Write-Header {
    param([string]$Message)
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Blue
    Write-Host $Message -ForegroundColor Blue
    Write-Host "===================================================" -ForegroundColor Blue
    Write-Host ""
}

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

# Check if running as Administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Check if command exists
function Test-Command {
    param([string]$Command)
    try {
        if (Get-Command $Command -ErrorAction SilentlyContinue) {
            return $true
        }
    } catch {
        return $false
    }
    return $false
}

# Get available package manager (priority: winget > scoop > choco)
function Get-PackageManager {
    if (Test-Command "winget") { return "winget" }
    if (Test-Command "scoop") { return "scoop" }
    if (Test-Command "choco") { return "choco" }
    return $null
}

# Install package using available package manager
# Returns $true if installed, $false if failed
function Install-WithPackageManager {
    param(
        [string]$DisplayName,
        [string]$WingetId,
        [string]$ChocoName,
        [string]$ScoopName,
        [string]$ManualUrl
    )

    $pm = Get-PackageManager

    switch ($pm) {
        "winget" {
            Write-Info "Installing $DisplayName via winget..."
            # Try user scope first, fallback to machine scope
            winget install $WingetId --silent --accept-package-agreements --accept-source-agreements --scope user 2>$null
            if ($LASTEXITCODE -ne 0) {
                # Retry without scope restriction (some packages only support machine-wide)
                winget install $WingetId --silent --accept-package-agreements --accept-source-agreements 2>$null
            }
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$DisplayName installed via winget"
                return $true
            }
        }
        "scoop" {
            Write-Info "Installing $DisplayName via scoop..."
            scoop install $ScoopName 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$DisplayName installed via scoop"
                return $true
            }
        }
        "choco" {
            if (Test-Administrator) {
                Write-Info "Installing $DisplayName via chocolatey..."
                choco install $ChocoName -y 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Success "$DisplayName installed via chocolatey"
                    return $true
                }
            } else {
                Write-Warning "Chocolatey requires admin. Skipping $DisplayName..."
            }
        }
    }

    Write-Warning "$DisplayName not installed. Install manually from: $ManualUrl"
    return $false
}

# Get user input with support for redirected stdin
function Get-UserInput {
    param(
        [string]$Prompt,
        [string]$Default = "N"
    )

    # Check if stdin is redirected (e.g., from Bash tool or piped input)
    if ([Console]::IsInputRedirected) {
        Write-Host "$Prompt " -NoNewline

        # Try to read from stdin without blocking
        $inputAvailable = $false
        try {
            $stdin = [Console]::In
            # Peek returns -1 if no data available
            if ($stdin.Peek() -ne -1) {
                $response = $stdin.ReadLine()
                $inputAvailable = $true
                Write-Host $response
            }
        } catch {
            # If peek fails, no input available
        }

        if ($inputAvailable -and $response) {
            return $response
        } else {
            # No input available, use default
            Write-Host $Default
            Write-Warning "No input detected (stdin redirected), using default: $Default"
            return $Default
        }
    } else {
        # Normal interactive mode - use standard Read-Host
        return Read-Host $Prompt
    }
}

# Install Chocolatey (optional - only if admin and no better PM available)
function Install-Chocolatey {
    if ($SkipChocolatey) {
        Write-Warning "Skipping Chocolatey installation (--SkipChocolatey flag)"
        return $false
    }

    if (Test-Command "choco") {
        Write-Success "Chocolatey already installed"
        return $true
    }

    # Check if we have winget/scoop - no need for choco then
    if ((Test-Command "winget") -or (Test-Command "scoop")) {
        $pm = Get-PackageManager
        Write-Info "Using $pm as package manager (Chocolatey not needed)"
        return $false
    }

    # Only try to install choco if we're admin and have no other PM
    if (-not (Test-Administrator)) {
        Write-Warning "No package manager found. Options:"
        Write-Info "  1. Run as Administrator to install Chocolatey"
        Write-Info "  2. Install winget (recommended): https://aka.ms/getwinget"
        Write-Info "  3. Install scoop: irm get.scoop.sh | iex"
        return $false
    }

    Write-Info "Installing Chocolatey package manager..."

    # Wrap Set-ExecutionPolicy in try-catch (may fail in some PS7 environments)
    try {
        Set-ExecutionPolicy Bypass -Scope Process -Force
    } catch {
        Write-Warning "Could not set execution policy: $($_.Exception.Message)"
        Write-Info "Continuing anyway - Chocolatey install may prompt for confirmation"
    }

    try {
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Success "Chocolatey installed"
        return $true
    } catch {
        Write-Warning "Failed to install Chocolatey: $($_.Exception.Message)"
        return $false
    }
}

# Install system dependencies
function Install-SystemDeps {
    Write-Header "Installing System Dependencies"

    $pm = Get-PackageManager
    if ($pm) {
        Write-Info "Using package manager: $pm"
    } else {
        Write-Warning "No package manager found. Will provide manual install instructions."
    }

    # FFmpeg
    if (Test-Command "ffmpeg") {
        $ffmpegVersion = (ffmpeg -version 2>&1 | Select-Object -First 1)
        Write-Success "FFmpeg already installed ($ffmpegVersion)"
    } else {
        $null = Install-WithPackageManager `
            -DisplayName "FFmpeg" `
            -WingetId "Gyan.FFmpeg" `
            -ChocoName "ffmpeg" `
            -ScoopName "ffmpeg" `
            -ManualUrl "https://ffmpeg.org/download.html"
    }

    # ImageMagick
    if (Test-Command "magick") {
        Write-Success "ImageMagick already installed"
    } else {
        $null = Install-WithPackageManager `
            -DisplayName "ImageMagick" `
            -WingetId "ImageMagick.ImageMagick" `
            -ChocoName "imagemagick" `
            -ScoopName "imagemagick" `
            -ManualUrl "https://imagemagick.org/script/download.php"
    }

    # Docker (optional)
    if (Test-Command "docker") {
        $dockerVersion = (docker --version)
        Write-Success "Docker already installed ($dockerVersion)"
    } else {
        Write-Warning "Docker not found. Skipping (optional)..."
        Write-Info "Install Docker from: https://docs.docker.com/desktop/install/windows-install/"
    }
}

# Install Node.js and npm packages
function Install-NodeDeps {
    Write-Header "Installing Node.js Dependencies"

    # Check Node.js
    if (Test-Command "node") {
        $nodeVersion = (node --version)
        Write-Success "Node.js already installed ($nodeVersion)"
    } else {
        $installed = Install-WithPackageManager `
            -DisplayName "Node.js" `
            -WingetId "OpenJS.NodeJS.LTS" `
            -ChocoName "nodejs-lts" `
            -ScoopName "nodejs-lts" `
            -ManualUrl "https://nodejs.org/"

        if (-not $installed) {
            Write-Error "Node.js is required but could not be installed"
            Write-Info "Please install Node.js manually and re-run this script"
            exit 1
        }

        # Refresh PATH after Node.js install
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
    }

    # Install global npm packages
    Write-Info "Installing global npm packages..."

    $npmPackages = @(
        "rmbg-cli",
        "pnpm",
        "wrangler",
        "repomix"
    )

    foreach ($package in $npmPackages) {
        try {
            $installed = npm list -g $package 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Success "$package already installed"
            } else {
                Write-Info "Installing $package..."
                npm install -g $package
                Write-Success "$package installed"
            }
        } catch {
            Write-Info "Installing $package..."
            npm install -g $package
            Write-Success "$package installed"
        }
    }

    # Install local npm packages for skills
    Write-Info "Installing local npm packages for skills..."

    # chrome-devtools
    $chromeDevToolsPath = Join-Path $ScriptDir "chrome-devtools\scripts"
    $chromePackageJson = Join-Path $chromeDevToolsPath "package.json"
    if ((Test-Path $chromeDevToolsPath) -and (Test-Path $chromePackageJson)) {
        Write-Info "Installing chrome-devtools dependencies..."
        Push-Location $chromeDevToolsPath
        npm install --quiet
        Pop-Location
        Write-Success "chrome-devtools dependencies installed"
    }

    # sequential-thinking
    $seqThinkingPath = Join-Path $ScriptDir "sequential-thinking"
    $seqPackageJson = Join-Path $seqThinkingPath "package.json"
    if ((Test-Path $seqThinkingPath) -and (Test-Path $seqPackageJson)) {
        Write-Info "Installing sequential-thinking dependencies..."
        Push-Location $seqThinkingPath
        npm install --quiet
        Pop-Location
        Write-Success "sequential-thinking dependencies installed"
    }

    # mcp-management
    $mcpManagementPath = Join-Path $ScriptDir "mcp-management\scripts"
    $mcpPackageJson = Join-Path $mcpManagementPath "package.json"
    if ((Test-Path $mcpManagementPath) -and (Test-Path $mcpPackageJson)) {
        Write-Info "Installing mcp-management dependencies..."
        Push-Location $mcpManagementPath
        npm install --quiet
        Pop-Location
        Write-Success "mcp-management dependencies installed"
    }

    # Optional: Shopify CLI (ask user unless auto-confirming)
    $shopifyPath = Join-Path $ScriptDir "shopify"
    if (Test-Path $shopifyPath) {
        if ($Y) {
            Write-Info "Skipping Shopify CLI installation (optional, use -Y to install all)"
        } else {
            $confirmation = Get-UserInput -Prompt "Install Shopify CLI for Shopify skill? (y/N)" -Default "N"
            if ($confirmation -eq 'y' -or $confirmation -eq 'Y') {
                Write-Info "Installing Shopify CLI..."
                npm install -g @shopify/cli @shopify/theme
                Write-Success "Shopify CLI installed"
            }
        }
    }
}

# Setup Python virtual environment
function Setup-PythonEnv {
    Write-Header "Setting Up Python Environment"

    # Check Python
    if (Test-Command "python") {
        $pythonVersion = (python --version)
        Write-Success "Python found ($pythonVersion)"
    } else {
        Write-Error "Python not found. Please install Python 3.7+ from: https://www.python.org/downloads/"
        Write-Info "Make sure to check 'Add Python to PATH' during installation"
        exit 1
    }

    # Create virtual environment
    if (Test-Path $VenvDir) {
        Write-Success "Virtual environment already exists at $VenvDir"
    } else {
        Write-Info "Creating virtual environment at $VenvDir..."
        python -m venv $VenvDir
        Write-Success "Virtual environment created"
    }

    # Activate and install packages
    Write-Info "Activating virtual environment..."
    $activateScript = Join-Path $VenvDir "Scripts\Activate.ps1"

    if (Test-Path $activateScript) {
        & $activateScript
    } else {
        Write-Error "Failed to find activation script at $activateScript"
        exit 1
    }

    # Upgrade pip
    Write-Info "Upgrading pip..."
    python -m pip install --upgrade pip --quiet

    # Install dependencies from all skills' requirements.txt files
    Write-Info "Installing Python dependencies from all skills..."

    $installedCount = 0
    Get-ChildItem -Path $ScriptDir -Directory | ForEach-Object {
        $skillName = $_.Name

        # Skip .venv and document-skills
        if ($skillName -eq ".venv" -or $skillName -eq "document-skills") {
            return
        }

        # Install main requirements.txt
        $requirementsPath = Join-Path $_.FullName "scripts\requirements.txt"
        if (Test-Path $requirementsPath) {
            Write-Info "Installing $skillName dependencies..."
            try {
                pip install -r $requirementsPath --quiet 2>$null
                $installedCount++
            } catch {
                Write-Warning "Some $skillName dependencies failed to install (may be optional)"
            }
        }

        # Install test requirements.txt
        $testRequirementsPath = Join-Path $_.FullName "scripts\tests\requirements.txt"
        if (Test-Path $testRequirementsPath) {
            try {
                pip install -r $testRequirementsPath --quiet 2>$null
            } catch {
                Write-Warning "Some $skillName test dependencies failed to install (may be optional)"
            }
        }
    }

    if ($installedCount -eq 0) {
        Write-Warning "No skill requirements.txt files found"
    } else {
        Write-Success "Installed Python dependencies from $installedCount skills"
    }

    deactivate
}

# Verify installations
function Test-Installations {
    Write-Header "Verifying Installations"

    $tools = @{
        "ffmpeg" = "FFmpeg"
        "magick" = "ImageMagick"
        "node" = "Node.js"
        "npm" = "npm"
    }

    foreach ($tool in $tools.GetEnumerator()) {
        if (Test-Command $tool.Key) {
            Write-Success "$($tool.Value) is available"
        } else {
            Write-Warning "$($tool.Value) is not available"
        }
    }

    $npmPackages = @("rmbg", "pnpm", "wrangler", "repomix")
    foreach ($package in $npmPackages) {
        if (Test-Command $package) {
            Write-Success "$package CLI is available"
        } else {
            Write-Warning "$package CLI is not available"
        }
    }

    # Check Python packages
    if (Test-Path $VenvDir) {
        $activateScript = Join-Path $VenvDir "Scripts\Activate.ps1"
        & $activateScript

        try {
            python -c "import google.genai" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Success "google-genai Python package is available"
            } else {
                Write-Warning "google-genai Python package is not available"
            }
        } catch {
            Write-Warning "google-genai Python package is not available"
        }

        deactivate
    }
}

# Print usage instructions
function Show-Usage {
    Write-Header "Installation Complete!"

    Write-Host "To use the Python virtual environment:" -ForegroundColor Green
    Write-Host "  .\.claude\skills\.venv\Scripts\Activate.ps1"
    Write-Host ""
    Write-Host "To verify installations:" -ForegroundColor Green
    Write-Host "  ffmpeg -version"
    Write-Host "  magick -version"
    Write-Host "  rmbg --version"
    Write-Host "  node --version"
    Write-Host ""
    Write-Host "To run tests:" -ForegroundColor Green
    Write-Host "  .\.claude\skills\.venv\Scripts\Activate.ps1"
    Write-Host "  cd .claude\skills\<skill-name>\scripts"
    Write-Host "  pytest tests\ -v"
    Write-Host ""
    Write-Host "Environment variables:" -ForegroundColor Green
    Write-Host "  Create .claude\skills\.env for shared config"
    Write-Host "  Create .claude\skills\<skill-name>\.env for skill-specific config"
    Write-Host ""
    Write-Host "For more information, see:" -ForegroundColor Blue
    Write-Host "  .claude\skills\INSTALLATION.md"
    Write-Host ""
}

# Show help
function Show-Help {
    Write-Host "Claude Code Skills Installation Script for Windows"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\install.ps1 [Options]"
    Write-Host ""
    Write-Host "Options:"
    Write-Host "  -Y                 Skip all prompts and auto-confirm installation"
    Write-Host "  -SkipChocolatey    Skip Chocolatey installation (uses winget/scoop instead)"
    Write-Host "  -Help              Show this help message"
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\install.ps1"
    Write-Host "  .\install.ps1 -Y"
    Write-Host "  .\install.ps1 -SkipChocolatey"
    Write-Host ""
    Write-Host "Package Manager Priority:"
    Write-Host "  1. winget (recommended, no admin required)"
    Write-Host "  2. scoop (no admin required)"
    Write-Host "  3. chocolatey (requires admin)"
    Write-Host ""
    Write-Host "Requirements:"
    Write-Host "  - PowerShell 5.1 or higher"
    Write-Host "  - One of: winget, scoop, or chocolatey (admin)"
    Write-Host ""
}

# Main installation flow
function Main {
    if ($Help) {
        Show-Help
        exit 0
    }

    Clear-Host
    Write-Header "Claude Code Skills Installation (Windows)"
    Write-Info "Script directory: $ScriptDir"

    # Show detected package manager
    $pm = Get-PackageManager
    if ($pm) {
        Write-Success "Detected package manager: $pm"
    } else {
        Write-Warning "No package manager detected (winget, scoop, or choco)"
        Write-Info "Install winget: https://aka.ms/getwinget"
    }
    Write-Host ""

    # Confirm installation (skip if -Y flag or NON_INTERACTIVE env is set)
    if (-not $Y) {
        $confirmation = Get-UserInput -Prompt "This will install system packages and Node.js dependencies. Continue? (y/N)" -Default "N"
        if ($confirmation -ne 'y' -and $confirmation -ne 'Y') {
            Write-Warning "Installation cancelled"
            exit 0
        }
    } else {
        Write-Info "Auto-confirming installation (-Y flag or NON_INTERACTIVE mode)"
    }

    try {
        $null = Install-Chocolatey
        Install-SystemDeps
        Install-NodeDeps
        Setup-PythonEnv
        Test-Installations
        Show-Usage
    } catch {
        Write-Error "Installation failed: $_"
        exit 1
    }
}

# Run main function
Main
