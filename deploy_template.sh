#!/bin/bash
# deploy_template.sh - Robust iOS App Template Deployment Script (safe by default)
# Deploys this template as a new project or integrates code into an existing blank app
# 2025 - Internal Thought

set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log()   { echo -e "${BLUE}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }
ok()    { echo -e "${GREEN}[OK]${NC} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_ROOT="$SCRIPT_DIR"
SRC_APP_DIR="$SRC_ROOT/app-template"
SRC_XCODEPROJ="$SRC_ROOT/app-template.xcodeproj"
SRC_TESTS_DIR="$SRC_ROOT/app-templateTests"
SRC_UITESTS_DIR="$SRC_ROOT/app-templateUITests"

DEST_DIR=""
NEW_BUNDLE_ID=""
NEW_APP_NAME=""
MODE="project" # project | integrate
DRY_RUN=false
INTERACTIVE=true
FORCE=false
MODIFY_PBXPROJ=false

usage() {
  cat <<EOF
Usage:
  ./deploy_template.sh <destination_path> [OPTIONS]

Options:
  --bundle-id <id>         Bundle identifier to set (opt-in; no pbxproj mutation unless --modify-pbxproj)
  --name <name>            App display name (default: destination folder name)
  --mode <project|integrate>  project (copy xcodeproj) or integrate (copy Sources only)
  --modify-pbxproj         Opt-in: attempt to update bundle identifiers in project.pbxproj (use with caution)
  --dry-run                Simulate deployment
  --non-interactive        Do not prompt
  --force                  Overwrite destination contents if not empty
  -h, --help               Show help

Examples:
  # New project (safe default)
  ./deploy_template.sh ~/Dev/MyNewApp --name "My New App" --bundle-id com.me.mynewapp

  # Integrate into an existing blank app (no project settings changed)
  ./deploy_template.sh ~/Dev/BlankApp --mode integrate --name "Blank App"
EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --bundle-id) NEW_BUNDLE_ID="$2"; shift 2 ;;
      --bundle-id=*) NEW_BUNDLE_ID="${1#*=}"; shift ;;
      --name) NEW_APP_NAME="$2"; shift 2 ;;
      --name=*) NEW_APP_NAME="${1#*=}"; shift ;;
      --mode) MODE="$2"; shift 2 ;;
      --mode=*) MODE="${1#*=}"; shift ;;
      --modify-pbxproj) MODIFY_PBXPROJ=true; shift ;;
      --dry-run) DRY_RUN=true; shift ;;
      --non-interactive) INTERACTIVE=false; shift ;;
      --force) FORCE=true; shift ;;
      -h|--help) usage; exit 0 ;;
      *) if [[ -z "$DEST_DIR" ]]; then DEST_DIR="$1"; shift; else error "Unknown arg: $1"; usage; exit 1; fi ;;
    esac
  done

  if [[ -z "$DEST_DIR" ]]; then error "Destination path required"; usage; exit 1; fi
  if [[ -z "$NEW_APP_NAME" ]]; then NEW_APP_NAME=$(basename "$DEST_DIR"); fi
  if [[ "$MODE" != "project" && "$MODE" != "integrate" ]]; then error "Invalid --mode: $MODE"; exit 1; fi
}

trap 'error "Deployment failed"; exit 1' ERR

validate_env() {
  log "Validating environment"
  command -v xcodebuild >/dev/null || { error "xcodebuild not found"; exit 1; }
  local ver; ver=$(xcodebuild -version | head -1 | awk '{print $2}')
  if ! awk -v v="$ver" 'BEGIN{split(v,a,"."); if (a[1] < 15) exit 1}'; then
    warn "Xcode 15+ recommended. Found: $ver"
  fi
  ok "Environment OK"
}

