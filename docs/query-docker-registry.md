# Docker Registry API

The `query-docker-registry.sh` script gives output that describes which docker images come from which repositories.

This is done by fetching a list of images for an organisation from the Docker Registry API, and then fetching the JSON data for each image. The `org.opencontainers.image.source` label is use to find which repository an image comes from.

The JSON that is output is an object with key/value pairs.
The keys are the names of the docker image.
The values are the URLs of the repositories that the images come from.

For example, the following JSON describes three docker images, `acme/foo`, `acme/bar` and `acme/baz`, and the repository they come from.

```json
{
  "acme/foo": "git@github.com:acme/foo.git",
  "acme/bar": "https://github.com/acme/bar",
  "acme/baz": ""
}
```

The first repository uses the remote repository name, in the form of a git URL. The second repository uses the remote repository name, in the form of an HTTPS URL. The third repository is an example when no label is available.
