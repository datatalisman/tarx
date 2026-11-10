#!/bin/bash
# Installs tarx for the current user. No sudo needed.

UTILITY_NAME="tarx"
INSTALL_DIR="$HOME/.local/bin"
PATH_LINE='export PATH="$HOME/.local/bin:$PATH"'

# run from the folder this script lives in; tarx may be in ./src or next to it
cd "$(dirname "$0")" || exit 1
if [ -f "./src/$UTILITY_NAME" ]; then
    SOURCE="./src/$UTILITY_NAME"
elif [ -f "./$UTILITY_NAME" ]; then
    SOURCE="./$UTILITY_NAME"
else
    echo "[ failure ] $UTILITY_NAME script not found (looked in ./src and .)"
    exit 1
fi

mkdir -p "$INSTALL_DIR" || { echo "[ failure ] cannot create $INSTALL_DIR"; exit 1; }

if install -m 755 "$SOURCE" "$INSTALL_DIR/$UTILITY_NAME"; then
    echo "[ success ] $UTILITY_NAME installed to $INSTALL_DIR/$UTILITY_NAME"
else
    echo "[ failure ] $UTILITY_NAME installation failed"
    exit 1
fi

# make sure ~/.local/bin is in PATH for future terminals
add_path_to_rc() {
    rc="$1"
    # already configured (any form of .local/bin) -> do nothing
    if grep -qs '\.local/bin' "$rc"; then
        return 1
    fi
    {
        echo ""
        echo "# added by tarx installer"
        echo "$PATH_LINE"
    } >> "$rc" && echo "[ status  ] added ~/.local/bin to PATH in $rc"
    return 0
}

case ":$PATH:" in
    *":$INSTALL_DIR:"*)
        echo "[ status  ] $INSTALL_DIR is already in PATH"
        ;;
    *)
        CHANGED=0
        # bash (always), zsh only when it is the login shell (macOS default)
        add_path_to_rc "$HOME/.bashrc" && CHANGED=1
        case "$SHELL" in
            */zsh) add_path_to_rc "$HOME/.zshrc" && CHANGED=1 ;;
        esac
        if [ "$CHANGED" -eq 1 ]; then
            echo "[ status  ] open a new terminal to use: $UTILITY_NAME"
        else
            echo "[ status  ] PATH is already configured in your shell rc; open a new terminal to use: $UTILITY_NAME"
        fi
        ;;
esac
