# tarx

**Turn a directory into one self-extracting script (`NAME.tar.sh`).**

`tarx` packs a directory into a compressed tar archive and embeds it in a Bash script. Copy that single file to another Linux/macOS machine, run it, and the directory is recreated. Useful for installers: data and instructions travel in one executable file.

Requirements: `bash`, `tar`, `gzip`, `awk`, `tail` (all standard on Linux/macOS).

## Usage

```bash
tarx <directory>
```

```bash
tarx test        # creates test.tar.sh in the current directory
```

- The output is always named `<directory name>.tar.sh` and is written to the current directory.
- `tarx .`, `tarx` without arguments and wildcards are not supported. Run `tarx` from the parent directory, so the new `.tar.sh` never ends up inside the directory it contains.
- If `test.tar.sh` already exists, `tarx` aborts. It never overwrites.

## Extract

```bash
./test.tar.sh              # extracts ./test in the current directory
./test.tar.sh /some/path   # extracts into /some/path
```

- If a `test` directory (or file) already exists at the destination, the script aborts with a message and extracts nothing. It never overwrites your data.


## Install

### Option 1: Homebrew (Recommended)

Install using Homebrew on Linux or macOS.

```
brew install datatalisman/tap/tarx
```

### Option 2: Quick Install

Install directly from GitHub without cloning the repository.

```
curl -fsSL https://raw.githubusercontent.com/datatalisman/tarx/master/install.sh | bash
```

No sudo needed. `tarx` is installed to `~/.local/bin`.

The installer adds `~/.local/bin` to your `PATH` automatically if it is not already present. It updates `~/.bashrc` (and `~/.zshrc` when zsh is your shell) without duplicating an existing entry.

Open a new terminal after installation if `~/.local/bin` was added to your `PATH`.

### Option 3: Clone and Install

Clone the repository and run the installer locally.

```
git clone https://github.com/datatalisman/tarx.git
cd tarx
chmod +x install.sh
./install.sh
```

No sudo needed. `tarx` is installed to `~/.local/bin`.

The installer automatically configures your PATH if necessary. Open a new terminal afterwards.

### Uninstall

**Homebrew:**

```
brew uninstall tarx
```

**Manual installation:**

```
chmod +x uninstall.sh
./uninstall.sh
```

The uninstaller removes only `tarx`. Your `PATH` configuration remains unchanged.



## Unit Tests (UT)

Clone the repository and navigate to the UT folder.

```bash
cd ut
chmod +x test_tarx.sh
./test_tarx.sh
```

The script runs the unit tests for `tarx`.

