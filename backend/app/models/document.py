"""
Arogya-Saathi — Document & Extraction Models
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SAEnum, Text, Float, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class DocumentStatus(str, enum.Enum):
    UPLOADED = "uploaded"
    PROCESSING = "processing"
    EXTRACTED = "extracted"
    NEEDS_REVIEW = "needs_review"
    VERIFIED = "verified"
    FAILED = "failed"


class Document(Base):
    __tablename__ = "documents"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False)
    original_filename = Column(String, nullable=False)
    storage_path = Column(String, nullable=True)
    document_type = Column(String, default="unknown")  # prescription, lab_report, discharge_summary, etc
    status = Column(SAEnum(DocumentStatus), default=DocumentStatus.UPLOADED)
    ocr_text = Column(Text, nullable=True)
    physician_note = Column(Text, nullable=True)
    is_mock = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    encounter = relationship("Encounter", back_populates="documents")
    extractions = relationship("DocumentExtraction", back_populates="document")


class DocumentExtraction(Base):
    __tablename__ = "document_extractions"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    document_id = Column(String, ForeignKey("documents.id"), nullable=False)
    entity_type = Column(String, nullable=False)  # date, medicine, diagnosis, lab_value, doctor, hospital
    value = Column(Text, nullable=False)
    confidence = Column(Float, default=0.85)
    is_verified = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    document = relationship("Document", back_populates="extractions")
