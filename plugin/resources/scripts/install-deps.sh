#!/bin/bash
# Circle — Dependency Installer
# First-time setup for Circle ecosystem dependencies.
#
# Usage:
#   bash install-deps.sh                    # Interactive mode
#   bash install-deps.sh --check-only       # Just show status
#   bash install-deps.sh --group=core,ios   # Install specific groups
#   bash install-deps.sh --all              # Install everything
#   bash install-deps.sh --dep=cupertino    # Install single dependency
#
# All dependencies are optional. Agents degrade gracefully when missing.
# See deps-manifest.yaml for the full dependency registry.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# ── Colors ──────────────────────────────────────────────────────────────────
if [ -t 1 ]; then
  GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'
  BLUE='\033[0;34m'; BOLD='\033[1m'; DIM='\033[2m'; NC='\033[0m'
else
  GREEN=''; RED=''; YELLOW=''; BLUE=''; BOLD=''; DIM=''; NC=''
fi

# ── Dependency Registry ────────────────────────────────────────────────────
# Format: ID|GROUP|TYPE|NAME|DESCRIPTION|CHECK_CMD|INSTALL_CMD|USED_BY|REQUIRES|INSTALL_NOTE
# Keep in sync with deps-manifest.yaml

PLUGINS_JSON="$HOME/.claude/plugins/installed_plugins.json"

DEPS=(
  "linear|core|mcp-cloud|Linear|Issue tracking and project management|||all agents||Enable in Claude Code settings > MCP Servers > Linear"
  "claude-mem|core|plugin|claude-mem|Cross-session semantic memory|grep -q claude-mem $PLUGINS_JSON 2>/dev/null|claude plugin marketplace add thedotmack && claude plugin install claude-mem@thedotmack|all agents||"
  "notion|extras|plugin|Notion|Notion workspace integration|grep -q Notion $PLUGINS_JSON 2>/dev/null|claude plugin marketplace add claude-plugins-official && claude plugin install Notion@claude-plugins-official|docs||"
  "bmad-mcp|extras|npm|bmad-mcp|Circle MCP server for workflow orchestration|npm list -g bmad-mcp 2>/dev/null \| grep -q bmad-mcp|npm install -g bmad-mcp|greenfield||"
)

# iOS / Swift development deps have moved to the companion plugin `circle-ios`
# as of v2.0.0. Install the companion plugin to get those prompts from its own
# deps-manifest.yaml.

GROUP_LABELS=(
  "core|Core (recommended for all teams)"
  "extras|Additional tools"
)

# ── Argument parsing ───────────────────────────────────────────────────────
MODE="interactive"
GROUPS=""
SINGLE_DEP=""

for arg in "$@"; do
  case $arg in
    --check-only)   MODE="check-only" ;;
    --all)          MODE="auto"; GROUPS="core,ios,extras" ;;
    --group=*)      MODE="auto"; GROUPS="${arg#--group=}" ;;
    --dep=*)        MODE="auto"; SINGLE_DEP="${arg#--dep=}" ;;
    -h|--help)
      echo "Circle — Dependency Installer"
      echo ""
      echo "Usage:"
      echo "  bash install-deps.sh                    # Interactive mode"
      echo "  bash install-deps.sh --check-only       # Just show status"
      echo "  bash install-deps.sh --group=core,ios   # Install specific groups"
      echo "  bash install-deps.sh --all              # Install everything"
      echo "  bash install-deps.sh --dep=cupertino    # Install single dependency"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg (use --help)"
      exit 1
      ;;
  esac
done

# ── Prerequisite detection ─────────────────────────────────────────────────
HAS_CLAUDE=false; HAS_NPM=false; HAS_BREW=false

command -v claude &>/dev/null && HAS_CLAUDE=true
command -v npm &>/dev/null    && HAS_NPM=true
command -v brew &>/dev/null   && HAS_BREW=true

print_prerequisites() {
  echo -e "${BOLD}Prerequisites${NC}"
  if $HAS_CLAUDE; then echo -e "  ${GREEN}ok${NC}  claude CLI"
  else                  echo -e "  ${RED}--${NC}  claude CLI (required for plugin installs)"; fi
  if $HAS_NPM; then    echo -e "  ${GREEN}ok${NC}  npm"
  else                  echo -e "  ${YELLOW}--${NC}  npm (needed for bmad-mcp)"; fi
  if $HAS_BREW; then   echo -e "  ${GREEN}ok${NC}  Homebrew"
  else                  echo -e "  ${YELLOW}--${NC}  Homebrew (needed for Cupertino — https://brew.sh)"; fi
  echo ""
}

