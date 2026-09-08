"""
Arogya-Saathi — FHIR Resource, Consent, Audit Log Models
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, JSON, Enum as SAEnum, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class FhirResource(Base):
    __tablename__ = "fhir_resources"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False)
    resource_type = Column(String, nullable=False)
    resource_json = Column(JSON, nullable=False)
    fhir_version = Column(String, default="R4")
    is_validated = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    encounter = relationship("Encounter", back_populates="fhir_resources")


class ConsentStatus(str, enum.Enum):
    PENDING = "pending"
    GRANTED = "granted"
    REVOKED = "revoked"
    EXPIRED = "expired"


class Consent(Base):
    __tablename__ = "consents"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    patient_id = Column(String, ForeignKey("patients.id"), nullable=False)
    purpose = Column(String, nullable=False)
    scope = Column(String, nullable=True)
    status = Column(SAEnum(ConsentStatus), default=ConsentStatus.PENDING)
    timestamp = Column(DateTime(timezone=True), default=utcnow)
    expiry = Column(DateTime(timezone=True), nullable=True)
    revoked_at = Column(DateTime(timezone=True), nullable=True)

    patient = relationship("Patient", back_populates="consents")


class AuditLog(Base):
    __tablename__ = "audit_logs"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, nullable=True)
    patient_id = Column(String, nullable=True)
    action = Column(String, nullable=False)
    resource_type = Column(String, nullable=True)
    resource_id = Column(String, nullable=True)
    details = Column(JSON, nullable=True)
    ip_address = Column(String, nullable=True)
    timestamp = Column(DateTime(timezone=True), default=utcnow)
