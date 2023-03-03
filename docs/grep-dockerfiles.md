# Grep Dockerfiles

The `grep-dockerfiles.sh` script gives output that describes which repositories extend which docker images.

This is done by using `find` to find all `Dockerfile`s, and `grep` to find all `FROM`, `FROM ... AS`, and `--from=` entries.

If the Dockerfile is located in a git repository and a "remote" URL has been provided, the remote repository is used as name. Otherwise, the directory name is used.

The JSON that is output is an object.
The keys are the names of the repositories.
The values are arrays of strings, where each string is a `FROM` or `--from=` entry.

For example, the following JSON describes three repositories, `acme/foo`, `acme/bar`, and `acme/baz`.

```json
{
  "git@github.com:acme/foo.git": [
    "FROM alpine:3.17",
    "COPY --from=alpine"
  ],
  "https://github.com/acme/bar": [
    "FROM acme/foo AS builder"
  ],
  "acme/baz": [
    "FROM acme/foo:latest"
  ]
}
```

The first repository uses the remote repository name, in the form of a git URL. The second repository uses the remote repository name, in the form of an HTTPS URL. The third repository uses the directory name, as an example when no remote repository is mentioned.
