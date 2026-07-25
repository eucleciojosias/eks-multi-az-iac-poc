"""Fetch movies from the OMDb API and create them via the running movies API.

This is an isolated utility project (own pyproject.toml/uv.lock/.venv) — it is not
a dependency of the api itself. Run from within this scripts/ directory:

    uv run seed_movies.py                       # seeds DEFAULT_TITLES
    uv run seed_movies.py "Titanic" "Se7en"      # seeds specific titles

Requires OMDB_API_KEY (free key: https://www.omdbapi.com/apikey.aspx) in the
environment or in scripts/.env. Assumes the API is already running (`make up`
from api/).
"""

import os
import sys

import httpx
from dotenv import load_dotenv

load_dotenv()

OMDB_URL = "https://www.omdbapi.com/"
OMDB_API_KEY = os.environ.get("OMDB_API_KEY")
API_BASE_URL = os.environ.get("API_BASE_URL", "http://localhost:8000")

DEFAULT_TITLES = [
    "The Matrix",
    "Inception",
    "The Godfather",
    "Pulp Fiction",
    "The Shawshank Redemption",
    "Interstellar",
    "Fight Club",
    "The Dark Knight",
    "Forrest Gump",
    "Parasite",
    "Spirited Away",
    "The Lord of the Rings: The Fellowship of the Ring",
]


def _clean(value: str) -> str:
    return "" if value == "N/A" else value


def fetch_movie(client: httpx.Client, title: str) -> dict | None:
    response = client.get(OMDB_URL, params={"apikey": OMDB_API_KEY, "t": title})
    response.raise_for_status()
    data = response.json()
    if data.get("Response") != "True":
        print(f"  skip {title!r}: {data.get('Error', 'unknown error')}")
        return None

    actors = _clean(data.get("Actors", ""))
    return {
        "name": data["Title"],
        "cast": [a.strip() for a in actors.split(",") if a.strip()],
        "synopsis": _clean(data.get("Plot", "")),
    }


def create_movie(client: httpx.Client, movie: dict) -> None:
    response = client.post(f"{API_BASE_URL}/movies", json=movie)
    response.raise_for_status()


def main(titles: list[str]) -> None:
    if not OMDB_API_KEY:
        sys.exit("OMDB_API_KEY is not set (get a free key at https://www.omdbapi.com/apikey.aspx)")

    with httpx.Client(timeout=10) as client:
        for title in titles:
            print(f"fetching {title!r}...")
            try:
                movie = fetch_movie(client, title)
                if movie is None:
                    continue
                create_movie(client, movie)
            except httpx.HTTPError as exc:
                print(f"  failed: {exc}")
                continue
            print(f"  created {movie['name']!r} ({len(movie['cast'])} cast members)")


if __name__ == "__main__":
    main(sys.argv[1:] or DEFAULT_TITLES)
