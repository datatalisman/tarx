#!/bin/bash
# Unit tests for tarx (../src/tarx)
# Run:  ./UT/test_tarx.sh      (or: bash UT/test_tarx.sh)
# Exit code 0 = all tests passed, 1 = at least one test failed.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TARX="$(cd "$SCRIPT_DIR/../src" && pwd -P)/tarx"

chmod +x $TARX

if [ ! -x "$TARX" ]; then
    echo "[ error ] tarx not found or not executable: $TARX"
    exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/tarx_ut.XXXXXX")" || exit 1
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0
OUT=""
RC=0

pass() { PASS=$((PASS + 1)); echo "  [ PASS ] $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  [ FAIL ] $1"; [ -n "${2:-}" ] && echo "           $2"; }

check() {   # check <name> <command...>   passes when the command succeeds
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then pass "$name"; else fail "$name"; fi
}

check_not() {   # check_not <name> <command...>   passes when the command fails
    local name="$1"; shift
    if "$@" >/dev/null 2>&1; then fail "$name"; else pass "$name"; fi
}

check_rc() {    # check_rc <name> <expected_rc>   uses last RC
    if [ "$RC" -eq "$2" ]; then pass "$1"; else fail "$1" "expected rc=$2, got rc=$RC. output: $OUT"; fi
}

check_rc_nonzero() {
    if [ "$RC" -ne 0 ]; then pass "$1"; else fail "$1" "expected non-zero rc, got 0. output: $OUT"; fi
}

check_out_has() {   # check_out_has <name> <text>
    case "$OUT" in
        *"$2"*) pass "$1" ;;
        *) fail "$1" "output does not contain: $2 | output: $OUT" ;;
    esac
}

run() { OUT="$("$@" 2>&1)"; RC=$?; }

new_case() {    # fresh empty working directory for each test group
    CASE="$WORK/$1"
    rm -rf "$CASE"
    mkdir -p "$CASE"
    cd "$CASE" || exit 1
}

make_sample() { # make_sample <dir>   creates a small tree with awkward content
    local d="$1"
    mkdir -p "$d/sub/deeper" "$d/empty_dir" "$d/dir with space"
    echo "hello" > "$d/a.txt"
    echo "nested" > "$d/sub/deeper/b.txt"
    echo "spaced" > "$d/dir with space/file with space.txt"
    # a text file that contains the payload marker line
    printf 'line1\n__TARX_PAYLOAD__\nline3\n' > "$d/marker.txt"
    # binary data
    head -c 20000 /dev/urandom > "$d/random.bin"
    # executable file keeps its mode
    printf '#!/bin/sh\necho ok\n' > "$d/run.sh"
    chmod 755 "$d/run.sh"
}

same_tree() {   # same_tree <dirA> <dirB>
    diff -r "$1" "$2" >/dev/null 2>&1
}

echo "tarx under test: $TARX"
echo

# ------------------------------------------------------------------
echo "== packing: basic =="
new_case basic
make_sample test
mkdir private_tmp
TMPDIR="$CASE/private_tmp" run "$TARX" test
check_rc "pack 'test' succeeds" 0
check "creates test.tar.sh" test -f test.tar.sh
check "test.tar.sh is executable" test -x test.tar.sh
check "output starts with a bash shebang" bash -c 'head -n1 test.tar.sh | grep -q "^#!/bin/bash"'
check "source directory is untouched" test -f test/a.txt
check_out_has "prints the created file name" "test.tar.sh"
check "no stray temp files left behind" bash -c '[ -z "$(ls -A private_tmp)" ]'

# ------------------------------------------------------------------
echo "== extracting: round trip =="
new_case roundtrip
make_sample src_data
run "$TARX" src_data
mkdir out && cd out || exit 1
run ../src_data.tar.sh
check_rc "extract succeeds" 0
check "extracted tree is identical to the original" same_tree ../src_data src_data
check "executable bit is preserved" test -x src_data/run.sh
check "empty directory is preserved" test -d src_data/empty_dir
check "file containing the marker line survives" same_tree ../src_data/marker.txt src_data/marker.txt
check "binary file is identical" cmp -s ../src_data/random.bin src_data/random.bin