ensure_dest() {
  log "Preparing destination: $DEST_DIR"
  if $DRY_RUN; then return; fi
  if [[ -e "$DEST_DIR" ]]; then
    if [[ -d "$DEST_DIR" && -z "$(ls -A "$DEST_DIR")" ]]; then
      ok "Destination exists and is empty"
    else
      if $FORCE; then
        warn "Force mode: clearing destination"
        rm -rf "$DEST_DIR"/*
      else
        if $INTERACTIVE; then
          read -r -p "Destination not empty. Overwrite? (y/N) " ans
          [[ "$ans" =~ ^[Yy]$ ]] || { log "Cancelled"; exit 0; }
          rm -rf "$DEST_DIR"/*
        else
          error "Destination not empty. Use --force or empty it manually."
          exit 1
        fi
      fi
    fi
  else
    mkdir -p "$DEST_DIR"
  fi
  ok "Destination ready"
}

copy_project_mode() {
  log "[project] Copying template project"
  $DRY_RUN || {
    cp -R "$SRC_APP_DIR" "$DEST_DIR/"
    cp -R "$SRC_XCODEPROJ" "$DEST_DIR/" 2>/dev/null || true
    [[ -d "$SRC_TESTS_DIR" ]] && cp -R "$SRC_TESTS_DIR" "$DEST_DIR/"
    [[ -d "$SRC_UITESTS_DIR" ]] && cp -R "$SRC_UITESTS_DIR" "$DEST_DIR/"
    cp "$SCRIPT_DIR/build_release.sh" "$DEST_DIR/" 2>/dev/null || true
  }
  ok "[project] Files copied"

  local old_proj_name="app-template"
  local new_proj_name
  new_proj_name=$(echo "$NEW_APP_NAME" | tr -dc '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')

  if [[ "$old_proj_name" != "$new_proj_name" ]]; then
    log "Renaming Xcode project to ${new_proj_name}.xcodeproj"
    $DRY_RUN || {
      if [[ -d "$DEST_DIR/${old_proj_name}.xcodeproj" ]]; then
        mv "$DEST_DIR/${old_proj_name}.xcodeproj" "$DEST_DIR/${new_proj_name}.xcodeproj"
      fi
      [[ -d "$DEST_DIR/${old_proj_name}Tests" ]] && mv "$DEST_DIR/${old_proj_name}Tests" "$DEST_DIR/${new_proj_name}Tests"
      [[ -d "$DEST_DIR/${old_proj_name}UITests" ]] && mv "$DEST_DIR/${old_proj_name}UITests" "$DEST_DIR/${new_proj_name}UITests"
    }
    ok "Project renamed"
  fi

  local info_plist="$DEST_DIR/app-template/Info.plist"
  if [[ -f "$info_plist" ]]; then
    log "Updating Info.plist app name"
    $DRY_RUN || {
      /usr/libexec/PlistBuddy -c "Set :CFBundleName $NEW_APP_NAME" "$info_plist" 2>/dev/null || true
      /usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName $NEW_APP_NAME" "$info_plist" 2>/dev/null || true
    }
  fi

  if [[ -n "${NEW_BUNDLE_ID}" && "$MODIFY_PBXPROJ" == true ]]; then
    warn "Attempting to update bundle identifiers in project.pbxproj (opt-in)"
    local proj_file="$DEST_DIR/${new_proj_name}.xcodeproj/project.pbxproj"
    if [[ -f "$proj_file" ]]; then
      $DRY_RUN || {
        cp "$proj_file" "$proj_file.bak.$(date +%s)"
        sed -i '' "s/internalthought\.app-template/${NEW_BUNDLE_ID}/g" "$proj_file" || true
        sed -i '' "s/internalthought\.app-templateTests/${NEW_BUNDLE_ID}.Tests/g" "$proj_file" || true
        sed -i '' "s/internalthought\.app-templateUITests/${NEW_BUNDLE_ID}.UITests/g" "$proj_file" || true
      }
    else
      warn "project.pbxproj not found at expected path; skipping bundle id update"
    fi
  else
    log "Skipping pbxproj modification (safe default). Set bundle ID in Xcode manually."
  fi

  ok "[project] Deployment complete"
}

copy_integrate_mode() {
  log "[integrate] Copying Sources into existing blank project (no settings changed)"
  $DRY_RUN || {
    mkdir -p "$DEST_DIR/TemplateSources"
    rsync -a --exclude="*.xcodeproj" --exclude="*Tests" "$SRC_APP_DIR/" "$DEST_DIR/TemplateSources/"
  }
  ok "Sources copied to $DEST_DIR/TemplateSources"

  cat <<EONOTE

Next steps to integrate:
1) Open your existing Xcode project in $DEST_DIR
2) Drag the 'TemplateSources' folder into your project (Copy items if needed)
3) Set your app entry point to 'AppTemplateApp' or merge ContentView/Coordinator into your App struct
4) Add SPM packages in Xcode:
   - Supabase (github.com/supabase-community/supabase-swift)
   - RevenueCat (github.com/RevenueCat/purchases-ios)
5) Set bundle identifier and capabilities in Signing & Capabilities
EONOTE
}

resolve_packages() {
  log "Resolving Swift Packages (best-effort)"
  local proj
  if [[ "$MODE" == "project" ]]; then
    local base=$(echo "$NEW_APP_NAME" | tr -dc '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')
    if [[ -d "$DEST_DIR/${base}.xcodeproj" ]]; then
      proj="$DEST_DIR/${base}.xcodeproj"
    elif [[ -d "$DEST_DIR/app-template.xcodeproj" ]]; then
      proj="$DEST_DIR/app-template.xcodeproj"
    fi
  fi

  if [[ -n "${proj:-}" ]]; then
    (cd "$DEST_DIR" && xcodebuild -resolvePackageDependencies -project "$(basename "$proj")" >/dev/null 2>&1) || warn "Package resolution may require opening Xcode"
  else
    warn "Project not found for package resolution; you can resolve inside Xcode"
  fi
  ok "Package resolution step finished"
}

validate() {
  log "Basic validation"
  if [[ "$MODE" == "project" ]]; then
    local base=$(echo "$NEW_APP_NAME" | tr -dc '[:alnum:]_-' | tr '[:upper:]' '[:lower:]')
    local proj="$DEST_DIR/${base}.xcodeproj"
    [[ -d "$proj" ]] || proj="$DEST_DIR/app-template.xcodeproj"
    if [[ ! -d "$proj" ]]; then error "Xcode project not found in destination"; exit 1; fi
    ok "Found project: $(basename "$proj")"
  else
    [[ -d "$DEST_DIR/TemplateSources" ]] || { error "TemplateSources missing"; exit 1; }
    ok "Found integrated sources"
  fi
}

main() {
  parse_args "$@"
  validate_env
  ensure_dest

  case "$MODE" in
    project) copy_project_mode ;;
    integrate) copy_integrate_mode ;;
  esac

  resolve_packages
  validate

  ok "Deployment completed successfully"
  log "Open the project in Xcode to finish signing and run."
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ $# -eq 0 ]]; then usage; exit 1; fi
  main "$@"
fi