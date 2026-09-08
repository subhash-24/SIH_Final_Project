"""
Arogya-Saathi — Clinical Finding Model
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SAEnum, Text, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class FindingSource(str, enum.Enum):
    PATIENT_REPORTED = "patient_reported"
    AI_EXTRACTED = "ai_extracted"
    DOCUMENT_EXTRACTED = "document_extracted"
    PHYSICIAN_CONFIRMED = "physician_confirmed"
    NEEDS_REVIEW = "needs_review"


class FindingType(str, enum.Enum):
    CHIEF_COMPLAINT = "chief_complaint"
    SYMPTOM = "symptom"
    ONSET = "onset"
    DURATION = "duration"
    SEVERITY = "severity"
    LOCATION = "location"
    CHARACTER = "character"
    RADIATION = "radiation"
    AGGRAVATING = "aggravating"
    RELIEVING = "relieving"
    ASSOCIATED = "associated"
    HPI = "hpi"
    ROS = "ros"
    VITAL = "vital"


class ClinicalFinding(Base):
    __tablename__ = "clinical_findings"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False)
    field_type = Column(SAEnum(FindingType), nullable=False)
    value = Column(Text, nullable=False)
    source = Column(SAEnum(FindingSource), default=FindingSource.AI_EXTRACTED)
    needs_review = Column(Boolean, default=True)
    physician_note = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    encounter = relationship("Encounter", back_populates="clinical_findings")


class MedicalHistory(Base):
    __tablename__ = "medical_histories"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    category = Column(String, nullable=False)  # past_medical, surgical, medication, allergy, family, social
    content = Column(Text, nullable=False)
    source = Column(SAEnum(FindingSource), default=FindingSource.PATIENT_REPORTED)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    patient = relationship("Patient", back_populates="medical_histories")
