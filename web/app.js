const container = document.querySelector('#container')
const form = document.querySelector('[data-form="json"]')
const plantumlForm = document.querySelector('[data-form="plantuml"]')

const removeDockerTag = image => image.split(':')[0];

// @FIXME: Throw error if `string` isn't string-able
const slug = string => string.replaceAll(/[^a-z0-9_]/gi, '_');

// @CHECKME: This only works for one-dimension arrays!
const uniqueArray = array => [...new Set(array)];

/**
 * There are three types of entry in `matches`:
 * 1. FROM
 * 2. FROM ... AS ...
 * 3. COPY --from=...
 *
 * The second is always the image name and the alias, but the first third can
 * contain either an image name or an alias. To make sure we only use actual
 * image names (and not aliases), we first need to grab all aliases, then grab
 * the images names, optionally replacing aliases with actual names.
 */
function extractDockerImages(matches) {
    const fromAsRegex = /from\s+(\S+)\s+as\s+([^\n\r\s]+)/
    const fromAttributeRegex = /--from=(\S+)/
    const fromRegex = /from\s+([^\n\r\s]+)/

    const aliases = {}
    let images = []

    matches.forEach(match => {
        match = match.toLowerCase()

        let from = fromRegex.exec(match);
        let fromAs = fromAsRegex.exec(match);
        let fromAttr = fromAttributeRegex.exec(match);

        if (fromAs) {
            const [, image, alias] = fromAs
            const imageName = removeDockerTag(image);
            aliases[alias] = imageName
            images.push(imageName)
        } else if (from || fromAttr) {
            const [, image] = from || fromAttr
            const imageName = removeDockerTag(image);
            images.push(imageName)
        } else {
            throw new Error(`Entry does not match any pattern: "${match}"`)
        }
    })

    /**
     * Aliases can point to another alias rather than another image
     * In that case replace the alias with the original image
     *
     * @FIXME: The current solution only works for (up to) two layers of redirection.
     */
    Object.entries(aliases).forEach(([alias, image]) => {
        if (aliases[image]) {
            aliases[alias] = aliases[image]
        }
    })

    images = images.map(image => {
        return aliases[image] || image
    })

    return uniqueArray(images).sort()
}

function createPlantUmlJson(fromRepos, imageToRepoMap) {
    const relationships = []

    for (const [repo, entries] of Object.entries(fromRepos)) {
        fromRepos[normalizeUrl(repo)] = entries
        delete fromRepos[repo]
    }

    for (const [image, repo] of Object.entries(imageToRepoMap)) {
        imageToRepoMap[image] = normalizeUrl(repo)
    }

    const repoToImageMap = {}
    Object.entries(imageToRepoMap).forEach(([image, repo]) => {
        if (repo) {
            repoToImageMap[normalizeUrl(repo)] = image
        }
    })

    Object.entries(fromRepos).forEach(([repo, entries]) => {
        repo = normalizeUrl(repo)

        let dockerImages = extractDockerImages(entries)

        dockerImages.forEach((dockerImage) => {
            let relationship = {
                from: {
                    image: repoToImageMap[repo],
                    repo: repo,
                },
                to: {
                    image: dockerImage,
                    repo: imageToRepoMap[dockerImage],
                }
            }

            relationships.push(relationship)
        })
    })

    return relationships
}

function parsePlantumlJson(plantumlJson) {
    let plantuml = `@startuml\n`
    plantuml += `@enduml\n`

    return plantuml
}

/**
 * Although an HTTP URL always contains a domain, a git URL can be in any of the
 * following formats:
 *
 *   - Repo name: `git/project`
 *   - Local Path: `/srv/git/project[.git]`
 *   - File Protocol: `file:///srv/git/project[.git]`
 *   - HTTP Protocol: `scheme://[user[:pass@]]server[:port]/git/project[.git]`
 *   - SSH Protocol: `[user@]server:project[.git]`
 *
 * This function will convert all of the above to a single format:
 *
 * - `server/project`
 *
 * @param {string} repo
 *
 * @returns {string}
 */
function normalizeUrl(repo) {
    let normalised

    // Convert SSH protocol to HTTP, so it can be handled by `URL`
    repo = repo.replace(/^git@([^:]+):/, 'https://$1/')

    try {
        // This will handle File, HTTP and SSH protocols
        const url = new URL(repo)
        const path = url.pathname.replace(/\.git$/, '') // Remove `.git` extension
        const domain = url.hostname

        normalised = `${domain}${path}`;
    } catch (e) {
        // Not a URL, either Local Path, or Repo name
        if (repo.startsWith('/')) {
            // Local Path
            normalised = repo.replace(/\.git$/, '') // Remove `.git` extension
        } else {
            // Repo name
            normalised = repo
        }
    }

    return normalised
}

form.addEventListener('submit', event => {
    event.preventDefault()

    const fromRepos = JSON.parse(event.target.querySelector('[name="repo.json"]').value.trim())
    const imageToRepoMap = JSON.parse(event.target.querySelector('[name="hub.json"]').value.trim())

    const plantumlJson = createPlantUmlJson(fromRepos, imageToRepoMap)

    document.querySelector('.result').value = JSON.stringify(plantumlJson, null, 4)
    plantumlForm.querySelector('button').attributes.removeNamedItem('disabled')
})

plantumlForm.addEventListener('submit', event => {
    event.preventDefault()

    const blob = event.target.querySelector('textarea').value.trim()
    const plantumlJson = JSON.parse(blob)

    const plantuml = parsePlantumlJson(plantumlJson)
    const diagram = compress2(plantuml);

    container.querySelector('textarea').value = plantuml
    container.insertAdjacentHTML('beforeend',
        `<a href="https://www.plantuml.com/plantuml/uml/${diagram}" target="_blank">View Diagram</a>`
    )
})
