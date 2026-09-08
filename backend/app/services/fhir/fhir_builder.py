"""
Arogya-Saathi — FHIR R4 Bundle Generator

Generates FHIR-compatible JSON resources from Arogya-Saathi encounter data.
Minimum resources: Patient, Encounter, Condition, Observation, AllergyIntolerance,
DocumentReference, and wraps in a Bundle.

FHIR is generated AFTER physician confirmation — never from raw AI output alone.
"""
import uuid
from datetime import datetime, timezone
from typing import Any


def _now_iso() -> str:
    return datetime.now(timezone.utc).isoformat()


def build_patient_resource(patient: Any) -> dict:
    """Build FHIR R4 Patient resource."""
    resource = {
        "resourceType": "Patient",
        "id": patient.id,
        "meta": {
            "profile": ["http://hl7.org/fhir/StructureDefinition/Patient"],
            "lastUpdated": _now_iso(),
            "tag": [{"system": "http://arogyasaathi.in/tag", "code": "arogya-saathi-mvp"}]
        },
        "text": {
            "status": "generated",
            "div": f"<div xmlns='http://www.w3.org/1999/xhtml'>Patient: {patient.name}</div>"
        },
        "name": [{"use": "official", "text": patient.name}],
        "gender": _map_gender(getattr(patient, "gender", None)),
        "communication": [
            {"language": {"coding": [{"system": "urn:ietf:bcp:47", "code": getattr(patient, "preferred_language", "en")}]}}
        ],
    }

    if getattr(patient, "dob", None):
        resource["birthDate"] = patient.dob.isoformat()
    elif getattr(patient, "age", None):
        resource["extension"] = [{
            "url": "http://arogyasaathi.in/fhir/extension/age-text",
            "valueString": str(patient.age)
        }]

    if getattr(patient, "mobile", None):
        resource["telecom"] = [{"system": "phone", "value": patient.mobile, "use": "mobile"}]

    if getattr(patient, "abha_number", None):
        resource["identifier"] = [{
            "system": "https://healthid.ndhm.gov.in",
            "value": patient.abha_number,
            "type": {"coding": [{"system": "http://terminology.hl7.org/CodeSystem/v2-0203", "code": "NI"}]}
        }]

    return resource


def build_encounter_resource(encounter: Any, patient_id: str, physician_id: str | None = None) -> dict:
    """Build FHIR R4 Encounter resource."""
    resource = {
        "resourceType": "Encounter",
        "id": encounter.id,
        "meta": {"lastUpdated": _now_iso()},
        "status": _map_encounter_status(getattr(encounter, "status", "finished")),
        "class": {
            "system": "http://terminology.hl7.org/CodeSystem/v3-ActCode",
            "code": "AMB",
            "display": "Ambulatory"
        },
        "subject": {"reference": f"Patient/{patient_id}"},
        "period": {"start": encounter.created_at.isoformat()},
        "reasonCode": [],
    }

    if getattr(encounter, "completed_at", None):
        resource["period"]["end"] = encounter.completed_at.isoformat()

    if getattr(encounter, "chief_complaint", None):
        resource["reasonCode"].append({
            "text": encounter.chief_complaint
        })

    if physician_id:
        resource["participant"] = [{
            "type": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/v3-ParticipationType", "code": "ATND"}]}],
            "individual": {"reference": f"Practitioner/{physician_id}"}
        }]

    return resource


def build_condition_resource(diagnosis: Any, patient_id: str, encounter_id: str) -> dict:
    """Build FHIR R4 Condition resource from a confirmed diagnosis."""
    resource = {
        "resourceType": "Condition",
        "id": diagnosis.id,
        "meta": {"lastUpdated": _now_iso()},
        "clinicalStatus": {
            "coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-clinical", "code": "active"}]
        },
        "verificationStatus": {
            "coding": [{"system": "http://terminology.hl7.org/CodeSystem/condition-ver-status", "code": "confirmed"}]
        },
        "subject": {"reference": f"Patient/{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "code": {"text": diagnosis.diagnosis_text},
        "recordedDate": diagnosis.created_at.isoformat() if hasattr(diagnosis, "created_at") else _now_iso(),
    }

    # Add terminology mappings if available
    codings = []
    if hasattr(diagnosis, "terminology_mappings"):
        for mapping in diagnosis.terminology_mappings:
            if getattr(mapping, "code", None):
                system_url = (
                    "http://www.who.int/classifications/icd/adaptations/multiuse"
                    if "ICD" in mapping.system else
                    "http://arogyasaathi.in/fhir/CodeSystem/namaste"
                )
                codings.append({
                    "system": system_url,
                    "code": mapping.code,
                    "display": mapping.term,
                })

    if codings:
        resource["code"]["coding"] = codings

    return resource


