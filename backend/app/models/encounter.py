"""
Arogya-Saathi — Encounter Model
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SAEnum, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class EncounterStatus(str, enum.Enum):
    INTAKE = "intake"
    IN_PROGRESS = "in_progress"
    PHYSICIAN_REVIEW = "physician_review"
    COMPLETED = "completed"
    CANCELLED = "cancelled"


class EncounterPriority(str, enum.Enum):
    ROUTINE = "routine"
    MODERATE = "moderate"
    URGENT = "urgent"


class Encounter(Base):
    __tablename__ = "encounters"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    physician_id = Column(String, ForeignKey("physicians.id"), nullable=True)
    status = Column(SAEnum(EncounterStatus), default=EncounterStatus.INTAKE)
    priority = Column(SAEnum(EncounterPriority), default=EncounterPriority.ROUTINE)
    chief_complaint = Column(Text, nullable=True)
    notes = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)
    completed_at = Column(DateTime(timezone=True), nullable=True)

    patient = relationship("Patient", back_populates="encounters")
    physician = relationship("Physician", back_populates="encounters")
    interview = relationship("Interview", back_populates="encounter", uselist=False)
    clinical_findings = relationship("ClinicalFinding", back_populates="encounter")
    documents = relationship("Document", back_populates="encounter")
    red_flags = relationship("RedFlag", back_populates="encounter")
    ayush_assessment = relationship("AyushAssessment", back_populates="encounter", uselist=False)
    diagnoses = relationship("Diagnosis", back_populates="encounter")
    fhir_resources = relationship("FhirResource", back_populates="encounter")
