"""
Arogya-Saathi — Diagnosis & Terminology Models
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SAEnum, Text, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class DiagnosisStatus(str, enum.Enum):
    NOT_ENTERED = "not_entered"
    AI_EXTRACTED = "ai_extracted"
    NEEDS_REVIEW = "needs_review"
    PHYSICIAN_ENTERED = "physician_entered"
    PHYSICIAN_CONFIRMED = "physician_confirmed"


class MappingStatus(str, enum.Enum):
    MAPPED = "mapped"
    NEEDS_REVIEW = "needs_review"
    UNAVAILABLE = "unavailable"


class Diagnosis(Base):
    __tablename__ = "diagnoses"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False)
    diagnosis_text = Column(Text, nullable=False)
    status = Column(SAEnum(DiagnosisStatus), default=DiagnosisStatus.NEEDS_REVIEW)
    physician_id = Column(String, ForeignKey("physicians.id"), nullable=True)
    physician_notes = Column(Text, nullable=True)
    is_primary = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    confirmed_at = Column(DateTime(timezone=True), nullable=True)

    encounter = relationship("Encounter", back_populates="diagnoses")
    terminology_mappings = relationship("TerminologyMapping", back_populates="diagnosis")


class TerminologyMapping(Base):
    __tablename__ = "terminology_mappings"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    diagnosis_id = Column(String, ForeignKey("diagnoses.id"), nullable=False)
    system = Column(String, nullable=False)  # "NAMASTE" or "ICD-11-TM2"
    code = Column(String, nullable=True)
    term = Column(Text, nullable=True)
    status = Column(SAEnum(MappingStatus), default=MappingStatus.NEEDS_REVIEW)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    diagnosis = relationship("Diagnosis", back_populates="terminology_mappings")
