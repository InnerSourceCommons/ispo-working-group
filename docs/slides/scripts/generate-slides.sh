#!/bin/bash
set -uo pipefail

# Generate ISPO Working Group Slides
# This script can be run locally to test slide generation
# 
# Usage: ./docs/slides/scripts/generate-slides.sh
#
# Prerequisites:
# - Node.js and npm installed
# - marp-cli installed globally: npm install -g @marp-team/marp-cli
# - Git LFS installed (optional, for committing PDFs)
# - Docker installed (optional, will use marp-cli if not available)

echo "🚀 Starting slide generation..."

# Configure Git (if not already configured)
if ! git config --global user.name >/dev/null 2>&1; then
  echo "📝 Configuring Git..."
  git config --global user.name "github-actions[bot]"
  git config --global user.email "41898282+github-actions[bot]@users.noreply.github.com"
fi

# Setup Git LFS Tracking
echo "🔧 Setting up Git LFS tracking..."
if command -v git-lfs &> /dev/null; then
  git lfs install --skip-repo || true
  # Track PDF and PPTX files in the slides directory (both are large binary files)
  # This is idempotent - if already tracked, it just updates .gitattributes
  # Warnings about missing files are non-fatal (files will be created during build)
  # The tracking pattern is still set correctly in .gitattributes
  git lfs track "docs/slides/**/*.pdf" 2>&1 || true
  git lfs track "docs/slides/**/*.pptx" 2>&1 || true
  # Stage .gitattributes if it was created or modified
  if [ -f .gitattributes ]; then
    git add .gitattributes || true
  fi
else
  echo "  ℹ Git LFS not installed, skipping LFS setup"
fi

