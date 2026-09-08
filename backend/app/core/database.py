"""
Arogya-Saathi — Database Engine (SQLite / SQLAlchemy)
"""
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, DeclarativeBase
from app.core.config import settings

# SQLite connect_args needed for multithreading
connect_args = {}
if settings.database_url.startswith("sqlite"):
    connect_args = {"check_same_thread": False}

engine = create_engine(
    settings.database_url,
    connect_args=connect_args,
    echo=settings.debug,
)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


class Base(DeclarativeBase):
    pass


def get_db():
    """FastAPI dependency: yields a database session."""
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()


def init_db():
    """Create all tables. Called at startup."""
    from app.models import (  # noqa: F401 - import all models to register with Base
        user, patient, encounter, interview, clinical_finding,
        document, timeline, red_flag, ayush,
        diagnosis, fhir_resource
    )
    Base.metadata.create_all(bind=engine)
