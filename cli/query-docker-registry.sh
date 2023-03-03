#!/usr/bin/env bash

query-docker-registry() {
    local sList sOrganisation sPassword sTempDir sToken sUser

    sUser="${1?Three parameters required: <username> <password> <organisation>}"
    sPassword="${2?Three parameters required: <username> <password> <organisation>}"
    sOrganisation="${3?Three parameters required: <username> <password> <organisation>}"

    fetchList() {
        local sToken

        sToken="$(
            curl \
                -s \
                -H "Content-Type: application/json" \
                -X POST \
                -d "$(printf '{"username": "%s", "password": "%s"}' "${sUser}" "${sPassword}")" \
                'https://hub.docker.com/v2/users/login/' \
            | jq -r .token
        )"

        # @FIXME: Fetch all pages if there are more than 100 repositories.
        curl -s -H "Authorization: JWT ${sToken}" \
            "https://hub.docker.com/v2/repositories/${sOrganisation}/?page_size=100" \
        | jq -r '.results|.[] |.name'
    }

    fetchManifests() {
        local sRepositoryList sName sRemaining sTotal

        sRepositoryList="${1?One parameter required: <list>}"

        sTotal="$(echo "${sRepositoryList}" | wc -l)"
        sRemaining="${sTotal}"

        # @TODO: To save on HTTP calls, fetch the token once, with access to all repositories.
        while IFS= read -r sName; do
            sRemaining="$((sRemaining - 1))"
            echo -ne "\rFetching manifest ($((sTotal - sRemaining)) of ${sTotal}) ${sName}                    " >&2

            sToken="$(
                curl -s \
                    "https://${sUser}:${sPassword}@auth.docker.io/token?service=registry.docker.io&scope=repository:${sOrganisation}/${sName}:pull" \
                | jq -r .token
            )"

            curl \
                -s \
                -H "Authorization: Bearer ${sToken}" \
                "https://index.docker.io/v2/${sOrganisation}/${sName}/manifests/latest" \
            > "${sTempDir}/${sName}.json"
        done < <(echo "${sRepositoryList}" | sort)

        echo -ne "\r                                                                                                    \r" >&2
    }

    outputJSON() {
        local sContents sFile sMatch

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
                # The single slash trigger a false positive in shellcheck, so it
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
    sTempDir=$(mktemp -d 2>/dev/null || mktemp -d -t 'dockerhub-fetch')

    # @FIXME: Add a trap to remove ${sTempDir}.

    sList="$(fetchList)"
    fetchManifests "${sList}"
    outputJSON
}

if [[ ${BASH_SOURCE[0]} == "${0}" ]]; then
    query-docker-registry "${@}"
else
    export -f query-docker-registry
fi
