#!/bin/zsh
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"

DEFAULT_DIRS=(
    "${repo_root}/build/apps/kuclaw-desktop/Kuclaw/app"
    "${repo_root}/build/apps/kuclaw-desktop/Kuclaw.app/Contents/Resources/qml/Kuclaw/app"
)

dirs=()
if [[ $# -gt 0 ]]; then
    dirs=("$@")
else
    dirs=("${DEFAULT_DIRS[@]}")
fi

missing=0

for resource in "AutomationSectionStyles.js" "WorkspaceSelection.js" "TitleBarLayout.js"; do
    found=0
    for dir in "${dirs[@]}"; do
        if [[ -f "${dir}/${resource}" ]]; then
            found=1
            break
        fi
    done

    if [[ "${found}" -eq 0 ]]; then
        echo "Missing bundled QML resource: ${resource}" >&2
        printf 'Checked paths:\n' >&2
        for dir in "${dirs[@]}"; do
            printf '  - %s\n' "${dir}/${resource}" >&2
        done
        missing=1
    fi
done

exit "${missing}"
