# Example: SQLite

Scaffolds a new Strapi project backed by SQLite and starts it.

```shell
docker compose up
```

Then open <http://localhost:1337/admin> and create the first admin user.

The project lives in the named volume `app`, so it survives
`docker compose down`. To keep it on the host instead, swap the volume for a
bind mount:

```yaml
    volumes:
      - ./app:/srv/app
```

With a bind mount, make sure the host directory is writable by the container
user (the alpine image runs as non-root `appuser`) — either `chown` it or pin
the container to your own UID with `user: "1000:1000"`.

Tear down, keeping the project:

```shell
docker compose down
```

Tear down and delete it:

```shell
docker compose down -v
```