# ── Field accessors ────────────────────────────────────────────────────────
# Parse pipe-delimited dependency entry
dep_id()          { echo "$1" | cut -d'|' -f1; }
dep_group()       { echo "$1" | cut -d'|' -f2; }
dep_type()        { echo "$1" | cut -d'|' -f3; }
dep_name()        { echo "$1" | cut -d'|' -f4; }
dep_desc()        { echo "$1" | cut -d'|' -f5; }
dep_check()       { echo "$1" | cut -d'|' -f6; }
dep_install()     { echo "$1" | cut -d'|' -f7; }
dep_used_by()     { echo "$1" | cut -d'|' -f8; }
dep_requires()    { echo "$1" | cut -d'|' -f9; }
dep_note()        { echo "$1" | cut -d'|' -f10; }

group_label() {
  local g="$1"
  for entry in "${GROUP_LABELS[@]}"; do
    local gid="${entry%%|*}"
    if [ "$gid" = "$g" ]; then
      echo "${entry#*|}"
      return
    fi
  done
}

# Find dep entry by id
find_dep() {
  local id="$1"
  for entry in "${DEPS[@]}"; do
    if [ "$(dep_id "$entry")" = "$id" ]; then
      echo "$entry"
      return
    fi
  done
}

# ── Check function ─────────────────────────────────────────────────────────
# Returns: "installed", "missing", or "manual"
check_dep() {
  local entry="$1"
  local check_cmd
  check_cmd=$(dep_check "$entry")

  if [ -z "$check_cmd" ]; then
    echo "manual"
  elif eval "$check_cmd" &>/dev/null; then
    echo "installed"
  else
    echo "missing"
  fi
}

# ── Status table ───────────────────────────────────────────────────────────
TOTAL_INSTALLED=0
TOTAL_MISSING=0
TOTAL_MANUAL=0

print_status_group() {
  local group="$1"
  local label has_deps=false
  label=$(group_label "$group")

  # Check if any deps in this group
  for entry in "${DEPS[@]}"; do
    if [ "$(dep_group "$entry")" = "$group" ]; then
      has_deps=true
      break
    fi
  done
  if ! $has_deps; then return; fi

  echo -e "  ${BOLD}$label${NC}"

  for entry in "${DEPS[@]}"; do
    if [ "$(dep_group "$entry")" != "$group" ]; then continue; fi

    local name desc status note
    name=$(dep_name "$entry")
    desc=$(dep_desc "$entry")
    status=$(check_dep "$entry")

    case $status in
      installed)
        echo -e "    ${GREEN}[ok]${NC}      $name  ${DIM}$desc${NC}"
        TOTAL_INSTALLED=$((TOTAL_INSTALLED + 1))
        ;;
      missing)
        echo -e "    ${RED}[--]${NC}      $name  ${DIM}$desc${NC}"
        TOTAL_MISSING=$((TOTAL_MISSING + 1))
        ;;
      manual)
        note=$(dep_note "$entry")
        echo -e "    ${YELLOW}[manual]${NC}  $name  ${DIM}$note${NC}"
        TOTAL_MANUAL=$((TOTAL_MANUAL + 1))
        ;;
    esac
  done
  echo ""
}

print_full_status() {
  TOTAL_INSTALLED=0; TOTAL_MISSING=0; TOTAL_MANUAL=0

  echo -e "${BOLD}Circle Dependencies${NC}"
  echo "=================="
  echo ""

  print_status_group "core"

  # Auto-detect iOS group relevance
  if test -f Package.swift 2>/dev/null || ls *.xcodeproj 1>/dev/null 2>&1; then
    print_status_group "ios"
  else
    echo -e "  ${DIM}iOS / Swift: not detected (no Package.swift or .xcodeproj)${NC}"
    echo ""
  fi

  print_status_group "extras"

  echo -e "  ${GREEN}$TOTAL_INSTALLED installed${NC}, ${RED}$TOTAL_MISSING missing${NC}, ${YELLOW}$TOTAL_MANUAL manual${NC}"
  echo ""
}

# ── Install function ───────────────────────────────────────────────────────

install_dep_by_entry() {
  local entry="$1"
  local name install_cmd note dtype requires
  name=$(dep_name "$entry")
  install_cmd=$(dep_install "$entry")
  note=$(dep_note "$entry")
  dtype=$(dep_type "$entry")
  requires=$(dep_requires "$entry")

  # Check if already installed
  local status
  status=$(check_dep "$entry")
  if [ "$status" = "installed" ]; then
    echo -e "  ${GREEN}ok${NC}  $name — already installed"
    return 0
  fi
  if [ "$status" = "manual" ]; then
    echo -e "  ${YELLOW}!${NC}   $name — $note"
    return 0
  fi

  # Check prerequisites
  if [ "$requires" = "brew" ] && ! $HAS_BREW; then
    echo -e "  ${RED}x${NC}   $name — requires Homebrew (https://brew.sh)"
    return 1
  fi
  if [ "$dtype" = "plugin" ] && ! $HAS_CLAUDE; then
    echo -e "  ${RED}x${NC}   $name — requires claude CLI"
    return 1
  fi
  if [ "$dtype" = "npm" ] && ! $HAS_NPM; then
    echo -e "  ${RED}x${NC}   $name — requires npm"
    return 1
  fi

  # Install
  if [ -z "$install_cmd" ]; then
    echo -e "  ${YELLOW}!${NC}   $name — no install command (manual setup required)"
    return 0
  fi

  echo -e "  ${BLUE}>${NC}   Installing $name..."
  if eval "$install_cmd" 2>/dev/null; then
    echo -e "  ${GREEN}+${NC}   $name — installed"
    return 0
  else
    echo -e "  ${RED}x${NC}   $name — installation failed"
    echo -e "       Try manually: $install_cmd"
    return 1
  fi
}

