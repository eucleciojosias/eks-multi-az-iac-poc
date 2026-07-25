# Movies API

Simple CRUD API for movies (name, cast, synopsis) — FastAPI + SQLAlchemy (async) +
PostgreSQL. A PoC: run locally now, point `DATABASE_URL` at Amazon RDS later with no
code change.

## Run

```bash
cp .env.example .env
make up          # docker compose up --build: api on :8000, postgres on :5432
```

Docs at `http://localhost:8000/docs`. `make down` to stop.

Optional data seeding from OMDb: see [`scripts/`](scripts/seed_movies.py).

## Endpoints

| Method | Path            | Body                          |
|--------|-----------------|--------------------------------|
| POST   | `/movies`       | `{name, cast: [...], synopsis}` |
| GET    | `/movies`       | query: `skip`, `limit`         |
| GET    | `/movies/{id}`  | —                               |
| PUT    | `/movies/{id}`  | `{name, cast: [...], synopsis}` |
| DELETE | `/movies/{id}`  | —                               |
| GET    | `/healthz`      | —                               |

## Notes

- Schema is created on startup (`Base.metadata.create_all`) — no migration step yet.
  Add Alembic before pointing this at a real database (RDS or otherwise).
- `make lint` / `make fmt` — ruff. No test suite (PoC).
- The image built here (`make build` / the `Dockerfile`) is the same one meant for
