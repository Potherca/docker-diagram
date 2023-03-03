const container = document.querySelector('#container')
const form = document.querySelector('[data-form="json"]')
const plantumlForm = document.querySelector('[data-form="plantuml"]')

function parseJson(fromRepos, imageToRepoMap) {
    return {
        fromRepos,
        imageToRepoMap
    }
}

function parsePlantumlJson(plantumlJson) {
    let plantuml = `@startuml\n`
    plantuml += `@enduml\n`

    return plantuml
}

form.addEventListener('submit', event => {
    event.preventDefault()

    const fromRepos = JSON.parse(event.target.querySelector('[name="repo.json"]').value.trim())
    const imageToRepoMap = JSON.parse(event.target.querySelector('[name="hub.json"]').value.trim())

    const plantumlJson = parseJson(fromRepos, imageToRepoMap)

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
