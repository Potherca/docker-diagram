# Docker Diagram

[![Project stage: Development][project-stage-badge: Development]][project-stage-page]
![Maintained][maintained-shield]
[![standard-readme compliant][standard-readme-shield]][standard-readme-link]

_Create a dependency diagram of your docker images_

> _"Be able to read blueprints, diagrams, floorplans, and other diagrams used in the construction process."_ ~ Marilyn vos Savant

When creating docker containers, it is not uncommon to have several low-level "base" images, which higher-level images are built from.

It would be nice to see which images extend which. This project aims to do that.

## Background

There are two ways to create a diagram of which docker image extends which.

1. `grep` Dockerfiles to find `FROM` and `--from` entries
2. Read from Docker Registry API and use Image Labels

With the first method, the name of the repository is known, but not the name of the image.
With the second method, the name of the image is known, but not the name of the repository.

Combining both methods yields a result in which both are available.

## Install

Download the BASH scripts in `cli/` so they can run locally.
This can be done by cloning the repository, or by downloading the scripts individually.

## Usage

Gathering the required data and creating the diagram, have been split into separate steps. The scripts in `cli/` are meant to be run locally.
They gather the required data and output it as JSON files.
The web application in `web/` is meant to be run in a browser and takes the JSON files as input.

In order to create a diagram, the following steps need to be taken:

1. Run the `docker-grep.sh` script to create a JSON file with the results of `grep`ing all `Dockerfile`s in a group of repositories.
2. Run the `dockerhub-fetch.sh` script to create a JSON file with the results of querying the Docker Registry API.
3. Visit `web/index.html` in a browser and input the two JSON files.
4. View the resulting diagram.

Optionally, the JSON and diagram code can be manually edited to make corrections or add additional information.

## Contributing

Please report any issues or feedback by [opening an issue](https://github.com/Potherca/docker-diagram/issues) or reaching out to [@potherca](https://twitter.com/potherca) in Twitter.

### Development

```
    .
    ├── cli/        <- Scripts to run the application
    ├── docs/       <- Documentation
    ├── web/        <- Web application
    └── README.md   <- This file
```

## License

This project is created by [Potherca](https://pother.ca) licensed under an [MPL-2.0 License](LICENSE).

[maintained-shield]: https://img.shields.io/maintenance/yes/2023.svg
[project-stage-badge: Development]: https://img.shields.io/badge/Project%20Stage-Development-yellowgreen.svg
[project-stage-page]: https://blog.pother.ca/project-stages/
[standard-readme-link]: https://github.com/RichardLitt/standard-readme
[standard-readme-shield]: https://img.shields.io/badge/-Standard%20Readme-brightgreen.svg
