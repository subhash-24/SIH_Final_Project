"""
Arogya-Saathi — Mock Clinical NLP / Extraction Service

Extracts structured clinical fields from transcript text.
Uses regex + keyword matching for MVP.
Interface identical to a production spaCy/Transformers service.
"""
import re
from dataclasses import dataclass, field


@dataclass
class ClinicalEntity:
    field_type: str
    value: str
    source: str = "ai_extracted"
    confidence: float = 0.88
    needs_review: bool = True


@dataclass
class ExtractionResult:
    entities: list[ClinicalEntity]
    normalized_symptoms: set[str]
    raw_text: str
    is_mock: bool = True


# ─── Pattern matching rules ──────────────────────────────────────────────────

CHIEF_COMPLAINT_PATTERNS = [
    r"(chest pain|seene mein dard|सीने में दर्द)",
    r"(fever|bukhar|बुखार)",
    r"(headache|sar dard|सिर दर्द)",
    r"(cough|khansi|खांसी)",
    r"(breathlessness|saans lene mein takleef)",
    r"(abdominal pain|pet dard|पेट दर्द)",
    r"(knee pain|ghutne ka dard)",
    r"(fatigue|thakaan|थकान)",
    r"(nausea|ji machalna|जी मचलना)",
    r"(vomiting|ulti|उल्टी)",
]

DURATION_PATTERNS = [
    r"(\d+\s*(?:day|din|hour|ghante|week|hafte|month|mahine)s?)",
    r"(since\s+(?:yesterday|kal se|morning|subah se))",
    r"(for\s+(?:the\s+)?(?:last\s+)?\d+\s+\w+)",
    r"(pichle\s+\d+\s+\w+)",
    r"(do ghante|teen din|ek hafte)",
]

SEVERITY_PATTERNS = [
    (r"\b(bahut tej|severe|very severe|unbearable|extreme)\b", "Severe"),
    (r"\b(tej|moderate|medium|moderate)\b", "Moderate"),
    (r"\b(mild|halka|thoda|slight)\b", "Mild"),
]

RADIATION_PATTERNS = [
    (r"(baaye haath|left arm|baye haath)", "Left arm"),
    (r"(right arm|daaye haath)", "Right arm"),
    (r"(jaw|jaws|chin)", "Jaw"),
    (r"(back|peethe|kamar)", "Back"),
    (r"(shoulder|kandha)", "Shoulder"),
]

ASSOCIATED_PATTERNS = [
    (r"(pasina|sweating|diaphoresis|perspiration)", "Sweating"),
    (r"(nausea|ji machalna|nausea)", "Nausea"),
    (r"(vomiting|ulti)", "Vomiting"),
    (r"(breathless|saans lene mein|dyspnea|shortness of breath)", "Shortness of breath"),
    (r"(palpitation|dhadkan tez|heart racing)", "Palpitations"),
    (r"(dizziness|chakkar|giddiness)", "Dizziness"),
    (r"(fever|bukhar)", "Fever"),
    (r"(cough|khansi)", "Cough"),
]


def extract_clinical_entities(text: str) -> ExtractionResult:
    """
    Extract structured clinical entities from free text.
    Works on Hindi (transliterated), Hindi (Devanagari), and English.
    """
    text_lower = text.lower()
    entities: list[ClinicalEntity] = []
    normalized_symptoms: set[str] = set()

    # Chief Complaint
    for pattern in CHIEF_COMPLAINT_PATTERNS:
        match = re.search(pattern, text_lower)
        if match:
            complaint = match.group(1).title()
            entities.append(ClinicalEntity(
                field_type="chief_complaint",
                value=complaint,
                confidence=0.92,
            ))
            # Add to normalized symptoms
            normalized_symptoms.add(complaint.lower().replace(" ", "_"))
            break

    # Duration
    for pattern in DURATION_PATTERNS:
        match = re.search(pattern, text_lower)
        if match:
            duration_text = match.group(1)
            # Normalize common Hindi
            duration_text = duration_text.replace("do ghante", "2 hours").replace("teen din", "3 days")
            entities.append(ClinicalEntity(
                field_type="duration",
                value=duration_text,
                confidence=0.85,
            ))
            break

    # Severity
    for pattern, label in SEVERITY_PATTERNS:
        if re.search(pattern, text_lower):
            entities.append(ClinicalEntity(
                field_type="severity",
                value=label,
                confidence=0.80,
            ))
            break

    # Radiation
    for pattern, label in RADIATION_PATTERNS:
        if re.search(pattern, text_lower):
            entities.append(ClinicalEntity(
                field_type="radiation",
                value=label,
                confidence=0.83,
            ))

    # Associated Symptoms
    associated = []
    for pattern, label in ASSOCIATED_PATTERNS:
        if re.search(pattern, text_lower):
            associated.append(label)
            normalized_symptoms.add(label.lower().replace(" ", "_"))

    if associated:
        entities.append(ClinicalEntity(
            field_type="associated",
            value=", ".join(associated),
            confidence=0.82,
        ))

    # Build HPI summary
    if entities:
        hpi_parts = []
        cc = next((e.value for e in entities if e.field_type == "chief_complaint"), None)
        dur = next((e.value for e in entities if e.field_type == "duration"), None)
        sev = next((e.value for e in entities if e.field_type == "severity"), None)
        rad = next((e.value for e in entities if e.field_type == "radiation"), None)

        if cc:
            hpi_parts.append(f"Patient presents with {cc}")
        if dur:
            hpi_parts.append(f"for {dur}")
        if sev:
            hpi_parts.append(f"described as {sev.lower()}")
        if rad:
            hpi_parts.append(f"radiating to {rad.lower()}")
        if associated:
            hpi_parts.append(f"with associated {', '.join(a.lower() for a in associated)}")

        hpi = ". ".join(hpi_parts) + "." if hpi_parts else text
        entities.append(ClinicalEntity(
            field_type="hpi",
            value=hpi,
            confidence=0.78,
        ))

    # Also add symptom keys for red-flag engine
    from app.services.rules.red_flag_engine import normalize_symptoms as rfe_normalize
    normalized_symptoms |= rfe_normalize(text)

    return ExtractionResult(
        entities=entities,
        normalized_symptoms=normalized_symptoms,
        raw_text=text,
        is_mock=True,
    )


class MockClinicalNLPService:
    """Clinical extraction service — regex + keyword for MVP."""

    def extract(self, text: str) -> ExtractionResult:
        return extract_clinical_entities(text)

    async def extract_async(self, text: str) -> ExtractionResult:
        import asyncio
        await asyncio.sleep(0.3)
        return extract_clinical_entities(text)


def get_nlp_service():
    from app.core.config import settings
    if settings.nlp_service == "mock":
        return MockClinicalNLPService()
    return MockClinicalNLPService()