# ------------------------------------------------------------------
echo "== archive stores only the directory name (no full path) =="
new_case names
mkdir -p deep/er/proj && echo x > deep/er/proj/f.txt
run "$TARX" "$CASE/deep/er/proj"
check_rc "pack with absolute path succeeds" 0
check "named after last path component" test -f proj.tar.sh
mkdir out && cd out || exit 1
run ../proj.tar.sh
check "extracts as ./proj, not the full path" test -f proj/f.txt
check_not "no 'deep' directory is created" test -e deep
cd "$CASE" || exit 1
rm -f proj.tar.sh
run "$TARX" deep/er/proj/
check_rc "pack with trailing slash succeeds" 0
check "trailing slash still gives proj.tar.sh" test -f proj.tar.sh
rm -f proj.tar.sh
run "$TARX" ./deep/er/proj
check "relative ./path works" test -f proj.tar.sh

# ------------------------------------------------------------------
echo "== names with spaces =="
new_case spaces
mkdir "my test" && echo s > "my test/f.txt"
run "$TARX" "my test"
check_rc "pack 'my test' succeeds" 0
check "creates 'my test.tar.sh'" test -f "my test.tar.sh"
mkdir out && cd out || exit 1
run "../my test.tar.sh"
check_rc "extract of 'my test' succeeds" 0
check "content restored" test -f "my test/f.txt"
cd "$CASE" || exit 1
run "$TARX" "my test"
check_rc_nonzero "second pack of 'my test' is refused"
# directory name with a single quote and dollar sign
mkdir "it's \$home" && echo q > "it's \$home/f.txt"
run "$TARX" "it's \$home"
check_rc "pack name with quote and dollar succeeds" 0
mkdir out2 && cd out2 || exit 1
run "../it's \$home.tar.sh"
check_rc "extract name with quote and dollar succeeds" 0
check "content restored" test -f "it's \$home/f.txt"

# ------------------------------------------------------------------
echo "== packing: invalid usage =="
new_case usage
mkdir test && echo x > test/f.txt
run "$TARX"
check_rc_nonzero "no arguments is rejected"
check "no arguments creates no file" bash -c '[ -z "$(ls -A | grep tar.sh)" ]'
run "$TARX" .
check_rc_nonzero "'.' is rejected"
run "$TARX" "*"
check_rc_nonzero "'*' is rejected"
run "$TARX" test other
check_rc_nonzero "two arguments are rejected"
run "$TARX" does_not_exist
check_rc_nonzero "missing directory is rejected"
check_out_has "missing directory message" "not a directory"
echo "i am a file" > plainfile
run "$TARX" plainfile
check_rc_nonzero "a regular file is rejected"
run "$TARX" /
check_rc_nonzero "'/' is rejected"
run "$TARX" -h
check_rc "-h exits 0" 0
check_out_has "-h prints usage" "Usage"
check "none of the invalid calls created a .tar.sh" bash -c '! ls *.tar.sh >/dev/null 2>&1'

# ------------------------------------------------------------------
echo "== packing: never inside the packed directory =="
new_case inside
mkdir -p test/sub && echo x > test/sub/f.txt
cd test || exit 1
run "$TARX" ../test
check_rc_nonzero "packing the directory you are standing in is rejected"
check "no output file inside the directory" bash -c '! ls *.tar.sh >/dev/null 2>&1'
cd sub || exit 1
run "$TARX" ../../test
check_rc_nonzero "packing an ancestor of the current directory is rejected"
check "no output file in the subdirectory" bash -c '! ls *.tar.sh >/dev/null 2>&1'
cd "$CASE" || exit 1
run "$TARX" test/sub
check_rc "packing a subdirectory from the parent is fine" 0
check "sub.tar.sh created in current directory" test -f sub.tar.sh

