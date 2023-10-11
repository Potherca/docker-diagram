#!/usr/bin/env bash

# ==============================================================================
# Mozilla Public License Version 2.0
#
# Copyright (C) 2023 Potherca
#
# This Source Code Form is subject to the terms of the Mozilla Public License,
# v. 2.0. If a copy of the MPL was not distributed with this file, You can
# obtain one at https://mozilla.org/MPL/2.0/.
# ==============================================================================
# There are a few standards this code tries to adhere to, these are listed below.
#
# - Code follows the BASH style-guide described at:
#   http://guides.dealerdirect.io/code-styling/bash/
#
# - Variables are named using an adaption of Systems Hungarian explained at:
#   http://blog.pother.ca/VariableNamingConvention
#
# ==============================================================================

set -o errexit  # Exit script when a command exits with non-zero status.
set -o errtrace # Exit on error inside any functions or sub-shells.
set -o nounset  # Exit script on use of an undefined variable.
set -o pipefail # Return exit status of the last command in the pipe that exited with a non-zero exit code

# ==============================================================================
#               List which Docker images come from which Repositories
# ------------------------------------------------------------------------------
## This script fetches a list of available docker repositories from a docker
## registry. This list is then used to fetch the manifest for all images in the
## registry. (These manifests are stored in temporary files)
##
## Currently, the script only works for Docker Hub, and the Docker Hub API. It
## has been hard-coded to use hub.docker.com, auth.docker.io, and index.docker.io
##
## Usage: $0 <username> <password> <organization>
##
## Where:
##       - <username> is the username of the user to authenticate with.
##       - <password> is the password of the user to authenticate with.
##       - <organization> is the organization to fetch the repositories for.
##
## Usage example:
##
##   bash query-docker-registry.sh 'peter-gibbons' '7$aRJFHbSo93e5@Z' 'initech'
##
## The script requires the following tools to be installed:
##
## - curl
## - jq
##
## The cUrl and jq executable can be overridden by setting their respective
## environmental variable before calling this script:
##
##        CURL=/usr/local/curl JQ=/usr/local/jq $0 <username> <password> <organization>
##
## The script will create the following files:
##
## - ${TEMP_DIR}/<repository-name>.json

usage() {
    local sScript sUsage

    sScript="$(basename "$0")"
    sUsage="$(grep '^##' < "$0" | cut -c4-)"

    readonly sScript
    readonly sUsage

    echo -e "${sUsage//\$0/${sScript}}"
}

