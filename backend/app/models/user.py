"""
Arogya-Saathi — User & Physician Models
"""
import uuid
from datetime import datetime, timezone
from sqlalchemy import Column, String, Boolean, DateTime, ForeignKey, Enum as SAEnum
from sqlalchemy.orm import relationship
from app.core.database import Base
import enum


class UserRole(str, enum.Enum):
    PATIENT = "patient"
    PHYSICIAN = "physician"
    ADMIN = "admin"


def utcnow():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    email = Column(String, unique=True, index=True, nullable=False)
    hashed_password = Column(String, nullable=False)
    role = Column(SAEnum(UserRole), nullable=False, default=UserRole.PHYSICIAN)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), default=utcnow)
    updated_at = Column(DateTime(timezone=True), default=utcnow, onupdate=utcnow)

    physician = relationship("Physician", back_populates="user", uselist=False)


class Physician(Base):
    __tablename__ = "physicians"

    id = Column(String, primary_key=True, default=lambda: str(uuid.uuid4()))
    user_id = Column(String, ForeignKey("users.id"), unique=True)
    name = Column(String, nullable=False)
    specialization = Column(String, default="General Medicine")
    registration_number = Column(String)
    hospital = Column(String)
    created_at = Column(DateTime(timezone=True), default=utcnow)

    user = relationship("User", back_populates="physician")
    encounters = relationship("Encounter", back_populates="physician")