# ------------------------------------------------------------------
echo "== packing: never overwrites =="
new_case nooverwrite
mkdir test && echo x > test/f.txt
echo "precious" > test.tar.sh
run "$TARX" test
check_rc_nonzero "existing test.tar.sh blocks packing"
check_out_has "message says it already exists" "already exists"
check "existing file content is unchanged" bash -c '[ "$(cat test.tar.sh)" = "precious" ]'
rm -f test.tar.sh
ln -s /nonexistent test.tar.sh
run "$TARX" test
check_rc_nonzero "a dangling symlink with that name also blocks packing"
check "symlink is untouched" test -L test.tar.sh
rm -f test.tar.sh

# ------------------------------------------------------------------
echo "== extracting: never overwrites =="
new_case noextract
mkdir test && echo original > test/a.txt
run "$TARX" test
mkdir out && cd out || exit 1
mkdir test && echo "users data" > test/a.txt && echo "other" > test/keep.txt
run ../test.tar.sh
check_rc_nonzero "extract aborts when the directory already exists"
check_out_has "message says it already exists" "already exists"
check "existing file is not overwritten" bash -c '[ "$(cat test/a.txt)" = "users data" ]'
check "other files are untouched" bash -c '[ "$(cat test/keep.txt)" = "other" ]'
cd "$CASE" || exit 1
rm -rf out && mkdir out && cd out || exit 1
echo "i am a file called test" > test
run ../test.tar.sh
check_rc_nonzero "extract aborts when a FILE with that name exists"
check "that file is untouched" bash -c '[ "$(cat test)" = "i am a file called test" ]'
cd "$CASE" || exit 1
rm -rf out && mkdir out && cd out || exit 1
ln -s /tmp test
run ../test.tar.sh
check_rc_nonzero "extract aborts when a symlink with that name exists"
check "symlink is untouched" test -L test
cd "$CASE" || exit 1
check "the original source directory was never touched" bash -c '[ "$(cat test/a.txt)" = "original" ]'

# ------------------------------------------------------------------
echo "== extracting: destination argument =="
new_case dest
mkdir test && echo d > test/a.txt
run "$TARX" test
run ./test.tar.sh "$CASE/target/path"
check_rc "extract into a new destination succeeds" 0
check "destination is created and filled" test -f "$CASE/target/path/test/a.txt"
run ./test.tar.sh "$CASE/target/path"
check_rc_nonzero "second extract to the same destination is refused"
check "first extraction is intact" bash -c '[ "$(cat "'"$CASE"'/target/path/test/a.txt")" = "d" ]'
mkdir other_dest
run ./test.tar.sh other_dest
check_rc "extract into an existing empty destination succeeds" 0
check "files are inside destination" test -f other_dest/test/a.txt
check_not "nothing leaked into the current directory" test -e "$CASE/a.txt"

# ------------------------------------------------------------------
echo "== extract script can be run from anywhere =="
new_case anywhere
mkdir test && echo w > test/a.txt
run "$TARX" test
mkdir elsewhere && cd elsewhere || exit 1
run bash ../test.tar.sh
check_rc "run through 'bash script' works" 0
check "extracted next to where it was run" test -f test/a.txt
cd "$CASE" || exit 1
mkdir via_abs && cd via_abs || exit 1
run "$CASE/test.tar.sh"
check_rc "run through absolute path works" 0
check "extracted into current directory" test -f test/a.txt

# ------------------------------------------------------------------
echo "== larger content and empty directory =="
new_case big
mkdir bigdir && head -c 3000000 /dev/urandom > bigdir/big.bin
run "$TARX" bigdir
mkdir out && cd out || exit 1
run ../bigdir.tar.sh
check_rc "3 MB random file round trip succeeds" 0
check "3 MB file is identical" cmp -s ../bigdir/big.bin bigdir/big.bin
cd "$CASE" || exit 1
mkdir emptydir
run "$TARX" emptydir
check_rc "packing an empty directory succeeds" 0
mkdir out2 && cd out2 || exit 1
run ../emptydir.tar.sh
check_rc "extracting an empty directory succeeds" 0
check "empty directory is recreated" test -d emptydir

# ------------------------------------------------------------------
echo
echo "Result: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
