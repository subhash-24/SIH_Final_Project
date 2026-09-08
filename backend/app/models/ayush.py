"""
Arogya-Saathi — AYUSH / Prakriti Models
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, DateTime, ForeignKey, Text, JSON, Float
from sqlalchemy.orm import relationship
from app.core.database import Base


def utcnow():
    return datetime.now(timezone.utc)


class AyushAssessment(Base):
    __tablename__ = "ayush_assessments"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    encounter_id = Column(String, ForeignKey("encounters.id"), nullable=False, unique=True)
    prakriti_result = Column(String, nullable=True)  # e.g. "Pitta-Vata"
    vata_score = Column(Float, default=0.0)
    pitta_score = Column(Float, default=0.0)
    kapha_score = Column(Float, default=0.0)
    vikriti_notes = Column(Text, nullable=True)
    dashavidha_data = Column(JSON, nullable=True)  # Dashavidha Pariksha fields
    ahara = Column(Text, nullable=True)   # diet habits
    vihara = Column(Text, nullable=True)  # lifestyle habits
    physician_notes = Column(Text, nullable=True)
    assessment_method = Column(String, default="questionnaire")
    created_at = Column(DateTime(timezone=True), default=utcnow)

    encounter = relationship("Encounter", back_populates="ayush_assessment")
    prakriti_answers = relationship("PrakritiAnswer", back_populates="assessment")


class PrakritiAnswer(Base):
    __tablename__ = "prakriti_answers"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    assessment_id = Column(String, ForeignKey("ayush_assessments.id"), nullable=False)
    question_id = Column(String, nullable=False)
    question_text = Column(Text, nullable=True)
    answer = Column(String, nullable=False)  # vata / pitta / kapha
    created_at = Column(DateTime(timezone=True), default=utcnow)

    assessment = relationship("AyushAssessment", back_populates="prakriti_answers")
