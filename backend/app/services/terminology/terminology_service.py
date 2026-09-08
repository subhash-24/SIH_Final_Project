"""
Arogya-Saathi — Terminology Mapping Service
Maps free-text diagnosis to NAMASTE and ICD-11 TM2 codes.
NEVER invents codes — returns "unavailable" if not found.
"""
import json
import re
from pathlib import Path
from dataclasses import dataclass

DATA_FILE = Path(__file__).parent / "terminology_data.json"


@dataclass
class TermMapping:
    system: str
    code: str | None
    term: str | None
    status: str  # "mapped" | "unavailable"


@dataclass
class DiagnosisMapping:
    namaste: TermMapping
    icd11_tm2: TermMapping
    matched_pattern: str | None = None


def _load_data() -> list[dict]:
    with open(DATA_FILE, encoding="utf-8") as f:
        return json.load(f)["mappings"]


_CACHE: list[dict] | None = None


def _get_data() -> list[dict]:
    global _CACHE
    if _CACHE is None:
        _CACHE = _load_data()
    return _CACHE


def lookup_diagnosis(diagnosis_text: str) -> DiagnosisMapping:
    """
    Search for NAMASTE and ICD-11 TM2 mappings for a given diagnosis text.
    Case-insensitive pattern matching against curated data.

    If not found, returns status="unavailable" — never invents codes.
    """
    text_lower = diagnosis_text.lower().strip()
    data = _get_data()

    for entry in data:
        for pattern in entry["diagnosis_text_patterns"]:
            if pattern.lower() in text_lower or text_lower in pattern.lower():
                namaste_data = entry.get("namaste", {})
                icd_data = entry.get("icd11_tm2", {})
                return DiagnosisMapping(
                    namaste=TermMapping(
                        system="NAMASTE",
                        code=namaste_data.get("code"),
                        term=namaste_data.get("term"),
                        status="mapped" if namaste_data.get("code") else "unavailable",
                    ),
                    icd11_tm2=TermMapping(
                        system="ICD-11-TM2",
                        code=icd_data.get("code"),
                        term=icd_data.get("term"),
                        status="mapped" if icd_data.get("code") else "unavailable",
                    ),
                    matched_pattern=pattern,
                )

    # Not found — return unavailable (NEVER invent codes)
    return DiagnosisMapping(
        namaste=TermMapping(
            system="NAMASTE",
            code=None,
            term=None,
            status="unavailable",
        ),
        icd11_tm2=TermMapping(
            system="ICD-11-TM2",
            code=None,
            term=None,
            status="unavailable",
        ),
        matched_pattern=None,
    )


def search_diagnoses(query: str, limit: int = 10) -> list[dict]:
    """Search for diagnoses matching a query string."""
    query_lower = query.lower().strip()
    data = _get_data()
    results = []

    for entry in data:
        for pattern in entry["diagnosis_text_patterns"]:
            if query_lower in pattern.lower():
                results.append({
                    "matched_term": pattern,
                    "namaste_code": entry.get("namaste", {}).get("code"),
                    "namaste_term": entry.get("namaste", {}).get("term"),
                    "icd11_code": entry.get("icd11_tm2", {}).get("code"),
                    "icd11_term": entry.get("icd11_tm2", {}).get("term"),
                })
                break  # only one result per entry
        if len(results) >= limit:
            break

    return results