def build_observation_resource(finding: Any, patient_id: str, encounter_id: str) -> dict:
    """Build FHIR R4 Observation from a clinical finding."""
    loinc_map = {
        "chief_complaint": {"code": "75326-9", "display": "Problem"},
        "severity": {"code": "72514-3", "display": "Pain severity"},
        "duration": {"code": "103335-0", "display": "Duration of symptom"},
        "associated": {"code": "75325-1", "display": "Symptom"},
        "radiation": {"code": "75325-1", "display": "Radiating symptom"},
        "hpi": {"code": "10164-2", "display": "History of present illness"},
    }

    field_type = getattr(finding, "field_type", "").value if hasattr(finding.field_type, "value") else str(getattr(finding, "field_type", ""))
    loinc = loinc_map.get(field_type, {"code": "75325-1", "display": "Symptom"})

    return {
        "resourceType": "Observation",
        "id": str(uuid.uuid4()),
        "meta": {"lastUpdated": _now_iso()},
        "status": "final",
        "category": [{"coding": [{"system": "http://terminology.hl7.org/CodeSystem/observation-category", "code": "survey"}]}],
        "code": {"coding": [{"system": "http://loinc.org", "code": loinc["code"], "display": loinc["display"]}]},
        "subject": {"reference": f"Patient/{patient_id}"},
        "encounter": {"reference": f"Encounter/{encounter_id}"},
        "valueString": finding.value,
        "note": [{"text": f"Source: {finding.source.value if hasattr(finding.source, 'value') else finding.source}"}],
    }


def build_document_reference_resource(doc: Any, patient_id: str, encounter_id: str) -> dict:
    """Build FHIR R4 DocumentReference from uploaded document."""
    return {
        "resourceType": "DocumentReference",
        "id": doc.id,
        "meta": {"lastUpdated": _now_iso()},
        "status": "current",
        "docStatus": "final",
        "type": {"text": getattr(doc, "document_type", "unknown")},
        "subject": {"reference": f"Patient/{patient_id}"},
        "context": {"encounter": [{"reference": f"Encounter/{encounter_id}"}]},
        "content": [{"attachment": {"title": doc.original_filename, "creation": doc.created_at.isoformat()}}],
    }


def build_bundle(
    patient: Any,
    encounter: Any,
    findings: list[Any] = None,
    diagnoses: list[Any] = None,
    documents: list[Any] = None,
    physician_id: str | None = None,
) -> dict:
    """
    Build a complete FHIR R4 Bundle containing all resources.
    """
    bundle_id = str(uuid.uuid4())
    entries = []

    # Patient
    patient_res = build_patient_resource(patient)
    entries.append({
        "fullUrl": f"urn:uuid:{patient.id}",
        "resource": patient_res,
    })

    # Encounter
    enc_res = build_encounter_resource(encounter, patient.id, physician_id)
    entries.append({
        "fullUrl": f"urn:uuid:{encounter.id}",
        "resource": enc_res,
    })

    # Conditions (diagnoses)
    for diag in (diagnoses or []):
        cond_res = build_condition_resource(diag, patient.id, encounter.id)
        entries.append({"fullUrl": f"urn:uuid:{diag.id}", "resource": cond_res})

    # Observations (clinical findings)
    for finding in (findings or []):
        obs_res = build_observation_resource(finding, patient.id, encounter.id)
        entries.append({"fullUrl": f"urn:uuid:{obs_res['id']}", "resource": obs_res})

    # Document References
    for doc in (documents or []):
        if getattr(doc, "status", "") in ("verified", "extracted", "needs_review"):
            doc_res = build_document_reference_resource(doc, patient.id, encounter.id)
            entries.append({"fullUrl": f"urn:uuid:{doc.id}", "resource": doc_res})

    return {
        "resourceType": "Bundle",
        "id": bundle_id,
        "meta": {
            "lastUpdated": _now_iso(),
            "tag": [
                {"system": "http://arogyasaathi.in/tag", "code": "generated"},
                {"system": "http://arogyasaathi.in/tag", "code": "demo"},
            ],
        },
        "type": "document",
        "timestamp": _now_iso(),
        "total": len(entries),
        "entry": entries,
    }


def _map_gender(gender: str | None) -> str:
    if not gender:
        return "unknown"
    g = gender.lower()
    if g in ("male", "m", "पुरुष"):
        return "male"
    if g in ("female", "f", "महिला"):
        return "female"
    return "other"


def _map_encounter_status(status: Any) -> str:
    s = str(status).lower()
    if "completed" in s:
        return "finished"
    if "in_progress" in s or "physician" in s:
        return "in-progress"
    return "arrived"
