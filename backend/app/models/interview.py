"""
Arogya-Saathi — Interview & Transcript Models
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Enum as SAEnum, Text, Float, Integer, Boolean
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


def utcnow():
    return datetime.now(timezone.utc)


class InterviewStatus(str, enum.Enum):
    PENDING = "pending"
    ACTIVE = "active"
    COMPLETED = "completed"
    FAILED = "failed"


class Interview(Base):
    __tablename__ = "interviews"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False)
    language = Column(String, default="en")
    status = Column(SAEnum(InterviewStatus), default=InterviewStatus.PENDING)
    current_question_index = Column(Integer, default=0)
    full_transcript = Column(Text, nullable=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    encounter = relationship("Encounter", back_populates="interview")
    segments = relationship("TranscriptSegment", back_populates="interview", order_by="TranscriptSegment.sequence")


class TranscriptSegment(Base):
    __tablename__ = "transcript_segments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    interview_id = Column(String, ForeignKey("interviews.id"), nullable=False)
    sequence = Column(Integer, default=0)
    question = Column(Text, nullable=True)
    response_text = Column(Text, nullable=True)
    audio_file_path = Column(String, nullable=True)
    confidence = Column(Float, default=1.0)
    language = Column(String, default="en")
    is_mock = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    interview = relationship("Interview", back_populates="segments")
