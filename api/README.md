# Movies API

Simple CRUD API for movies (name, cast, synopsis) — FastAPI + SQLAlchemy (async) + PostgreSQL.

## Run

```bash
cp .env.example .env
make up          # docker compose up --build: api on :8000, postgres on :5432
```

Optional data seeding: replay `seed-movies.http` from OMDb.


## Endpoints

| Method | Path            | Body                          |
|--------|-----------------|--------------------------------|
| POST   | `/movies`       | `{name, cast: [...], synopsis}` |
| GET    | `/movies`       | query: `skip`, `limit`         |
| GET    | `/movies/{id}`  | —                               |
| PUT    | `/movies/{id}`  | `{name, cast: [...], synopsis}` |
| DELETE | `/movies/{id}`  | —                               |
| GET    | `/healthz`      | —                               |
