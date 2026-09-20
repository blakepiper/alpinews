#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
cat > "$tmp/zig" <<'MOCK'
#!/bin/sh
printf '<%s>\n' "$@"
MOCK
chmod +x "$tmp/zig"
export PATH="$tmp:$PATH"
for compiler in cc c++; do
    sh "$ROOT/bin/$compiler" --target=x86_64-alpine-linux-musl -I 'path with spaces' '' -target x86_64-alpine-linux-musl -o result > "$tmp/actual"
    printf '<%s>\n' "$compiler" --target=x86_64-linux-musl -I 'path with spaces' '' -target x86_64-linux-musl -o result > "$tmp/expected"
    cmp "$tmp/expected" "$tmp/actual"
    sh "$ROOT/bin/$compiler" --target=aarch64-linux-musl -c source.c > "$tmp/actual"
    printf '<%s>\n' "$compiler" --target=aarch64-linux-musl -c source.c > "$tmp/expected"
    cmp "$tmp/expected" "$tmp/actual"
done
printf 'PASS: compiler target normalization, other targets, empty arguments and quoting.\n'
