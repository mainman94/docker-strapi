# Example: PostgreSQL

Scaffolds a new Strapi project backed by PostgreSQL and starts it. Strapi
waits for the database to pass its healthcheck before booting.

```shell
docker compose up
```

Then open <http://localhost:1337/admin> and create the first admin user.

The database password defaults to `strapi`. Override it before the first run —
the scaffolded project writes it into `.env` and will not pick up a later
change:

```shell
POSTGRES_PASSWORD='choose-something-real' docker compose up
```

Postgres is not published to the host; only Strapi's port `1337` is. Both the
project (`app`) and the database (`data`) live in named volumes and survive
`docker compose down`; `docker compose down -v` deletes them.
