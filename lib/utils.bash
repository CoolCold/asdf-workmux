#!/usr/bin/env bash

[[ -n "${_UTILS_BASH_:-}" ]] && return 0
export _UTILS_BASH_=1

get_arch() {
	local arch
	arch=$(uname -m | tr '[:upper:]' '[:lower:]')
	case "$arch" in
	x86_64) echo "amd64" ;;
	aarch64) echo "arm64" ;;
	*) echo "$arch" ;;
	esac
}

get_platform() {
	uname | tr '[:upper:]' '[:lower:]'
}

get_download_url() {
	local version="$1"
	local platform arch
	platform=$(get_platform)
	arch=$(get_arch)

	case "$version" in
	v*) ;;
	*) version="v${version}" ;;
	esac

	echo "https://github.com/raine/workmux/releases/download/${version}/workmux-${platform}-${arch}.tar.gz"
}
