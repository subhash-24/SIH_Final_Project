"""
Arogya-Saathi — Encounter & Interview API Routes
"""
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
import asyncio

from app.core.database import get_db
from app.models.encounter import Encounter, EncounterStatus, EncounterPriority
from app.models.interview import Interview, TranscriptSegment, InterviewStatus
from app.models.clinical_finding import ClinicalFinding, FindingSource, FindingType
from app.models.red_flag import RedFlag, RedFlagSeverity, RedFlagStatus
from app.models.fhir_resource import AuditLog
from app.auth.dependencies import require_physician
from app.models.user import User

router = APIRouter(tags=["Encounters & Interviews"])


# ─── Encounters ───────────────────────────────────────────────────────────────

class EncounterCreate(BaseModel):
    patient_id: str
    chief_complaint: Optional[str] = None


@router.post("/encounters", status_code=status.HTTP_201_CREATED)
def create_encounter(payload: EncounterCreate, db: Session = Depends(get_db)):
    encounter = Encounter(
        patient_id=payload.patient_id,
        chief_complaint=payload.chief_complaint,
        status=EncounterStatus.INTAKE,
    )
    db.add(encounter)
    db.commit()
    db.refresh(encounter)

    # Audit
    log = AuditLog(action="encounter_created", resource_type="encounter", resource_id=encounter.id,
                   patient_id=payload.patient_id)
    db.add(log)
    db.commit()

    return {"id": encounter.id, "patient_id": encounter.patient_id, "status": encounter.status.value}


@router.get("/encounters/{encounter_id}")
def get_encounter(encounter_id: str, db: Session = Depends(get_db),
                  current_user: User = Depends(require_physician)):
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="Encounter not found")

    findings = [
        {"id": f.id, "field_type": f.field_type.value, "value": f.value,
         "source": f.source.value, "needs_review": f.needs_review}
        for f in enc.clinical_findings
    ]

    red_flags = [
        {"id": r.id, "rule_name": r.rule_name, "severity": r.severity.value,
         "reason": r.reason, "triggered_by": r.triggered_by, "status": r.status.value}
        for r in enc.red_flags
    ]

    return {
        "id": enc.id,
        "patient_id": enc.patient_id,
        "status": enc.status.value,
        "priority": enc.priority.value,
        "chief_complaint": enc.chief_complaint,
        "clinical_findings": findings,
        "red_flags": red_flags,
        "created_at": enc.created_at.isoformat(),
    }


@router.get("/encounters/{encounter_id}/summary")
def get_encounter_summary(encounter_id: str, db: Session = Depends(get_db),
                          current_user: User = Depends(require_physician)):
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="Encounter not found")

    patient = enc.patient
    findings_by_type: dict = {}
    for f in enc.clinical_findings:
        ft = f.field_type.value
        if ft not in findings_by_type:
            findings_by_type[ft] = []
        findings_by_type[ft].append({"value": f.value, "source": f.source.value, "needs_review": f.needs_review})

    return {
        "encounter_id": enc.id,
        "patient": {
            "id": patient.id, "name": patient.name, "age": patient.age,
            "gender": patient.gender, "abha_number": patient.abha_number,
        },
        "status": enc.status.value,
        "priority": enc.priority.value,
        "chief_complaint": enc.chief_complaint,
        "findings": findings_by_type,
        "red_flags": [
            {"rule_name": r.rule_name, "severity": r.severity.value, "reason": r.reason,
             "triggered_by": r.triggered_by, "status": r.status.value}
            for r in enc.red_flags
        ],
        "documents_count": len(enc.documents),
        "has_ayush": enc.ayush_assessment is not None,
        "diagnoses": [
            {"id": d.id, "text": d.diagnosis_text, "status": d.status.value}
            for d in enc.diagnoses
        ],
    }


@router.put("/encounters/{encounter_id}/submit")
def submit_encounter(encounter_id: str, db: Session = Depends(get_db)):
    """Patient submits their intake — moves to physician queue."""
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="Encounter not found")
    enc.status = EncounterStatus.PHYSICIAN_REVIEW
    db.commit()

    log = AuditLog(action="encounter_submitted", resource_type="encounter", resource_id=encounter_id,
                   patient_id=enc.patient_id)
    db.add(log)
    db.commit()

    return {"message": "Encounter submitted for physician review", "id": encounter_id}


# ─── Interviews ───────────────────────────────────────────────────────────────

class InterviewStart(BaseModel):
    encounter_id: str
    language: str = "en"


class InterviewText(BaseModel):
    text: str
    language: str = "en"