query-docker-registry() {
    local sList sOrganisation sPassword sTempDir sToken sUser

    sUser="${1?Three parameters required: <username> <password> <organisation>}"
    sPassword="${2?Three parameters required: <username> <password> <organisation>}"
    sOrganisation="${3?Three parameters required: <username> <password> <organisation>}"

    call-url() {
        local sPaginationUrl sPrevious sUrl sResponse sResult sToken

        readonly sUrl="${1?Two parameter required: <url> <token> [previous-content]}"
        readonly sToken="${2?Two parameter required: <url> <token> [previous-content]}"
        readonly sPrevious="${3:-''}"

        sResponse=$(curl -s -H "Authorization: JWT ${sToken}" "${sUrl}")
        readonly sResponse

        sPaginationUrl="$(echo "${sResponse}" | jq -r '.next')"
        readonly sPaginationUrl

        sResult=$(echo "${sResponse}" | jq -r '.results|.[] |.name')
        readonly sResult

        if [[ ${sPaginationUrl} == 'null' ]]; then
            printf '%s\n%s' "${sPrevious}" "${sResult}"
        else
            call-url "${sPaginationUrl}" "${sToken}" "${sResult}"
        fi
    }

    fetchList() {
        local sUser sPassword sOrganisation sUrl

        readonly sUser="${1?Three parameters required: <username> <password> <organization>}"
        readonly sPassword="${2?Three parameters required: <username> <password> <organization>}"
        readonly sOrganisation="${3?Three parameters required: <username> <password> <organization>}"

        readonly sUrl="https://hub.docker.com/v2/repositories/${sOrganisation}/?page_size=100"

        sToken="$(fetchRegistryToken "${sUser}" "${sPassword}")"
        readonly sToken

        call-url "${sUrl}" "${sToken}"
    }

    fetchManifests() {
        local sRepositoryList sName sRemaining sTempDir sToken sTotal

        readonly sTempDir="${1?Two parameters required: <temp-dir> <list>}"
        readonly sRepositoryList="${2?Two parameters required: <temp-dir> <list>}"

        sTotal="$(echo "${sRepositoryList}" | wc -l)"
        sRemaining="${sTotal}"

        # @TODO: To save on HTTP calls, fetch the token once, with access to all repositories.
        while IFS= read -r sName; do
            sRemaining="$((sRemaining - 1))"
            echo -ne "\rFetching manifest ($((sTotal - sRemaining)) of ${sTotal}) ${sName}                    " >&2

            sToken="$(
                curl -s \
                    "https://${sUser}:${sPassword}@auth.docker.io/token?service=registry.docker.io&scope=repository:${sOrganisation}/${sName}:pull" \
                | jq -r '.token'
            )"

            curl \
                --header "Authorization: Bearer ${sToken}" \
                --silent \
                "https://index.docker.io/v2/${sOrganisation}/${sName}/manifests/latest" \
            > "${sTempDir}/${sName}.json"
        done < <(echo "${sRepositoryList}" | sort)

        echo -ne "\r                                                                                                    \r" >&2
    }

    fetchRegistryToken() {
        local sUser sPassword

        sUser="${1?Two parameters required: <username> <password>}"
        sPassword="${2?Two parameters required: <username> <password>}"

        curl \
            --data "$(printf '{"username": "%s", "password": "%s"}' "${sUser}" "${sPassword}")" \
            --header "Content-Type: application/json" \
            --request POST \
            --silent \
            'https://hub.docker.com/v2/users/login/' \
            | jq -r '.token'
    }

    outputJSON() {
        local sContents sFile sMatch sTempDir

        sTempDir="${1?One parameter required: <temp-dir>}"

        sContents=''

        for sFile in "${sTempDir}/"*.json; do
            sMatch="$(
                # "tr" can only be piped to. Redirection could be used, but that
                # would look weird to less experienced developers, because of the
                # line starting with `<` and the fact that the redirection is
                # done from a variable:
                #
                # < "${sFile}" tr -d '\\' \
                #
                # So instead `cat` is used, even thought this triggers shellcheck.
                #
                # The single slash triggers a false positive in shellcheck, so it
                # is disabled for the line.
                #
                # See https://github.com/koalaman/shellcheck/issues/2639
                #
                # shellcheck disable=SC2002
                # shellcheck disable=SC1003
                cat "${sFile}" \
                    | tr -d '\\' \
                    | grep -oE 'org.opencontainers.image.source":"[^"]+"' \
                    | cut -d'"' -f3
            )"
            sContents+="$(printf '\n\t"%s":"%s",' "${sOrganisation}/$(basename "${sFile}" '.json')" "${sMatch}")"
        done

        printf "{%s\n}\n" "${sContents:0:-1}" # Remove trailing comma
    }

    # Cross-platform way to create a temporary directory.
    sTempDir=$(mktemp -d 2> /dev/null || mktemp -d -t 'dockerhub-fetch')
    readonly sTempDir

    # @FIXME: Add a trap to remove ${sTempDir}.

    sList="$(fetchList "${sUser}" "${sPassword}" "${sOrganisation}")"
    fetchManifests "${sTempDir}" "${sList}"
    outputJSON "${sTempDir}"
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
    query-docker-registry "${@:-}"
else
    export -f query-docker-registry
fi