# Build function to generate a single format
# Format is determined by output file extension (.pdf, .html, .pptx)
build_slide() {
  local md_file="$1"
  local output_path="$2"
  
  # Determine file type from extension
  local ext="${output_path##*.}"
  local format_name
  case "$ext" in
    pdf) format_name="PDF" ;;
    html) format_name="HTML" ;;
    pptx) format_name="PowerPoint" ;;
    *) format_name="$ext" ;;
  esac
  
  # Try docker first, fall back to marp-cli if docker fails or isn't available
  if docker info >/dev/null 2>&1 && docker run --rm \
    -v "$PWD:/workspace" \
    -w /workspace \
    -e MARP_USER=root:root \
    marpteam/marp-cli:v3.4.0 \
    --theme-set docs/slides/themes/*.css \
    --allow-local-files "$md_file" -o "$output_path" 2>/dev/null; then
    echo "  ✓ $format_name built"
    return 0
  else
    # For marp-cli, format is determined by output file extension
    if marp \
      --theme-set "docs/slides/themes/*.css" \
      --allow-local-files \
      -- "$md_file" -o "$output_path"; then
      echo "  ✓ $format_name built"
      return 0
    else
      echo "  ✗ $format_name build failed"
      return 1
    fi
  fi
}

# Build All Slides
echo "📊 Building slides..."
# Find all .md files in docs/slides subdirectories only (not in root, excluding README.md)
# Using -mindepth 2 ensures we only process files in subdirectories, not docs/slides/*.md
find docs/slides -mindepth 2 -type f -name "*.md" ! -name "README.md" | while read -r md_file; do
  # Get directory and filename without extension
  dir=$(dirname "$md_file")
  filename=$(basename "$md_file" .md)
  
  # Copy logo to slide directory so it's accessible from generated HTML
  if [ ! -f "${dir}/ispo-logo.svg" ]; then
    cp docs/assets/ispo-logo.svg "${dir}/ispo-logo.svg" 2>/dev/null || true
  fi
  
  # Output paths for all formats in the same directory as the markdown file
  pdf_path="${dir}/${filename}.pdf"
  html_path="${dir}/${filename}.html"
  pptx_path="${dir}/${filename}.pptx"
  
  echo "Building: $md_file"
  echo "  → PDF: $pdf_path"
  echo "  → HTML: $html_path"
  echo "  → PowerPoint: $pptx_path"
  
  build_slide "$md_file" "$pdf_path"
  build_slide "$md_file" "$html_path"
  build_slide "$md_file" "$pptx_path"
done

# Commit Generated Slides
echo "💾 Committing generated slides..."
# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
  echo "  ℹ Not in a git repository, skipping commit"
else
  # Add all generated files (PDFs and PPTX will be tracked by LFS, HTML is text)
  # Use find to locate files since git add doesn't expand glob patterns
  find docs/slides -type f -name "*.pdf" -exec git add {} \; 2>/dev/null || true
  find docs/slides -type f -name "*.pptx" -exec git add {} \; 2>/dev/null || true
  find docs/slides -type f -name "*.html" -exec git add {} \; 2>/dev/null || true
  # Also add .gitattributes if it exists and was modified
  if [ -f .gitattributes ]; then
    git add .gitattributes 2>/dev/null || true
  fi
  # Check if there are any changes to commit
  if git diff --staged --quiet 2>/dev/null; then
    echo "  ℹ No changes to commit"
  else
    git commit -m "chore: regenerate slide PDFs, HTML, and PowerPoint [skip ci]" || true
    # Try to push, but don't fail if authentication isn't available (e.g., local testing)
    if git push 2>&1; then
      echo "  ✓ Successfully pushed changes"
    else
      push_exit_code=$?
      if [ $push_exit_code -eq 128 ] || [ $push_exit_code -eq 1 ]; then
        echo "  ⚠️  Warning: Could not push changes (likely authentication issue)"
        echo "  This is expected when running locally. Changes are committed locally."
      else
        echo "  ⚠️  Warning: Push failed with exit code $push_exit_code"
      fi
    fi
  fi
fi

# List Generated Slides
echo "📋 Generated slides:"
pdf_count=$(find docs/slides -type f -name "*.pdf" | wc -l)
html_count=$(find docs/slides -type f -name "*.html" | wc -l)
pptx_count=$(find docs/slides -type f -name "*.pptx" | wc -l)
total_count=$((pdf_count + html_count + pptx_count))

# Check if running in GitHub Actions
if [ -n "${GITHUB_STEP_SUMMARY:-}" ]; then
  # Output to GitHub Actions step summary
  echo "## 📊 Generated Slides" >> "$GITHUB_STEP_SUMMARY"
  echo "" >> "$GITHUB_STEP_SUMMARY"
  if [ "$total_count" -eq 0 ]; then
    echo "⚠️ No slide files were generated." >> "$GITHUB_STEP_SUMMARY"
  else
    echo "The following slide files have been generated:" >> "$GITHUB_STEP_SUMMARY"
    echo "- PDF: $pdf_count file(s)" >> "$GITHUB_STEP_SUMMARY"
    echo "- HTML: $html_count file(s)" >> "$GITHUB_STEP_SUMMARY"
    echo "- PowerPoint: $pptx_count file(s)" >> "$GITHUB_STEP_SUMMARY"
    echo "" >> "$GITHUB_STEP_SUMMARY"
    # List all generated files
    find docs/slides -type f \( -name "*.pdf" -o -name "*.html" -o -name "*.pptx" \) | sort | while read -r slide_file; do
      rel_path="$slide_file"
      filename=$(basename "$slide_file")
      ext="${filename##*.}"
      # Output to step summary with link
      echo "- **$filename** (\`$ext\`) - \`$rel_path\`" >> "$GITHUB_STEP_SUMMARY"
      # Build repository URL if GitHub variables are available
      if [ -n "${GITHUB_SERVER_URL:-}" ] && [ -n "${GITHUB_REPOSITORY:-}" ] && [ -n "${GITHUB_REF_NAME:-}" ]; then
        repo_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/blob/${GITHUB_REF_NAME}/$rel_path"
        echo "  - [View in repository]($repo_url)" >> "$GITHUB_STEP_SUMMARY"
      fi
      # Also output to console with GitHub Actions annotation
      echo "::notice file=$rel_path::Generated slide: $rel_path"
    done
  fi
  echo "" >> "$GITHUB_STEP_SUMMARY"
fi

# Always output to console as well
if [ "$total_count" -eq 0 ]; then
  echo "  ⚠️ No slide files were generated."
else
  echo "  Generated files:"
  echo "    - PDF: $pdf_count file(s)"
  echo "    - HTML: $html_count file(s)"
  echo "    - PowerPoint: $pptx_count file(s)"
  echo ""
  echo "  Files:"
  find docs/slides -type f \( -name "*.pdf" -o -name "*.html" -o -name "*.pptx" \) | sort | while read -r slide_file; do
    echo "    - $slide_file"
  done
fi

echo "✅ Slide generation complete!"