@router.post("/interviews/start", status_code=status.HTTP_201_CREATED)
def start_interview(payload: InterviewStart, db: Session = Depends(get_db)):
    interview = Interview(
        encounter_id=payload.encounter_id,
        language=payload.language,
        status=InterviewStatus.ACTIVE,
    )
    db.add(interview)
    db.commit()
    db.refresh(interview)

    log = AuditLog(action="interview_started", resource_type="interview", resource_id=interview.id)
    db.add(log)
    db.commit()

    # Return first question
    first_question = _get_question(0, payload.language)
    return {
        "interview_id": interview.id,
        "status": interview.status.value,
        "current_question": first_question,
        "question_index": 0,
    }


async def _process_interview_response(
    interview: Interview,
    text: str,
    language: str,
    confidence: float,
    is_mock: bool,
    db: Session,
):
    """
    Common clinical extraction, storage, and triage logic shared by audio and text intake.
    """
    from app.services.ai.nlp_service import get_nlp_service
    from app.services.rules.red_flag_engine import evaluate_red_flags, get_highest_severity

    # NLP extraction
    nlp = get_nlp_service()
    extraction = await nlp.extract_async(text)

    # Save transcript segment
    segment = TranscriptSegment(
        interview_id=interview.id,
        sequence=interview.current_question_index,
        question=_get_question(interview.current_question_index, language),
        response_text=text,
        confidence=confidence,
        language=language,
        is_mock=is_mock or extraction.is_mock,
    )
    db.add(segment)

    # Save clinical findings
    enc_id = interview.encounter_id
    for entity in extraction.entities:
        finding = ClinicalFinding(
            encounter_id=enc_id,
            field_type=FindingType(entity.field_type) if entity.field_type in [e.value for e in FindingType] else FindingType.SYMPTOM,
            value=entity.value,
            source=FindingSource.AI_EXTRACTED,
            needs_review=True,
        )
        db.add(finding)

    # Update chief complaint on encounter
    enc = db.query(Encounter).filter(Encounter.id == enc_id).first()
    if enc:
        cc_entity = next((e for e in extraction.entities if e.field_type == "chief_complaint"), None)
        if cc_entity and not enc.chief_complaint:
            enc.chief_complaint = cc_entity.value

    # Red flag evaluation
    rf_results = evaluate_red_flags(
        symptoms=extraction.normalized_symptoms,
        clinical_text=text,
    )

    triggered_flags = []
    if rf_results:
        highest = get_highest_severity(rf_results)
        # Update encounter priority
        if enc:
            if highest == "urgent":
                enc.priority = EncounterPriority.URGENT
            elif highest == "warning":
                enc.priority = EncounterPriority.MODERATE

        for result in rf_results:
            rf = RedFlag(
                encounter_id=enc_id,
                rule_id=result.rule_id,
                rule_name=result.rule_name,
                severity=RedFlagSeverity(result.severity),
                reason=result.physician_reason,
                triggered_by=result.triggered_by,
                source="patient_interview",
                status=RedFlagStatus.DETECTED,
            )
            db.add(rf)
            triggered_flags.append({
                "rule_name": result.rule_name,
                "severity": result.severity,
                "patient_message": result.patient_message,
                "physician_reason": result.physician_reason,
                "triggered_by": result.triggered_by,
            })

        log = AuditLog(action="red_flag_detected", resource_type="encounter",
                       resource_id=enc_id, details={"rules": [r.rule_id for r in rf_results]})
        db.add(log)

    db.commit()

    # Determine next question
    next_idx = interview.current_question_index + 1
    interview.current_question_index = next_idx
    db.commit()

    next_question = _get_adaptive_question(extraction, next_idx, language)

    return {
        "transcript": text,
        "language": language,
        "confidence": confidence,
        "is_mock": extraction.is_mock or is_mock,
        "extraction_source": getattr(extraction, "source", "mock" if extraction.is_mock else "cloud_llm"),
        "extracted_fields": [
            {"field_type": e.field_type, "value": e.value, "source": e.source, "confidence": e.confidence}
            for e in extraction.entities
        ],
        "red_flags": triggered_flags,
        "has_red_flags": bool(triggered_flags),
        "next_question": next_question,
        "question_index": next_idx,
    }


@router.post("/interviews/{interview_id}/text")
async def submit_text(
    interview_id: str,
    payload: InterviewText,
    db: Session = Depends(get_db),
):
    """
    Receive typed patient text → Clinical NLP (Gemini / rule fallback) → Red Flag Detection.
    Returns structured extraction identical to audio endpoint.
    """
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")

    return await _process_interview_response(
        interview=interview,
        text=payload.text,
        language=payload.language or "en",
        confidence=1.0,
        is_mock=False,
        db=db,
    )


