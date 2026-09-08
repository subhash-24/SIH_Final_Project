"""
Arogya-Saathi — Deterministic Red-Flag Rule Engine
============================================================
CRITICAL SAFETY REQUIREMENT:
- Rules are deterministic and rule-based (no LLM dependency)
- Every trigger is explainable
- Never labels as diagnosis — only "symptom pattern"
- Never says "AI diagnosed" — only "Emergency symptom pattern detected"
============================================================
"""
from dataclasses import dataclass, field
from typing import NamedTuple
import re


# ─── Symptom Normalization Map ───────────────────────────────────────────────
# Maps extracted terms → canonical symptom keys used in rules

SYMPTOM_KEYWORDS: dict[str, str] = {
    # Cardiac
    "chest pain": "chest_pain",
    "chest ache": "chest_pain",
    "chest tightness": "chest_pain",
    "chest pressure": "chest_pain",
    "chest discomfort": "chest_pain",
    "sweating": "sweating",
    "diaphoresis": "sweating",
    "perspiration": "sweating",
    "radiation to arm": "radiation_arm",
    "radiating to arm": "radiation_arm",
    "radiation to left arm": "radiation_arm",
    "left arm pain": "radiation_arm",
    "arm pain": "radiation_arm",
    "jaw pain": "radiation_jaw",
    "radiation to jaw": "radiation_jaw",
    "back pain": "back_pain",
    "radiation to back": "back_pain",
    "shortness of breath": "dyspnea",
    "difficulty breathing": "dyspnea",
    "breathlessness": "dyspnea",
    "sob": "dyspnea",
    "nausea": "nausea",
    "vomiting": "vomiting",
    "palpitations": "palpitations",
    # Neurological
    "severe headache": "severe_headache",
    "sudden headache": "severe_headache",
    "worst headache": "severe_headache",
    "thunderclap headache": "severe_headache",
    "facial droop": "facial_droop",
    "arm weakness": "limb_weakness",
    "leg weakness": "limb_weakness",
    "weakness": "limb_weakness",
    "slurred speech": "slurred_speech",
    "speech difficulty": "slurred_speech",
    "vision loss": "vision_change",
    "blurred vision": "vision_change",
    "sudden vision": "vision_change",
    "confusion": "confusion",
    "disorientation": "confusion",
    "loss of consciousness": "syncope",
    "syncope": "syncope",
    "fainting": "syncope",
    "seizure": "seizure",
    "convulsion": "seizure",
    # Respiratory
    "severe breathlessness": "severe_dyspnea",
    "cannot breathe": "severe_dyspnea",
    "unable to breathe": "severe_dyspnea",
    "coughing blood": "hemoptysis",
    "blood in sputum": "hemoptysis",
    "hemoptysis": "hemoptysis",
    # GI
    "severe abdominal pain": "severe_abdominal_pain",
    "abdominal rigidity": "severe_abdominal_pain",
    "blood in stool": "gi_bleeding",
    "bloody stool": "gi_bleeding",
    "melena": "gi_bleeding",
    "vomiting blood": "hematemesis",
    "hematemesis": "hematemesis",
    # Obstetric
    "heavy bleeding": "heavy_bleeding",
    "vaginal bleeding": "heavy_bleeding",
    # Fever
    "high fever": "high_fever",
    "fever": "fever",
    "very high fever": "high_fever",
    "rash": "rash",
    "stiff neck": "neck_stiffness",
    "neck stiffness": "neck_stiffness",
    "photophobia": "photophobia",
}


# ─── Rule Definitions ────────────────────────────────────────────────────────

@dataclass
class RedFlagRule:
    id: str
    name: str
    required_symptoms: list[str]          # ALL must be present
    supporting_symptoms: list[str]        # at least `support_threshold` must be present
    support_threshold: int                # min supporting symptoms needed
    severity: str                         # "urgent" | "warning" | "attention"
    patient_message: str                  # what to show patient
    physician_reason: str                 # clinical explanation for physician
    category: str                         # cardiac, neurological, etc.


