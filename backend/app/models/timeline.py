"""
Arogya-Saathi — Timeline Event Model
"""
import uuid
from datetime import datetime, timezone, date
from sqlalchemy import Column, String, DateTime, Date, ForeignKey, Enum as SAEnum, Text
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class TimelineEventType(str, enum.Enum):
    ENCOUNTER = "encounter"
    DOCUMENT = "document"
    INVESTIGATION = "investigation"
    DIAGNOSIS = "diagnosis"
    MEDICATION = "medication"
    SURGERY = "surgery"
    HOSPITALIZATION = "hospitalization"
    VACCINATION = "vaccination"
    OTHER = "other"


class TimelineEvent(Base):
    __tablename__ = "timeline_events"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    event_type = Column(SAEnum(TimelineEventType), nullable=False)
    event_date = Column(Date, nullable=True)
    event_date_text = Column(String, nullable=True)  # free text if exact date unknown
    title = Column(String, nullable=False)
    description = Column(Text, nullable=True)
    source = Column(String, default="patient_reported")
    linked_document_id = Column(String, ForeignKey("documents.id"), nullable=True)
    linked_encounter_id = Column(String, ForeignKey("encounters.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    patient = relationship("Patient", back_populates="timeline_events")
