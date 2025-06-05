# SoltrOS Justfile

# Image info
export repo_organization := env("GITHUB_REPOSITORY_OWNER", "soltros")
export image_name := env("IMAGE_NAME", "soltros")
export repo_image_name := lowercase(repo_organization) / lowercase(image_name)
export IMAGE_REGISTRY := "ghcr.io" / repo_image_name
export default_tag := env("DEFAULT_TAG", "latest")

# Quiet build output unless root
[private]
export SET_X := if `id -u` == "0" { "1" } else { env("SET_X", "") }

# Default: show available commands
[private]
default:
    @just --list

# ─────────────────────────────────────────────
# Build container image using Podman
# ─────────────────────────────────────────────
build $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set ${SET_X:+-x} -euo pipefail

    podman build \
        --build-arg IMAGE_NAME=${target_image} \
        --build-arg TAG_VERSION=${tag} \
        --label org.opencontainers.image.source="https://github.com/${repo_organization}/${image_name}" \
        --label org.opencontainers.image.title="${target_image}" \
        --label org.opencontainers.image.version="${tag}" \
        --tag "localhost/${target_image}:${tag}" \
        .

# ─────────────────────────────────────────────
# Push image to GHCR
# ─────────────────────────────────────────────
push $target_image=image_name $tag=default_tag:
    #!/usr/bin/env bash
    set -euo pipefail
    podman push "localhost/${target_image}:${tag}" "docker://${IMAGE_REGISTRY}:${tag}"

# ─────────────────────────────────────────────
# Flatpak List Updater
# ─────────────────────────────────────────────
update-flatpaks:
    flatpak list --columns application --app > ./repo_files/flatpaks

# ─────────────────────────────────────────────
# Just Syntax Helpers
# ─────────────────────────────────────────────
[group('Just')]
check:
    find . -type f -name "*.just" | while read -r file; do
        just --unstable --fmt --check -f "$file"
    done
    just --unstable --fmt --check -f Justfile

fix:
    find . -type f -name "*.just" | while read -r file; do
        just --unstable --fmt -f "$file"
    done
    just --unstable --fmt -f Justfile

# ─────────────────────────────────────────────
# Optional CI Tools
# ─────────────────────────────────────────────
[group('CI')]
install-cosign:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v cosign >/dev/null; then
        TMPDIR="$(mktemp -d)"
        trap 'rm -rf $TMPDIR' EXIT SIGINT
        COSIGN_CONTAINER_ID="$(podman create cgr.dev/chainguard/cosign:latest)"
        podman cp "${COSIGN_CONTAINER_ID}:/usr/bin/cosign" "$TMPDIR/cosign"
        podman rm -f "$COSIGN_CONTAINER_ID"
        install -m 0755 "$TMPDIR/cosign" /usr/local/bin/cosign
    fi

install-syft:
    #!/usr/bin/env bash
    set -euo pipefail

    if ! command -v syft >/dev/null; then
        TMPDIR="$(mktemp -d)"
        trap 'rm -rf $TMPDIR' EXIT SIGINT
        SYFT_CONTAINER_ID="$(podman create ghcr.io/anchore/syft:v1.26.1)"
        podman cp "${SYFT_CONTAINER_ID}:/syft" "$TMPDIR/syft"
        podman rm -f "$SYFT_CONTAINER_ID"
        install -m 0755 "$TMPDIR/syft" /usr/local/bin/syft
    fi

gen-sbom $input $output="": install-syft
    #!/usr/bin/env bash
    set -euo pipefail
    OUTPUT_PATH="${output:-sbom.json}"
    syft scan "$input" -o spdx-json="$OUTPUT_PATH"
    echo "SBOM written to: $OUTPUT_PATH"

