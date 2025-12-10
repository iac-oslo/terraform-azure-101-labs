#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Bootstrap script for creating a new workshop repository from template.

.DESCRIPTION
    This script creates a new repository in the iac-oslo organization from the labs-repo-template
    and customizes it with the provided workshop name and repository name.

.PARAMETER WorkshopName
    The name of the workshop to be used in documentation.

.PARAMETER RepoName
    The repository name without the organization prefix (only lowercase letters, numbers, and hyphens are allowed).

.EXAMPLE
    .\bootstrap.ps1 -WorkshopName "Azure Networking Workshop" -RepoName "azure-networking-lab"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, HelpMessage = "The name of the workshop")]
    [ValidateNotNullOrEmpty()]
    [string]$WorkshopName,

    [Parameter(Mandatory = $true, HelpMessage = "The repository name (lowercase letters, numbers, and hyphens only)")]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[a-z0-9-]+$', ErrorMessage = "RepoName must contain only lowercase letters, numbers, and hyphens")]
    [string]$RepoName
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Function to check if GitHub CLI is installed
function Test-GitHubCLI {
    Write-Host "Checking if GitHub CLI is installed..." -ForegroundColor Cyan

    $ghCommand = Get-Command gh -ErrorAction SilentlyContinue

    if (-not $ghCommand) {
        throw "GitHub CLI (gh) is not installed. Please install it from https://cli.github.com/"
    }

    Write-Host "✓ GitHub CLI is installed" -ForegroundColor Green

    # Check if authenticated
    try {
        $null = gh auth status 2>&1
        Write-Host "✓ GitHub CLI is authenticated" -ForegroundColor Green
    }
    catch {
        throw "GitHub CLI is not authenticated. Please run 'gh auth login' first."
    }
}

# Function to create repository from template
function New-RepositoryFromTemplate {
    param(
        [string]$Organization = "iac-oslo",
        [string]$Template = "labs-repo-template",
        [string]$NewRepoName
    )

    Write-Host "Creating repository '$NewRepoName' from template '$Organization/$Template'..." -ForegroundColor Cyan

    try {
        gh repo create "$Organization/$NewRepoName" `
            --template "$Organization/$Template" `
            --public `
            --clone

        Write-Host "✓ Repository created successfully" -ForegroundColor Green

        # Change to the new repository directory
        Set-Location $NewRepoName
        Write-Host "✓ Changed directory to $NewRepoName" -ForegroundColor Green
    }
    catch {
        throw "Failed to create repository: $_"
    }
}

# Function to replace text in file
function Update-FileContent {
    param(
        [string]$FilePath,
        [string]$OldText,
        [string]$NewText
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        return
    }

    Write-Host "Updating $FilePath..." -ForegroundColor Cyan

    $content = Get-Content -Path $FilePath -Raw
    $updatedContent = $content -replace [regex]::Escape($OldText), $NewText

    if ($content -ne $updatedContent) {
        Set-Content -Path $FilePath -Value $updatedContent -NoNewline
        Write-Host "✓ Updated $FilePath" -ForegroundColor Green
    }
    else {
        Write-Host "  No changes needed in $FilePath" -ForegroundColor Yellow
    }
}

# Main script execution
try {
    Write-Host "`n=== Workshop Repository Bootstrap ===" -ForegroundColor Magenta
    Write-Host "Workshop Name: $WorkshopName" -ForegroundColor White
    Write-Host "Repository Name: $RepoName" -ForegroundColor White
    Write-Host ""

    # Step 1: Check GitHub CLI
    Test-GitHubCLI

    # Step 2: Create repository from template
    New-RepositoryFromTemplate -NewRepoName $RepoName

    # Step 3: Update README.md
    Update-FileContent `
        -FilePath "README.md" `
        -OldText "WORKSHOP_NAME_PLACEHOLDER" `
        -NewText $WorkshopName

    # Step 4: Update mkdocs.yml - Workshop name
    Update-FileContent `
        -FilePath "mkdocs.yml" `
        -OldText "WORKSHOP_NAME_PLACEHOLDER" `
        -NewText $WorkshopName

    # Step 5: Update mkdocs.yml - Repository URL
    Update-FileContent `
        -FilePath "mkdocs.yml" `
        -OldText "https://github.com/iac-oslo/repo-name-placeholder" `
        -NewText "https://github.com/iac-oslo/$RepoName"

    # Step 6: Update cicd.yaml - Repository name
    Update-FileContent `
        -FilePath ".github/workflows/cicd.yaml" `
        -OldText "repository-name-placeholder" `
        -NewText $RepoName

    # Step 7: Commit changes
    Write-Host "`nCommitting changes..." -ForegroundColor Cyan
    git add .
    git commit -m "Bootstrap workshop: $WorkshopName"
    git push
    Write-Host "✓ Changes committed and pushed" -ForegroundColor Green

    Write-Host "`n=== Bootstrap Complete ===" -ForegroundColor Green
    Write-Host "Repository URL: https://github.com/iac-oslo/$RepoName" -ForegroundColor White
    Write-Host ""
}
catch {
    Write-Error "Bootstrap failed: $_"
    exit 1
}
