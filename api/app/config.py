from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = "movies-api"
    environment: str = "local"
    log_level: str = "INFO"
    database_url: str = "postgresql+asyncpg://movies:movies@localhost:5432/movies"


settings = Settings()
