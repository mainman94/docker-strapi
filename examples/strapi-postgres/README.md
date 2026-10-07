# Example: PostgreSQL

Scaffolds a new Strapi project backed by PostgreSQL and starts it. Strapi
waits for the database to pass its healthcheck before booting.

There is no default database password; compose refuses to start without one.
Set it before the first run — the scaffolded project writes it into `.env`
and will not pick up a later change:

```shell
POSTGRES_PASSWORD='choose-something-real' docker compose up
```

Then open <http://localhost:1337/admin> and create the first admin user.

Postgres is not published to the host, and Strapi's port `1337` is bound to
`127.0.0.1` only: the example runs the development server. Both the
project (`app`) and the database (`data`) live in named volumes and survive
`docker compose down`; `docker compose down -v` deletes them.
