"""
Arogya-Saathi — Demo Data Seeder
Seeds 5 fictional demo patients with full clinical data.
ALL DATA IS FICTIONAL AND FOR DEMONSTRATION ONLY.
"""
from datetime import datetime, timezone, date, timedelta
import uuid
from sqlalchemy.orm import Session

from app.core.security import get_password_hash
from app.models.user import User, Physician, UserRole
from app.models.patient import Patient
from app.models.encounter import Encounter, EncounterStatus, EncounterPriority
from app.models.interview import Interview, TranscriptSegment, InterviewStatus
from app.models.clinical_finding import ClinicalFinding, MedicalHistory, FindingSource, FindingType
from app.models.document import Document, DocumentExtraction, DocumentStatus
from app.models.timeline import TimelineEvent, TimelineEventType
from app.models.red_flag import RedFlag, RedFlagSeverity, RedFlagStatus
from app.models.ayush import AyushAssessment, PrakritiAnswer
from app.models.diagnosis import Diagnosis, TerminologyMapping, DiagnosisStatus, MappingStatus
from app.models.fhir_resource import Consent, ConsentStatus, AuditLog


def utcnow():
    return datetime.now(timezone.utc)


def seed_demo_data(db: Session):
    """Idempotent seed — checks before inserting."""
    existing = db.query(User).filter(User.email == "dr.sharma@arogyasaathi.demo").first()
    if existing:
        print("Demo data already seeded.")
        return

    print("Seeding demo data...")

    # ── Physician ─────────────────────────────────────────────────────────────
    physician_user = User(
        id=str(uuid.uuid4()),
        email="dr.sharma@arogyasaathi.demo",
        hashed_password=get_password_hash("demo@123"),
        role=UserRole.PHYSICIAN,
        is_active=True,
    )
    db.add(physician_user)
    db.flush()

    physician = Physician(
        id=str(uuid.uuid4()),
        user_id=physician_user.id,
        name="Dr. Priya Sharma",
        specialization="General Medicine",
        registration_number="MCI-12345",
        hospital="Arogya Demo Hospital",
    )
    db.add(physician)
    db.flush()

    # Admin user
    admin_user = User(
        id=str(uuid.uuid4()),
        email="admin@arogyasaathi.demo",
        hashed_password=get_password_hash("admin@123"),
        role=UserRole.ADMIN,
        is_active=True,
    )
    db.add(admin_user)

    # ── Demo Patients ─────────────────────────────────────────────────────────

    # Patient 1: Emergency Chest Pain (URGENT)
    p1 = Patient(
        id=str(uuid.uuid4()),
        name="Ramesh Kumar",
        age="45",
        gender="Male",
        mobile="9876543210",
        preferred_language="hi",
        is_demo=True,
    )
    db.add(p1)
    db.flush()

    enc1 = Encounter(
        id=str(uuid.uuid4()),
        patient_id=p1.id,
        physician_id=physician.id,
        status=EncounterStatus.PHYSICIAN_REVIEW,
        priority=EncounterPriority.URGENT,
        chief_complaint="Chest pain",
        created_at=utcnow() - timedelta(minutes=15),
    )
    db.add(enc1)
    db.flush()

    _add_finding(db, enc1.id, FindingType.CHIEF_COMPLAINT, "Chest pain", FindingSource.PATIENT_REPORTED)
    _add_finding(db, enc1.id, FindingType.DURATION, "2 hours", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc1.id, FindingType.SEVERITY, "Severe", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc1.id, FindingType.RADIATION, "Left arm", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc1.id, FindingType.ASSOCIATED, "Sweating, Nausea", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc1.id, FindingType.HPI,
                 "45-year-old male presents with severe chest pain for 2 hours radiating to left arm with associated sweating and nausea.",
                 FindingSource.AI_EXTRACTED)

    # Red flag for p1
    rf1 = RedFlag(
        encounter_id=enc1.id,
        rule_id="cardiac_emergency",
        rule_name="Possible Cardiac Emergency",
        severity=RedFlagSeverity.URGENT,
        reason="Chest pain with sweating and radiation to arm requires urgent cardiac assessment. Rule out Acute Coronary Syndrome.",
        triggered_by=["chest_pain", "sweating", "radiation_arm"],
        source="patient_interview",
        status=RedFlagStatus.DETECTED,
        created_at=utcnow() - timedelta(minutes=14),
    )
    db.add(rf1)

    # Medical history p1
    _add_history(db, p1.id, "past_medical", "Hypertension (5 years)", FindingSource.PATIENT_REPORTED)
    _add_history(db, p1.id, "medication", "Tab. Amlodipine 5mg once daily", FindingSource.PATIENT_REPORTED)
    _add_history(db, p1.id, "family", "Father had heart attack at age 60", FindingSource.PATIENT_REPORTED)

    # Interview transcript for p1
    iv1 = Interview(
        encounter_id=enc1.id,
        language="hi",
        status=InterviewStatus.COMPLETED,
    )
    db.add(iv1)
    db.flush()

    seg1 = TranscriptSegment(
        interview_id=iv1.id,
        sequence=0,
        question="आज आप यहाँ क्यों आए हैं? कृपया बताएं क्या तकलीफ है।",
        response_text="मुझे दो घंटे से बहुत तेज सीने में दर्द हो रहा है। दर्द मेरे बाएं हाथ में भी जा रहा है और मुझे बहुत पसीना आ रहा है।",
        confidence=0.94,
        language="hi",
        is_mock=True,
    )
    db.add(seg1)

    # Document for p1
    doc1 = Document(
        encounter_id=enc1.id,
        original_filename="prescription_march_2025.jpg",
        document_type="prescription",
        status=DocumentStatus.EXTRACTED,
        ocr_text="Dr. Rajan Mehta\nDate: 15 March 2025\nTab. Atorvastatin 20mg\nTab. Aspirin 75mg",
        is_mock=True,
    )
    db.add(doc1)
    db.flush()

    # Timeline for p1
    db.add(TimelineEvent(patient_id=p1.id, event_type=TimelineEventType.DIAGNOSIS,
                          event_date=date(2020, 6, 10), title="Hypertension diagnosed",
                          description="First diagnosed with hypertension", source="patient_reported"))
    db.add(TimelineEvent(patient_id=p1.id, event_type=TimelineEventType.DOCUMENT,
                          event_date=date(2025, 3, 15), title="Prescription",
                          description="Reviewed by Dr. Rajan Mehta", source="document_extracted",
                          linked_document_id=doc1.id))
    db.add(TimelineEvent(patient_id=p1.id, event_type=TimelineEventType.ENCOUNTER,
                          event_date=date.today(), title="Current Visit — Chest Pain",
                          description="Emergency presentation with severe chest pain",
                          source="current_encounter", linked_encounter_id=enc1.id))

    # Consent for p1
    db.add(Consent(patient_id=p1.id, purpose="clinical_care",
                    scope="voice_recording,document_processing,ai_processing",
                    status=ConsentStatus.GRANTED))

    # ── Patient 2: Fever ──────────────────────────────────────────────────────
    p2 = Patient(
        id=str(uuid.uuid4()),
        name="Priya Sharma",
        age="32",
        gender="Female",
        preferred_language="en",
        is_demo=True,
    )
    db.add(p2)
    db.flush()

    enc2 = Encounter(
        id=str(uuid.uuid4()),
        patient_id=p2.id,
        physician_id=physician.id,
        status=EncounterStatus.PHYSICIAN_REVIEW,
        priority=EncounterPriority.MODERATE,
        chief_complaint="Fever",
        created_at=utcnow() - timedelta(minutes=30),
    )
    db.add(enc2)
    db.flush()

    _add_finding(db, enc2.id, FindingType.CHIEF_COMPLAINT, "Fever", FindingSource.PATIENT_REPORTED)
    _add_finding(db, enc2.id, FindingType.DURATION, "3 days", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc2.id, FindingType.ASSOCIATED, "Sore throat, Cough", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc2.id, FindingType.HPI,
                 "32-year-old female with fever for 3 days, sore throat, and cough.",
                 FindingSource.AI_EXTRACTED)

    _add_history(db, p2.id, "past_medical", "No significant past medical history", FindingSource.PATIENT_REPORTED)

    # ── Patient 3: Chronic Disease (Diabetes) ─────────────────────────────────
    p3 = Patient(
        id=str(uuid.uuid4()),
        name="Suresh Patel",
        age="62",
        gender="Male",
        preferred_language="en",
        is_demo=True,
    )
    db.add(p3)
    db.flush()

    enc3 = Encounter(
        id=str(uuid.uuid4()),
        patient_id=p3.id,
        physician_id=physician.id,
        status=EncounterStatus.COMPLETED,
        priority=EncounterPriority.ROUTINE,
        chief_complaint="Diabetes follow-up",
        created_at=utcnow() - timedelta(hours=2),
        completed_at=utcnow() - timedelta(hours=1),
    )
    db.add(enc3)
    db.flush()

    _add_finding(db, enc3.id, FindingType.CHIEF_COMPLAINT, "Diabetes follow-up", FindingSource.PATIENT_REPORTED)
    _add_finding(db, enc3.id, FindingType.HPI,
                 "62-year-old male with Type 2 Diabetes Mellitus for 10 years presents for routine follow-up. Reports difficulty controlling blood sugar.",
                 FindingSource.AI_EXTRACTED)

    _add_history(db, p3.id, "past_medical", "Type 2 Diabetes Mellitus (10 years)", FindingSource.PATIENT_REPORTED)
    _add_history(db, p3.id, "past_medical", "Hypertension (8 years)", FindingSource.PATIENT_REPORTED)
    _add_history(db, p3.id, "medication", "Tab. Metformin 500mg twice daily", FindingSource.PATIENT_REPORTED)
    _add_history(db, p3.id, "medication", "Tab. Glimepiride 2mg once daily", FindingSource.PATIENT_REPORTED)

    # Completed diagnosis for p3
    diag3 = Diagnosis(
        encounter_id=enc3.id,
        diagnosis_text="Type 2 Diabetes Mellitus",
        status=DiagnosisStatus.PHYSICIAN_CONFIRMED,
        physician_id=physician.id,
        is_primary=True,
        confirmed_at=utcnow() - timedelta(hours=1),
    )
    db.add(diag3)
    db.flush()

    db.add(TerminologyMapping(diagnosis_id=diag3.id, system="NAMASTE",
                               code="NAMASTE-EN-001", term="Madhumeha (Diabetes Mellitus Type 2)",
                               status=MappingStatus.MAPPED))
    db.add(TerminologyMapping(diagnosis_id=diag3.id, system="ICD-11-TM2",
                               code="5A11", term="Type 2 diabetes mellitus",
                               status=MappingStatus.MAPPED))

    db.add(TimelineEvent(patient_id=p3.id, event_type=TimelineEventType.DIAGNOSIS,
                          event_date=date(2015, 3, 1), title="Type 2 Diabetes diagnosed",
                          source="patient_reported"))
    db.add(TimelineEvent(patient_id=p3.id, event_type=TimelineEventType.ENCOUNTER,
                          event_date=date.today(), title="Follow-up Visit", source="current_encounter",
                          linked_encounter_id=enc3.id))

    # ── Patient 4: AYUSH Focus ────────────────────────────────────────────────
    p4 = Patient(
        id=str(uuid.uuid4()),
        name="Meera Devi",
        age="38",
        gender="Female",
        preferred_language="hi",
        is_demo=True,
    )
    db.add(p4)
    db.flush()

    enc4 = Encounter(
        id=str(uuid.uuid4()),
        patient_id=p4.id,
        physician_id=physician.id,
        status=EncounterStatus.PHYSICIAN_REVIEW,
        priority=EncounterPriority.ROUTINE,
        chief_complaint="Fatigue and digestive issues",
        created_at=utcnow() - timedelta(minutes=45),
    )
    db.add(enc4)
    db.flush()

    _add_finding(db, enc4.id, FindingType.CHIEF_COMPLAINT, "Fatigue and digestive problems", FindingSource.PATIENT_REPORTED)
    _add_finding(db, enc4.id, FindingType.HPI,
                 "38-year-old female with chronic fatigue and digestive complaints. Requests Ayurvedic assessment.",
                 FindingSource.AI_EXTRACTED)

    # AYUSH assessment for p4
    ayush4 = AyushAssessment(
        encounter_id=enc4.id,
        prakriti_result="Pitta-Vata",
        vata_score=35.0,
        pitta_score=45.0,
        kapha_score=20.0,
        ahara="Spicy and oily food, irregular meal times",
        vihara="Sedentary lifestyle, high stress work environment",
        assessment_method="questionnaire",
    )
    db.add(ayush4)

    # ── Patient 5: Routine OPD ────────────────────────────────────────────────
    p5 = Patient(
        id=str(uuid.uuid4()),
        name="Arjun Singh",
        age="28",
        gender="Male",
        preferred_language="en",
        is_demo=True,
    )
    db.add(p5)
    db.flush()

    enc5 = Encounter(
        id=str(uuid.uuid4()),
        patient_id=p5.id,
        physician_id=physician.id,
        status=EncounterStatus.PHYSICIAN_REVIEW,
        priority=EncounterPriority.ROUTINE,
        chief_complaint="Knee pain after sports injury",
        created_at=utcnow() - timedelta(minutes=60),
    )
    db.add(enc5)
    db.flush()

    _add_finding(db, enc5.id, FindingType.CHIEF_COMPLAINT, "Knee pain", FindingSource.PATIENT_REPORTED)
    _add_finding(db, enc5.id, FindingType.DURATION, "2 days", FindingSource.AI_EXTRACTED)
    _add_finding(db, enc5.id, FindingType.HPI,
                 "28-year-old male with right knee pain following football injury 2 days ago. Swelling present.",
                 FindingSource.AI_EXTRACTED)

    db.commit()
    print("✓ Demo data seeded successfully.")
    print(f"  Physician login: dr.sharma@arogyasaathi.demo / demo@123")
    print(f"  Admin login:     admin@arogyasaathi.demo / admin@123")
    print(f"  Demo patients:   {[p1.name, p2.name, p3.name, p4.name, p5.name]}")


def _add_finding(db: Session, encounter_id: str, field_type: FindingType, value: str, source: FindingSource):
    db.add(ClinicalFinding(encounter_id=encounter_id, field_type=field_type,
                            value=value, source=source, needs_review=(source == FindingSource.AI_EXTRACTED)))


def _add_history(db: Session, patient_id: str, category: str, content: str, source: FindingSource):
    db.add(MedicalHistory(patient_id=patient_id, category=category, content=content, source=source))
