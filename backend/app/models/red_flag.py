"""
Arogya-Saathi — Red Flag Model
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SAEnum, Text, JSON
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class RedFlagSeverity(str, enum.Enum):
    URGENT = "urgent"
    WARNING = "warning"
    ATTENTION = "attention"


class RedFlagStatus(str, enum.Enum):
    DETECTED = "detected"
    ACKNOWLEDGED = "acknowledged"
    REVIEWED = "reviewed"
    DISMISSED = "dismissed"


class RedFlag(Base):
    __tablename__ = "red_flags"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False)
    rule_id = Column(String, nullable=False)
    rule_name = Column(String, nullable=False)
    severity = Column(SAEnum(RedFlagSeverity), default=RedFlagSeverity.URGENT)
    reason = Column(Text, nullable=False)
    triggered_by = Column(JSON, nullable=True)  # list of symptoms that triggered this
    source = Column(String, default="patient_interview")
    status = Column(SAEnum(RedFlagStatus), default=RedFlagStatus.DETECTED)
    acknowledged_by = Column(String, nullable=True)  # physician user_id
    acknowledged_at = Column(DateTime(timezone=True), nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    encounter = relationship("Encounter", back_populates="red_flags")
