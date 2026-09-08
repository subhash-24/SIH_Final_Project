"""
Arogya-Saathi — Mock ASR Service (Speech-to-Text)

Interface: same as real Whisper adapter.
Returns realistic clinical transcriptions for demo scenarios.
"""
import asyncio
import random
from dataclasses import dataclass


@dataclass
class TranscriptionResult:
    text: str
    language: str
    confidence: float
    segments: list[dict]
    is_mock: bool = True


# Demo transcriptions keyed by scenario hint in audio metadata
DEMO_TRANSCRIPTIONS = {
    "chest": (
        "Mujhe do ghante se bahut tej seene mein dard ho raha hai. "
        "Dard mere baaye haath mein bhi ja raha hai aur mujhe bahut pasina aa raha hai.",
        "hi"
    ),
    "chest_en": (
        "I have been having severe chest pain for the last two hours. "
        "The pain is going to my left arm and I am sweating a lot.",
        "en"
    ),
    "fever": (
        "Mujhe teen din se tez bukhar hai. Gaala bhi dard kar raha hai aur khांsi aa rahi hai.",
        "hi"
    ),
    "fever_en": (
        "I have had high fever for three days with sore throat and cough.",
        "en"
    ),
    "diabetes": (
        "Mujhe diabetes hai. Blood sugar control nahi ho raha. "
        "Pair mein sunn pan bhi aa gaya hai.",
        "hi"
    ),
    "fatigue": (
        "Mujhe bahut thakaan rehti hai. Paachan mein bhi problem hai. "
        "Khana theek se nahi pachta.",
        "hi"
    ),
    "injury": (
        "My knee got injured during football. There is swelling and I cannot walk properly.",
        "en"
    ),
}


class MockASRService:
    """
    Mock Speech-to-Text adapter.
    Simulates Whisper behavior with realistic demo data.
    In production, replace with WhisperASRService with same interface.
    """

    async def transcribe(
        self,
        audio_data: bytes | None = None,
        audio_path: str | None = None,
        language: str | None = None,
        scenario_hint: str | None = None,
    ) -> TranscriptionResult:
        """
        Simulate transcription with a small realistic delay.
        scenario_hint: optional key from DEMO_TRANSCRIPTIONS for demo mode.
        """
        # Simulate processing delay
        await asyncio.sleep(random.uniform(0.8, 2.0))

        if scenario_hint and scenario_hint in DEMO_TRANSCRIPTIONS:
            text, lang = DEMO_TRANSCRIPTIONS[scenario_hint]
        elif language and language == "hi":
            text, lang = DEMO_TRANSCRIPTIONS["chest"]
        else:
            text, lang = DEMO_TRANSCRIPTIONS["chest_en"]

        return TranscriptionResult(
            text=text,
            language=lang,
            confidence=0.92,
            segments=[
                {"start": 0.0, "end": 3.5, "text": text[:len(text)//2]},
                {"start": 3.5, "end": 6.0, "text": text[len(text)//2:]},
            ],
            is_mock=True,
        )

    async def detect_language(self, audio_data: bytes) -> str:
        await asyncio.sleep(0.3)
        return "hi"  # Default demo language


# Factory: returns mock or real based on config
def get_asr_service():
    from app.core.config import settings
    if settings.asr_service == "mock":
        return MockASRService()
    # Future: return WhisperASRService()
    return MockASRService()
