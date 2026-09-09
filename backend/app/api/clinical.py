"""
Arogya-Saathi — Documents, Red Flags, AYUSH, Diagnosis, FHIR API Routes
"""
import os
import shutil
from pathlib import Path
from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File, Form
from sqlalchemy.orm import Session
from pydantic import BaseModel
from typing import Optional
from datetime import datetime, timezone

from app.core.database import get_db
from app.core.config import settings
from app.models.document import Document, DocumentExtraction, DocumentStatus
from app.models.red_flag import RedFlag, RedFlagStatus
from app.models.ayush import AyushAssessment, PrakritiAnswer
from app.models.diagnosis import Diagnosis, TerminologyMapping, DiagnosisStatus, MappingStatus
from app.models.encounter import Encounter, EncounterStatus
from app.models.fhir_resource import FhirResource, AuditLog
from app.auth.dependencies import require_physician
from app.models.user import User

router = APIRouter(tags=["Clinical Operations"])

UPLOAD_DIR = Path(settings.storage_local_path)
UPLOAD_DIR.mkdir(parents=True, exist_ok=True)


# ─── Documents ────────────────────────────────────────────────────────────────

@router.post("/documents/upload", status_code=status.HTTP_201_CREATED)
async def upload_document(
    encounter_id: str = Form(...),
    document_type: str = Form("unknown"),
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    """Upload a document — runs mock OCR pipeline."""
    # Save file
    safe_name = f"{encounter_id}_{file.filename}"
    file_path = UPLOAD_DIR / safe_name
    with open(file_path, "wb") as f:
        content = await file.read()
        f.write(content)

    doc = Document(
        encounter_id=encounter_id,
        original_filename=file.filename,
        storage_path=str(file_path),
        document_type=document_type,
        status=DocumentStatus.UPLOADED,
        is_mock=False,
    )
    db.add(doc)
    db.commit()
    db.refresh(doc)

    # Process Document (OCR + NLP)
    await _process_document(doc, db)

    log = AuditLog(action="document_uploaded", resource_type="document",
                   resource_id=doc.id, patient_id=None)
    db.add(log)
    db.commit()

    return {
        "id": doc.id,
        "status": doc.status.value,
        "original_filename": doc.original_filename,
        "ocr_text": doc.ocr_text,
        "extractions": [
            {"entity_type": e.entity_type, "value": e.value, "confidence": e.confidence}
            for e in doc.extractions
        ],
    }


async def _process_document(doc: Document, db: Session):
    """Run OCR + entity extraction pipeline."""
    from app.services.ai.ocr_service import get_ocr_service
    from app.services.ai.nlp_service import get_nlp_service

    # 1. OCR Extraction
    ocr_service = get_ocr_service()
    # pass the full path of the saved file to the OCR service
    ocr_text = await ocr_service.extract_text(doc.storage_path, document_type=doc.document_type)
    doc.ocr_text = ocr_text
    doc.status = DocumentStatus.EXTRACTED

    # 2. NLP Extraction (using the same NLP service as interviews)
    nlp_service = get_nlp_service()
    extraction = await nlp_service.extract_async(ocr_text, context="document")

    # Note: For mock OCR, it might still return some structured entities or we fallback to Ollama output
    # Since Ollama might output chief complaint, etc. we map it to generic extractions for documents
    for entity in extraction.entities:
        extraction_record = DocumentExtraction(
            document_id=doc.id,
            entity_type=entity.field_type,
            value=entity.value,
            confidence=entity.confidence,
        )
        db.add(extraction_record)

    db.commit()
    db.refresh(doc)



@router.get("/documents/{document_id}")
def get_document(document_id: str, db: Session = Depends(get_db),
                 current_user: User = Depends(require_physician)):
    doc = db.query(Document).filter(Document.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    return {
        "id": doc.id,
        "original_filename": doc.original_filename,
        "document_type": doc.document_type,
        "status": doc.status.value,
        "ocr_text": doc.ocr_text,
        "extractions": [
            {"id": e.id, "entity_type": e.entity_type, "value": e.value,
             "confidence": e.confidence, "is_verified": e.is_verified}
            for e in doc.extractions
        ],
    }


@router.post("/documents/{document_id}/verify")
def verify_document(document_id: str, db: Session = Depends(get_db),
                    current_user: User = Depends(require_physician)):
    doc = db.query(Document).filter(Document.id == document_id).first()
    if not doc:
        raise HTTPException(status_code=404, detail="Document not found")
    doc.status = DocumentStatus.VERIFIED
    for extraction in doc.extractions:
        extraction.is_verified = True
    db.commit()
    log = AuditLog(action="document_verified", resource_type="document", resource_id=document_id,
                   user_id=current_user.id)
    db.add(log)
    db.commit()
    return {"message": "Document verified", "id": document_id}


# ─── Red Flags ────────────────────────────────────────────────────────────────

@router.get("/redflags/active")
def get_active_redflags(db: Session = Depends(get_db),
                        current_user: User = Depends(require_physician)):
    flags = (db.query(RedFlag)
             .filter(RedFlag.status.in_([RedFlagStatus.DETECTED, RedFlagStatus.ACKNOWLEDGED]))
             .order_by(RedFlag.created_at.desc())
             .limit(50)
             .all())
    return {
        "count": len(flags),
        "red_flags": [
            {"id": f.id, "encounter_id": f.encounter_id, "rule_name": f.rule_name,
             "severity": f.severity.value, "reason": f.reason, "triggered_by": f.triggered_by,
             "status": f.status.value, "created_at": f.created_at.isoformat()}
            for f in flags
        ],
    }


@router.post("/redflags/{flag_id}/acknowledge")
def acknowledge_redflag(flag_id: str, db: Session = Depends(get_db),
                        current_user: User = Depends(require_physician)):
    flag = db.query(RedFlag).filter(RedFlag.id == flag_id).first()
    if not flag:
        raise HTTPException(status_code=404, detail="Red flag not found")
    flag.status = RedFlagStatus.ACKNOWLEDGED
    flag.acknowledged_by = current_user.id
    flag.acknowledged_at = datetime.now(timezone.utc)
    db.commit()
    log = AuditLog(action="red_flag_acknowledged", resource_type="red_flag",
                   resource_id=flag_id, user_id=current_user.id)
    db.add(log)
    db.commit()
    return {"message": "Red flag acknowledged", "id": flag_id}


# ─── AYUSH ────────────────────────────────────────────────────────────────────

class PrakritiSubmit(BaseModel):
    encounter_id: str
    answers: dict  # {question_id: "vata" | "pitta" | "kapha"}
    ahara: Optional[str] = None
    vihara: Optional[str] = None
    vikriti_notes: Optional[str] = None


@router.post("/ayush/prakriti", status_code=status.HTTP_201_CREATED)
def submit_prakriti(payload: PrakritiSubmit, db: Session = Depends(get_db)):
    from app.services.ayush.prakriti_engine import calculate_prakriti, get_prakriti_questions

    score = calculate_prakriti(payload.answers)

    assessment = AyushAssessment(
        encounter_id=payload.encounter_id,
        prakriti_result=score.result,
        vata_score=score.vata,
        pitta_score=score.pitta,
        kapha_score=score.kapha,
        ahara=payload.ahara,
        vihara=payload.vihara,
        vikriti_notes=payload.vikriti_notes,
        assessment_method="questionnaire",
    )
    db.add(assessment)
    db.commit()
    db.refresh(assessment)

    # Save individual answers
    questions = {q.id: q.text_en for q in get_prakriti_questions()}
    for q_id, answer in payload.answers.items():
        pa = PrakritiAnswer(
            assessment_id=assessment.id,
            question_id=q_id,
            question_text=questions.get(q_id, q_id),
            answer=answer,
        )
        db.add(pa)
    db.commit()

    return {
        "assessment_id": assessment.id,
        "prakriti_result": score.result,
        "vata_score": score.vata,
        "pitta_score": score.pitta,
        "kapha_score": score.kapha,
        "assessment_method": "questionnaire",
        "note": "Questionnaire-based assessment — requires physician review",
    }


@router.get("/ayush/{encounter_id}")
def get_ayush(encounter_id: str, db: Session = Depends(get_db),
              current_user: User = Depends(require_physician)):
    assessment = db.query(AyushAssessment).filter(
        AyushAssessment.encounter_id == encounter_id).first()
    if not assessment:
        return {"encounter_id": encounter_id, "assessment": None}
    return {
        "encounter_id": encounter_id,
        "prakriti_result": assessment.prakriti_result,
        "vata_score": assessment.vata_score,
        "pitta_score": assessment.pitta_score,
        "kapha_score": assessment.kapha_score,
        "ahara": assessment.ahara,
        "vihara": assessment.vihara,
        "vikriti_notes": assessment.vikriti_notes,
        "assessment_method": assessment.assessment_method,
        "note": "Questionnaire-based assessment — requires physician review",
    }


@router.get("/ayush/questions/prakriti")
def get_prakriti_questions_endpoint():
    from app.services.ayush.prakriti_engine import get_prakriti_questions
    questions = get_prakriti_questions()
    return {
        "questions": [
            {"id": q.id, "text_en": q.text_en, "text_hi": q.text_hi, "options": q.options}
            for q in questions
        ]
    }


# ─── Diagnosis ────────────────────────────────────────────────────────────────

class DiagnosisCreate(BaseModel):
    encounter_id: str
    diagnosis_text: str
    is_primary: bool = True
    physician_notes: Optional[str] = None


@router.post("/diagnoses", status_code=status.HTTP_201_CREATED)
def create_diagnosis(payload: DiagnosisCreate, db: Session = Depends(get_db),
                     current_user: User = Depends(require_physician)):
    """
    Physician enters and confirms a diagnosis.
    CRITICAL: Only physician can finalize. AI suggestions require physician input.
    """
    physician = current_user.physician
    if not physician:
        raise HTTPException(status_code=403, detail="Physician profile required")

    diagnosis = Diagnosis(
        encounter_id=payload.encounter_id,
        diagnosis_text=payload.diagnosis_text,
        status=DiagnosisStatus.PHYSICIAN_CONFIRMED,
        physician_id=physician.id,
        physician_notes=payload.physician_notes,
        is_primary=payload.is_primary,
        confirmed_at=datetime.now(timezone.utc),
    )
    db.add(diagnosis)
    db.commit()
    db.refresh(diagnosis)

    # Auto-lookup terminology
    from app.services.terminology.terminology_service import lookup_diagnosis
    mapping = lookup_diagnosis(payload.diagnosis_text)

    namaste_mapping = TerminologyMapping(
        diagnosis_id=diagnosis.id,
        system="NAMASTE",
        code=mapping.namaste.code,
        term=mapping.namaste.term,
        status=MappingStatus(mapping.namaste.status),
    )
    icd_mapping = TerminologyMapping(
        diagnosis_id=diagnosis.id,
        system="ICD-11-TM2",
        code=mapping.icd11_tm2.code,
        term=mapping.icd11_tm2.term,
        status=MappingStatus(mapping.icd11_tm2.status),
    )
    db.add(namaste_mapping)
    db.add(icd_mapping)

    log = AuditLog(action="diagnosis_confirmed", resource_type="diagnosis",
                   resource_id=diagnosis.id, user_id=current_user.id,
                   details={"text": payload.diagnosis_text})
    db.add(log)
    db.commit()

    return {
        "diagnosis_id": diagnosis.id,
        "diagnosis_text": diagnosis.diagnosis_text,
        "status": diagnosis.status.value,
        "namaste": {
            "code": namaste_mapping.code,
            "term": namaste_mapping.term,
            "status": namaste_mapping.status.value,
        },
        "icd11_tm2": {
            "code": icd_mapping.code,
            "term": icd_mapping.term,
            "status": icd_mapping.status.value,
        },
        "note": "Terminology mapping unavailable message shown if code is None"
    }


@router.get("/diagnoses/search")
def search_diagnoses(q: str, db: Session = Depends(get_db),
                     current_user: User = Depends(require_physician)):
    from app.services.terminology.terminology_service import search_diagnoses as svc_search
    results = svc_search(q)
    return {"query": q, "results": results}


# ─── FHIR ────────────────────────────────────────────────────────────────────

@router.post("/fhir/bundle")
def generate_fhir_bundle(encounter_id: str, db: Session = Depends(get_db),
                         current_user: User = Depends(require_physician)):
    enc = db.query(Encounter).filter(Encounter.id == encounter_id).first()
    if not enc:
        raise HTTPException(status_code=404, detail="Encounter not found")

    from app.services.fhir.fhir_builder import build_bundle
    bundle = build_bundle(
        patient=enc.patient,
        encounter=enc,
        findings=enc.clinical_findings,
        diagnoses=[d for d in enc.diagnoses if d.status == DiagnosisStatus.PHYSICIAN_CONFIRMED],
        documents=enc.documents,
        physician_id=enc.physician_id,
    )

    # Store in DB
    fhir_res = FhirResource(
        encounter_id=encounter_id,
        resource_type="Bundle",
        resource_json=bundle,
        is_validated=False,
    )
    db.add(fhir_res)
    log = AuditLog(action="fhir_generated", resource_type="encounter",
                   resource_id=encounter_id, user_id=current_user.id)
    db.add(log)
    db.commit()

    return bundle


@router.get("/fhir/metadata")
def fhir_metadata():
    return {
        "resourceType": "CapabilityStatement",
        "status": "active",
        "fhirVersion": "4.0.1",
        "software": {"name": "Arogya-Saathi", "version": "1.0.0"},
        "format": ["json"],
        "rest": [{
            "mode": "server",
            "resource": [
                {"type": "Patient"}, {"type": "Encounter"},
                {"type": "Condition"}, {"type": "Observation"},
                {"type": "DocumentReference"}, {"type": "Bundle"},
            ]
        }],
        "note": "Demo/MVP implementation — not production-validated",
    }


# ─── Physician Queue ──────────────────────────────────────────────────────────

@router.get("/physician/queue")
def get_physician_queue(db: Session = Depends(get_db),
                        current_user: User = Depends(require_physician)):
    """Returns today's patient queue for the physician dashboard."""
    from app.models.encounter import Encounter, EncounterPriority
    from app.models.patient import Patient
    from datetime import date

    encounters = (
        db.query(Encounter)
        .filter(Encounter.status.in_([
            EncounterStatus.PHYSICIAN_REVIEW.value,
            EncounterStatus.IN_PROGRESS.value,
            EncounterStatus.COMPLETED.value,
        ]))
        .order_by(Encounter.created_at.desc())
        .limit(50)
        .all()
    )

    queue = []
    for enc in encounters:
        patient = enc.patient
        has_urgent = any(r.severity.value == "urgent" for r in enc.red_flags)
        queue.append({
            "encounter_id": enc.id,
            "patient_id": patient.id,
            "patient_name": patient.name,
            "age": patient.age or (str(patient.dob) if patient.dob else "N/A"),
            "gender": patient.gender or "N/A",
            "chief_complaint": enc.chief_complaint or "Not specified",
            "status": enc.status.value,
            "priority": enc.priority.value,
            "has_red_flags": has_urgent or bool(enc.red_flags),
            "red_flag_count": len(enc.red_flags),
            "created_at": enc.created_at.isoformat(),
            "waiting_minutes": _calc_wait_minutes(enc.created_at),
        })

    # Sort: urgent first, then by waiting time
    queue.sort(key=lambda x: (0 if x["priority"] == "urgent" else 1 if x["priority"] == "moderate" else 2,
                               -x["waiting_minutes"]))
    return {"queue": queue, "total": len(queue)}


def _calc_wait_minutes(created_at) -> int:
    from datetime import timezone
    now = datetime.now(timezone.utc)
    diff = now - created_at.replace(tzinfo=timezone.utc) if created_at.tzinfo is None else now - created_at
    return max(0, int(diff.total_seconds() / 60))


# ─── ABHA Mock ────────────────────────────────────────────────────────────────

@router.post("/abha/verify")
def abha_verify(abha_number: str):
    """Mock ABHA verification — sandbox only."""
    return {
        "status": "demo",
        "message": "ABHA verification is in demo/sandbox mode",
        "abha_number": abha_number,
        "verified": True,
        "patient_name": "Demo Patient",
        "note": "This is a mock response. Connect to ABDM sandbox for real verification.",
    }


@router.post("/abha/consent/request")
def abha_consent_request(patient_id: str, purpose: str = "clinical_care"):
    """Mock ABHA consent request."""
    return {
        "status": "demo",
        "consent_request_id": f"MOCK-CONSENT-{patient_id[:8]}",
        "purpose": purpose,
        "note": "Mock ABHA consent — sandbox mode",
    }