RED_FLAG_RULES: list[RedFlagRule] = [
    RedFlagRule(
        id="cardiac_emergency",
        name="Possible Cardiac Emergency",
        required_symptoms=["chest_pain"],
        supporting_symptoms=["sweating", "radiation_arm", "radiation_jaw", "nausea", "dyspnea", "palpitations"],
        support_threshold=1,
        severity="urgent",
        patient_message=(
            "Your symptoms may need urgent attention. "
            "Please remain seated and a physician has been alerted."
        ),
        physician_reason=(
            "Chest pain with associated symptoms (sweating, arm/jaw radiation, dyspnea, or nausea) "
            "requires urgent cardiac assessment. Rule out Acute Coronary Syndrome."
        ),
        category="cardiac",
    ),
    RedFlagRule(
        id="stroke_warning",
        name="Possible Stroke",
        required_symptoms=[],
        supporting_symptoms=["facial_droop", "limb_weakness", "slurred_speech", "vision_change", "severe_headache", "confusion"],
        support_threshold=2,
        severity="urgent",
        patient_message=(
            "Your symptoms need immediate medical attention. "
            "A physician has been alerted urgently."
        ),
        physician_reason=(
            "Combination of neurological symptoms (facial droop, limb weakness, speech difficulty, "
            "vision change, severe headache, or confusion) may indicate stroke. "
            "Consider FAST assessment and urgent neurological evaluation."
        ),
        category="neurological",
    ),
    RedFlagRule(
        id="thunderclap_headache",
        name="Severe Sudden Headache",
        required_symptoms=["severe_headache"],
        supporting_symptoms=["neck_stiffness", "photophobia", "vomiting", "syncope"],
        support_threshold=1,
        severity="urgent",
        patient_message=(
            "Your symptoms may need urgent attention. "
            "Please remain seated and a physician has been alerted."
        ),
        physician_reason=(
            "Sudden severe ('thunderclap') headache with meningeal signs (neck stiffness, photophobia) "
            "or vomiting may indicate subarachnoid hemorrhage or meningitis. Urgent assessment required."
        ),
        category="neurological",
    ),
    RedFlagRule(
        id="meningitis_warning",
        name="Possible Meningitis",
        required_symptoms=["fever", "neck_stiffness"],
        supporting_symptoms=["severe_headache", "photophobia", "rash", "confusion"],
        support_threshold=1,
        severity="urgent",
        patient_message=(
            "Your symptoms need urgent medical evaluation. "
            "A physician has been alerted."
        ),
        physician_reason=(
            "Fever with neck stiffness and additional meningeal signs (headache, photophobia, rash) "
            "requires urgent evaluation for meningitis or encephalitis."
        ),
        category="infection",
    ),
    RedFlagRule(
        id="severe_dyspnea",
        name="Severe Breathing Difficulty",
        required_symptoms=["severe_dyspnea"],
        supporting_symptoms=["chest_pain", "sweating", "cyanosis", "confusion"],
        support_threshold=0,
        severity="urgent",
        patient_message=(
            "Severe difficulty breathing needs immediate attention. "
            "A physician has been alerted urgently."
        ),
        physician_reason=(
            "Severe acute dyspnea may indicate respiratory failure, pulmonary embolism, "
            "severe asthma, or acute LVF. Urgent assessment required."
        ),
        category="respiratory",
    ),
    RedFlagRule(
        id="gi_bleed",
        name="Possible Gastrointestinal Bleeding",
        required_symptoms=[],
        supporting_symptoms=["gi_bleeding", "hematemesis", "syncope"],
        support_threshold=1,
        severity="urgent",
        patient_message=(
            "Your symptoms need prompt medical evaluation. "
            "A physician has been alerted."
        ),
        physician_reason=(
            "Signs of gastrointestinal bleeding (melena, hematemesis, blood in stool) "
            "with or without syncope require urgent assessment."
        ),
        category="gastrointestinal",
    ),
]


# ─── Detection Logic ─────────────────────────────────────────────────────────

class RedFlagResult(NamedTuple):
    triggered: bool
    rule_id: str
    rule_name: str
    severity: str
    patient_message: str
    physician_reason: str
    triggered_by: list[str]
    category: str


def normalize_symptoms(text: str) -> set[str]:
    """
    Convert free text into canonical symptom keys.
    Case-insensitive multi-word matching.
    """
    text_lower = text.lower()
    found: set[str] = set()
    # Sort by length desc so longer phrases match before shorter substrings
    sorted_keywords = sorted(SYMPTOM_KEYWORDS.keys(), key=len, reverse=True)
    for phrase in sorted_keywords:
        if phrase in text_lower:
            found.add(SYMPTOM_KEYWORDS[phrase])
    return found


def evaluate_red_flags(
    symptoms: set[str] | None = None,
    clinical_text: str | None = None,
) -> list[RedFlagResult]:
    """
    Evaluate all red-flag rules against the provided symptoms.

    Args:
        symptoms: Set of canonical symptom keys (e.g. {"chest_pain", "sweating"})
        clinical_text: Free text to normalize if symptoms set not provided

    Returns:
        List of triggered RedFlagResult objects (may be empty)
    """
    if symptoms is None:
        symptoms = set()
    if clinical_text:
        symptoms = symptoms | normalize_symptoms(clinical_text)

    triggered: list[RedFlagResult] = []

    for rule in RED_FLAG_RULES:
        # Check required symptoms (ALL must be present)
        if rule.required_symptoms:
            if not all(s in symptoms for s in rule.required_symptoms):
                continue

        # Check supporting symptoms (at least threshold must be present)
        matched_supporting = [s for s in rule.supporting_symptoms if s in symptoms]
        if len(matched_supporting) < rule.support_threshold:
            continue

        # Rule triggered
        triggered_by = list(rule.required_symptoms) + matched_supporting
        triggered.append(RedFlagResult(
            triggered=True,
            rule_id=rule.id,
            rule_name=rule.name,
            severity=rule.severity,
            patient_message=rule.patient_message,
            physician_reason=rule.physician_reason,
            triggered_by=triggered_by,
            category=rule.category,
        ))

    return triggered


def get_highest_severity(results: list[RedFlagResult]) -> str | None:
    """Return highest severity from a list of results."""
    if not results:
        return None
    order = {"urgent": 0, "warning": 1, "attention": 2}
    return min(results, key=lambda r: order.get(r.severity, 99)).severity