install_dep_by_id() {
  local id="$1"
  local entry
  entry=$(find_dep "$id")
  if [ -z "$entry" ]; then
    echo -e "${RED}Error:${NC} Unknown dependency: $id"
    return 1
  fi
  install_dep_by_entry "$entry"
}

install_group() {
  local group="$1"
  local label
  label=$(group_label "$group")

  echo -e "${BOLD}Installing: $label${NC}"
  for entry in "${DEPS[@]}"; do
    if [ "$(dep_group "$entry")" = "$group" ]; then
      install_dep_by_entry "$entry" || true
    fi
  done
  echo ""
}

# ── Interactive guided mode ────────────────────────────────────────────────

interactive_guided() {
  echo -e "${BOLD}Guided Setup${NC}"
  echo "============"
  echo ""

  for group in core ios extras; do
    # Skip iOS if not detected
    if [ "$group" = "ios" ]; then
      if ! test -f Package.swift 2>/dev/null && ! ls *.xcodeproj 1>/dev/null 2>&1; then
        continue
      fi
    fi

    local label
    label=$(group_label "$group")
    echo -e "${BOLD}$label${NC}"
    echo ""

    for entry in "${DEPS[@]}"; do
      if [ "$(dep_group "$entry")" != "$group" ]; then continue; fi

      local status name desc install_cmd note used_by
      status=$(check_dep "$entry")
      name=$(dep_name "$entry")
      desc=$(dep_desc "$entry")
      install_cmd=$(dep_install "$entry")
      note=$(dep_note "$entry")
      used_by=$(dep_used_by "$entry")

      if [ "$status" = "installed" ]; then
        echo -e "  ${GREEN}ok${NC}  $name — already installed"
        continue
      fi

      if [ "$status" = "manual" ]; then
        echo -e "  ${YELLOW}!${NC}   $name — $note"
        echo -e "       Used by: $used_by"
        echo ""
        continue
      fi

      echo -e "  --- $name ($desc) ---"
      echo -e "  Used by: $used_by"
      if [ -n "$install_cmd" ]; then
        echo -e "  Command: $install_cmd"
      fi
      echo ""
      read -p "  Install? [y/N]: " answer
      case "$answer" in
        [yY]|[yY][eE][sS])
          install_dep_by_entry "$entry" || true
          ;;
        *)
          echo -e "  Skipped."
          ;;
      esac
      echo ""
    done
  done
}

# ── Interactive mode ───────────────────────────────────────────────────────

interactive_mode() {
  echo -e "${BOLD}Circle — First-Time Setup${NC}"
  echo "=================================="
  echo ""

  print_prerequisites
  print_full_status

  if [ "$TOTAL_MISSING" -eq 0 ]; then
    echo "All installable dependencies are ready."
    return 0
  fi

  echo "How would you like to proceed?"
  echo ""
  echo "  1) Auto-install all missing dependencies"
  echo "  2) Guided setup (choose one by one)"
  echo "  3) Skip (agents degrade gracefully)"
  echo ""
  read -p "Choice [1-3]: " choice

  echo ""
  case "$choice" in
    1)
      for group in core ios extras; do
        if [ "$group" = "ios" ]; then
          if ! test -f Package.swift 2>/dev/null && ! ls *.xcodeproj 1>/dev/null 2>&1; then
            continue
          fi
        fi
        install_group "$group"
      done
      ;;
    2)
      interactive_guided
      ;;
    3)
      echo "Skipping dependency setup."
      echo "Run again anytime: bash $SCRIPT_DIR/install-deps.sh"
      ;;
    *)
      echo "Invalid choice. Exiting."
      exit 1
      ;;
  esac

  echo ""
  echo -e "${BOLD}Updated Status${NC}"
  print_full_status
}

# ── Main ───────────────────────────────────────────────────────────────────

case "$MODE" in
  check-only)
    print_prerequisites
    print_full_status
    ;;
  auto)
    if [ -n "$SINGLE_DEP" ]; then
      install_dep_by_id "$SINGLE_DEP"
    else
      IFS=',' read -ra GROUP_ARRAY <<< "$GROUPS"
      for group in "${GROUP_ARRAY[@]}"; do
        install_group "$group"
      done
    fi
    ;;
  interactive)
    interactive_mode
    ;;
esac
