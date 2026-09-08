"""
Arogya-Saathi — Patient API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import date

from app.core.database import get_db
from app.models.patient import Patient
from app.models.encounter import Encounter, EncounterStatus
from app.models.timeline import TimelineEvent
from app.models.clinical_finding import MedicalHistory
from app.auth.dependencies import get_current_user, require_physician
from app.models.user import User

router = APIRouter(prefix="/patients", tags=["Patients"])


class PatientCreate(BaseModel):
    name: str
    age: Optional[str] = None
    dob: Optional[date] = None
    gender: Optional[str] = None
    mobile: Optional[str] = None
    abha_number: Optional[str] = None
    emergency_contact_name: Optional[str] = None
    emergency_contact_phone: Optional[str] = None
    preferred_language: str = "en"


class PatientOut(BaseModel):
    id: str
    name: str
    age: Optional[str]
    gender: Optional[str]
    mobile: Optional[str]
    abha_number: Optional[str]
    preferred_language: str

    class Config:
        from_attributes = True


@router.post("", response_model=PatientOut, status_code=status.HTTP_201_CREATED)
def create_patient(payload: PatientCreate, db: Session = Depends(get_db)):
    """Create a new patient (called during intake — no auth required)."""
    patient = Patient(**payload.model_dump())
    db.add(patient)
    db.commit()
    db.refresh(patient)
    return patient


@router.get("/{patient_id}", response_model=PatientOut)
def get_patient(
    patient_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_physician),
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")
    return patient


@router.get("/{patient_id}/history")
def get_patient_history(
    patient_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_physician),
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    from app.models.clinical_finding import MedicalHistory
    histories = db.query(MedicalHistory).filter(MedicalHistory.patient_id == patient_id).all()
    return {
        "patient_id": patient_id,
        "histories": [
            {
                "id": h.id,
                "category": h.category,
                "content": h.content,
                "source": h.source.value,
                "created_at": h.created_at.isoformat(),
            }
            for h in histories
        ]
    }


@router.get("/{patient_id}/timeline")
def get_patient_timeline(
    patient_id: str,
    db: Session = Depends(get_db),
    current_user: User = Depends(require_physician),
):
    patient = db.query(Patient).filter(Patient.id == patient_id).first()
    if not patient:
        raise HTTPException(status_code=404, detail="Patient not found")

    events = (
        db.query(TimelineEvent)
        .filter(TimelineEvent.patient_id == patient_id)
        .order_by(TimelineEvent.event_date.desc().nullslast())
        .all()
    )
    return {
        "patient_id": patient_id,
        "events": [
            {
                "id": e.id,
                "event_type": e.event_type.value,
                "event_date": e.event_date.isoformat() if e.event_date else None,
                "event_date_text": e.event_date_text,
                "title": e.title,
                "description": e.description,
                "source": e.source,
            }
            for e in events
        ],
    }
