#!/bin/bash
# Removes tarx from the current user's ~/.local/bin. No sudo needed.

UTILITY_NAME="tarx"
INSTALL_DIR="$HOME/.local/bin"

if [ ! -e "$INSTALL_DIR/$UTILITY_NAME" ]; then
    echo "[ failure ] $UTILITY_NAME is not installed in $INSTALL_DIR"
    exit 1
fi

if rm -f "$INSTALL_DIR/$UTILITY_NAME"; then
    echo "[ success ] $UTILITY_NAME uninstalled"
else
    echo "[ failure ] could not remove $INSTALL_DIR/$UTILITY_NAME"
    exit 1
fi
