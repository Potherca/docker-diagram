#!/usr/bin/env bash

: "${GIT:=git}"

grep-dockerfiles() {
    local sContents sFile sFind sIgnore sLines sPath sRepository sRepoPath

    sPath="${1?One parameter required: <path> [ignore]}"
    sIgnore="${2:-\0}"

    # Remove trailing slash `/` form sPath
    readonly sPath="${sPath%/}"

    sContents=''
    for sFile in $(find "${sPath}" -type f -name Dockerfile | grep -vE "${sIgnore}"); do
        sLines=''
        while read -r sFind; do
            # Add sFind to sLines
            # Strip carriage returns
            sFind=${sFind%$'\r'}
            sLines+="\"${sFind}\","
        done <<<"$(grep -iP '^FROM ([^\n\r\s]+)(?:\s+AS\s+([^\n\r\s]+))?|--from=([^\s]+)' "${sFile}")"

        # Remove trailing comma
        sLines="${sLines:0:-1}"

        # The sFile contains the full path to the Dockerfile, but we only want the root path
        sRepoPath="${sFile%/*}"

        sRepository=$("${GIT}" -C "${sRepoPath}" config remote.origin.url)

        if [[ -z ${sRepository} ]]; then
            sRepository="${sRepoPath}"
        fi

        sContents+="$(printf '\n\t"%s":[%s],' "${sRepository}" "${sLines}")"
    done

    printf "{%s\n}\n" "${sContents:0:-1}" # Remove trailing comma
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
    grep-dockerfiles "${@}"
else
    export -f grep-dockerfiles
fi
