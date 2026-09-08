"""
Arogya-Saathi — Patient Model
"""
import uuid
from datetime import datetime, timezone, date
from sqlalchemy import Column, String, Date, DateTime, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class Patient(Base):
    __tablename__ = "patients"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    name = Column(String, nullable=False)
    dob = Column(Date, nullable=True)
    age = Column(String, nullable=True)  # fallback if DOB not provided
    gender = Column(String, nullable=True)
    mobile = Column(String, nullable=True)
    abha_number = Column(String, nullable=True, unique=True)
    emergency_contact_name = Column(String, nullable=True)
    emergency_contact_phone = Column(String, nullable=True)
    preferred_language = Column(String, default="en")
    is_demo = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    encounters = relationship("Encounter", back_populates="patient")
    medical_histories = relationship("MedicalHistory", back_populates="patient")
    timeline_events = relationship("TimelineEvent", back_populates="patient")
    consents = relationship("Consent", back_populates="patient")
