"""
Arogya-Saathi — FastAPI Application Entry Point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path
import os

from app.core.config import settings
from app.core.database import init_db, SessionLocal
from app.api.auth import router as auth_router
from app.api.patients import router as patients_router
from app.api.encounters import router as encounters_router
from app.api.clinical import router as clinical_router

app = FastAPI(
    title="Arogya-Saathi API",
    description=(
        "आरोग्य-साथी — AI-assisted clinical intake platform. "
        "Speak Naturally. Get Structured. Care Smarter. "
        "All AI outputs are labeled and require physician verification."
    ),
    version=settings.app_version,
    docs_url="/api/docs",
    redoc_url="/api/redoc",
)

# ── CORS ──────────────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins_list + ["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ───────────────────────────────────────────────────────────────────
app.include_router(auth_router, prefix="/api/v1")
app.include_router(patients_router, prefix="/api/v1")
app.include_router(encounters_router, prefix="/api/v1")
app.include_router(clinical_router, prefix="/api/v1")

# ── Static uploads ────────────────────────────────────────────────────────────
uploads_path = Path(settings.storage_local_path)
uploads_path.mkdir(parents=True, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=str(uploads_path)), name="uploads")


@app.get("/")
def root():
    return {
        "app": "Arogya-Saathi",
        "tagline": "Speak Naturally. Get Structured. Care Smarter.",
        "version": settings.app_version,
        "environment": settings.environment,
        "docs": "/api/docs",
        "status": "running",
        "note": "All AI outputs require physician verification",
    }


@app.get("/health")
def health():
    return {"status": "healthy", "service": "arogya-saathi-backend"}


# ── Startup ───────────────────────────────────────────────────────────────────
@app.on_event("startup")
def startup():
    # Initialize database tables
    init_db()

    # Seed demo data
    if settings.environment == "development":
        db = SessionLocal()
        try:
            from app.core.seed import seed_demo_data
            seed_demo_data(db)
        except Exception as e:
            print(f"Seed error (non-fatal): {e}")
        finally:
            db.close()

    print(f"🏥 Arogya-Saathi backend started — {settings.environment}")
    print(f"   API docs: http://localhost:{settings.port}/api/docs")
