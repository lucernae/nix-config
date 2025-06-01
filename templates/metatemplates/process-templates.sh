#!/usr/bin/env bash
set -e

# Default values
CONTEXT_FILE=""
SOURCE_DIR=""
TARGET_DIR=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --context)
      CONTEXT_FILE="$2"
      shift 2
      ;;
    --source)
      SOURCE_DIR="$2"
      shift 2
      ;;
    --target)
      TARGET_DIR="$2"
      shift 2
      ;;
    --help)
      echo "Usage: process-templates --context CONTEXT_FILE --source SOURCE_DIR --target TARGET_DIR"
      echo ""
      echo "Options:"
      echo "  --context FILE    Path to a Nix file containing the context variables"
      echo "  --source DIR      Path to the source directory containing templates"
      echo "  --target DIR      Path to the target directory where processed files will be written"
      echo "  --help            Show this help message"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

# Validate required arguments
if [[ -z "$CONTEXT_FILE" ]]; then
  echo "Error: --context is required"
  exit 1
fi

if [[ -z "$SOURCE_DIR" ]]; then
  echo "Error: --source is required"
  exit 1
fi

if [[ -z "$TARGET_DIR" ]]; then
  echo "--target is required"
  echo "defaulting to current directory"
  TARGET_DIR="."
fi

# Convert to absolute paths
CONTEXT_FILE=$(realpath "$CONTEXT_FILE")
SOURCE_DIR=$(realpath "$SOURCE_DIR")

# Check if files/directories exist
if [[ ! -f "$CONTEXT_FILE" ]]; then
    echo "Error: Context file '$CONTEXT_FILE' does not exist"
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Error: Source directory '$SOURCE_DIR' does not exist"
    exit 1
fi

# Create target directory if it doesn't exist
mkdir -p "$TARGET_DIR"
TARGET_DIR=$(realpath "$TARGET_DIR")

# If the target context file exists, use that instead
if [[ -f "$TARGET_DIR/context.template.nix" ]]; then
  CONTEXT_FILE="$TARGET_DIR/context.template.nix"
  echo "Using target context file: '$CONTEXT_FILE'"
fi

# Function to process a single file
process_file() {
    local source_file="$1"
    local rel_path="${source_file#$SOURCE_DIR/}"
    local target_file="$TARGET_DIR/$rel_path"
    local target_dir="$(dirname "$target_file")"

    # Create target directory if it doesn't exist
    mkdir -p "$target_dir"

    # Exit immediately if the file is context.template.nix and target exists
    if [ "$rel_path" = "context.template.nix" ] && [[ -f $target_file ]]; then
        return 0
    fi

    # Process the file content using nix-instantiate
    local content=$(cat "$source_file")
    nix-instantiate --eval --expr "
      let
        pkgs = import <nixpkgs> {};
        lib = pkgs.lib;
        context_file = import $CONTEXT_FILE;
        context = context_file.context;
        utils = lib.attrByPath [\"utils\"] {} context_file;
        content = ''$content'';
      in
        content
    " --strict --raw > "$target_file"
}

# Find and process all files in the source directory
find "$SOURCE_DIR" -type f | while read -r file; do
    process_file "$file"
done

echo "Templates processed successfully from '$SOURCE_DIR' to '$TARGET_DIR'"