@router.post("/interviews/{interview_id}/audio")
async def submit_audio(
    interview_id: str,
    audio: UploadFile = File(None),
    language: str = Form("en"),
    scenario_hint: str = Form(None),
    db: Session = Depends(get_db),
):
    """
    Receive audio blob → ASR → Clinical NLP → Red Flag Detection.
    Returns structured extraction.
    """
    from app.services.ai.asr_service import get_asr_service

    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")

    # Read audio bytes (or use hint for demo)
    audio_bytes = None
    if audio:
        audio_bytes = await audio.read()

    # ASR
    asr = get_asr_service()
    transcription = await asr.transcribe(
        audio_data=audio_bytes,
        language=language,
        scenario_hint=scenario_hint,
    )

    return await _process_interview_response(
        interview=interview,
        text=transcription.text,
        language=transcription.language or language,
        confidence=transcription.confidence,
        is_mock=transcription.is_mock,
        db=db,
    )


@router.get("/interviews/{interview_id}/transcript")
def get_transcript(interview_id: str, db: Session = Depends(get_db)):
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")
    return {
        "interview_id": interview_id,
        "language": interview.language,
        "status": interview.status.value,
        "segments": [
            {"sequence": s.sequence, "question": s.question,
             "response_text": s.response_text, "confidence": s.confidence}
            for s in interview.segments
        ],
    }


@router.post("/interviews/{interview_id}/complete")
def complete_interview(interview_id: str, db: Session = Depends(get_db)):
    interview = db.query(Interview).filter(Interview.id == interview_id).first()
    if not interview:
        raise HTTPException(status_code=404, detail="Interview not found")
    interview.status = InterviewStatus.COMPLETED
    db.commit()
    return {"message": "Interview completed", "interview_id": interview_id}


# ─── Question Logic ───────────────────────────────────────────────────────────

_QUESTIONS_EN = [
    "What brings you here today? Please describe what is troubling you.",
    "When did this problem start? How long have you had these symptoms?",
    "How severe is the discomfort on a scale of 0 to 10?",
    "Where exactly do you feel this? Does it spread anywhere else?",
    "Are there any other symptoms you are experiencing along with this?",
    "Do you have any known medical conditions or previous illnesses?",
    "Are you currently taking any medicines or treatments?",
    "Do you have any known allergies to medicines or foods?",
    "Has anyone in your family had similar health problems?",
    "Is there anything that makes your symptoms better or worse?",
]

_QUESTIONS_HI = [
    "आज आप यहाँ क्यों आए हैं? कृपया बताएं क्या तकलीफ है।",
    "यह समस्या कब से है? कितने समय से लक्षण हैं?",
    "0 से 10 के पैमाने पर तकलीफ कितनी है?",
    "दर्द या तकलीफ कहाँ है? कहीं और भी फैलती है?",
    "इसके साथ कोई और लक्षण हैं?",
    "क्या आपको कोई पुरानी बीमारी है?",
    "क्या आप कोई दवाई ले रहे हैं?",
    "क्या आपको किसी दवाई या खाने से एलर्जी है?",
    "क्या परिवार में किसी को ऐसी समस्या रही है?",
    "कुछ करने से आराम या तकलीफ ज्यादा होती है?",
]

# Adaptive: if chest pain found, prioritize cardiac follow-ups
_ADAPTIVE_CARDIAC_EN = [
    "Does the pain go to your arm, jaw, or back?",
    "Are you experiencing sweating, nausea, or difficulty breathing?",
    "Have you had this kind of chest pain before?",
]

_ADAPTIVE_CARDIAC_HI = [
    "क्या दर्द आपके हाथ, जबड़े या पीठ में जाता है?",
    "क्या आपको पसीना, जी मचलना या साँस लेने में तकलीफ है?",
    "क्या पहले भी ऐसा सीने में दर्द हुआ था?",
]


def _get_question(index: int, language: str) -> str | None:
    questions = _QUESTIONS_HI if language == "hi" else _QUESTIONS_EN
    if index < len(questions):
        return questions[index]
    return None


def _get_adaptive_question(extraction, index: int, language: str) -> str | None:
    """Return adaptive question based on extracted symptoms."""
    # Check if chest pain is in findings
    has_chest_pain = any(
        e.field_type == "chief_complaint" and "chest" in e.value.lower()
        for e in extraction.entities
    )
    has_chest_pain = has_chest_pain or "chest_pain" in extraction.normalized_symptoms

    if has_chest_pain and index <= 3:
        cardiac_q = _ADAPTIVE_CARDIAC_HI if language == "hi" else _ADAPTIVE_CARDIAC_EN
        if index - 1 < len(cardiac_q):
            return cardiac_q[index - 1]

    return _get_question(index, language)
