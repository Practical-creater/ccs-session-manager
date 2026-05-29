#!/usr/bin/env bash
# Install ccs into ~/.local/bin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN_DIR="${HOME}/.local/bin"

mkdir -p "$BIN_DIR"
cp "$SCRIPT_DIR/ccs" "$BIN_DIR/ccs"
chmod +x "$BIN_DIR/ccs"
echo "✓ Installed ccs -> $BIN_DIR/ccs"

case ":$PATH:" in
  *":$BIN_DIR:"*)
    echo "✓ $BIN_DIR is on your PATH — run 'ccs list' to start."
    ;;
  *)
    echo "⚠ $BIN_DIR is not on your PATH. Add this line to your ~/.zshrc or ~/.bashrc:"
    echo ""
    echo "    export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "  then restart your shell (or 'source' the file)."
    ;;
esac
