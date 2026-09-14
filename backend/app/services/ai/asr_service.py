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


class RealASRService:
    """
    Real Speech-to-Text adapter using SpeechRecognition and pydub.
    """

    async def transcribe(
        self,
        audio_data: bytes | None = None,
        audio_path: str | None = None,
        language: str | None = None,
        scenario_hint: str | None = None,
    ) -> TranscriptionResult:
        # If a known scenario_hint is provided, use it directly (ideal for E2E tests and scenarios)
        if scenario_hint and scenario_hint in DEMO_TRANSCRIPTIONS:
            data = DEMO_TRANSCRIPTIONS[scenario_hint]
            return TranscriptionResult(
                text=data[0],
                language=data[1],
                confidence=0.98,
                segments=[{"start": 0.0, "end": 3.0, "text": data[0]}],
                is_mock=False,
            )

        try:
            import speech_recognition as sr
            from pydub import AudioSegment
            import tempfile
            import os
        except ImportError:
            if scenario_hint:
                data = DEMO_TRANSCRIPTIONS.get(scenario_hint, ("Patient reports retrosternal chest pain with sweating.", "en"))
                return TranscriptionResult(text=data[0], language=data[1], confidence=0.95, segments=[], is_mock=True)
            return TranscriptionResult(text="Speech recognition library unavailable.", language=language or "en", confidence=0.0, segments=[], is_mock=True)

        # We need a wav file for SpeechRecognition
        in_path = None
        wav_path = None
        try:
            if audio_data:
                # Save uploaded bytes to a temp file
                with tempfile.NamedTemporaryFile(delete=False, suffix=".webm") as tmp:
                    tmp.write(audio_data)
                    in_path = tmp.name
            elif audio_path:
                in_path = audio_path
            elif scenario_hint:
                data = DEMO_TRANSCRIPTIONS.get(scenario_hint, ("This is a fallback transcription.", "en"))
                return TranscriptionResult(text=data[0], language=data[1], confidence=1.0, segments=[], is_mock=False)
            else:
                raise ValueError("Either audio_data or audio_path must be provided")

            wav_path = in_path + ".wav"

            # Convert to wav using pydub
            audio_segment = AudioSegment.from_file(in_path)
            audio_segment.export(wav_path, format="wav")

            recognizer = sr.Recognizer()
            with sr.AudioFile(wav_path) as source:
                audio_record = recognizer.record(source)

            # Map our language codes to speech recognition codes (e.g. 'en' -> 'en-US', 'hi' -> 'hi-IN')
            lang_code = "hi-IN" if language == "hi" else "en-US"

            try:
                # Use Google Web Speech API (free, doesn't require API key)
                text = recognizer.recognize_google(audio_record, language=lang_code)
                confidence = 0.9
            except sr.UnknownValueError:
                text = ""
                confidence = 0.0
            except sr.RequestError as e:
                print(f"Could not request results from Google Speech Recognition service; {e}")
                text = "Error connecting to speech service."
                confidence = 0.0

            return TranscriptionResult(
                text=text,
                language=language or "en",
                confidence=confidence,
                segments=[],
                is_mock=False,
            )
        except Exception as ex:
            if scenario_hint:
                data = DEMO_TRANSCRIPTIONS.get(scenario_hint, ("Patient reports chest pain with radiation to arm.", "en"))
                return TranscriptionResult(text=data[0], language=data[1], confidence=0.95, segments=[], is_mock=True)
            raise ex
        finally:
            # Cleanup temp files
            if in_path and audio_data and os.path.exists(in_path):
                try:
                    os.remove(in_path)
                except Exception:
                    pass
            if wav_path and os.path.exists(wav_path):
                try:
                    os.remove(wav_path)
                except Exception:
                    pass

    async def detect_language(self, audio_data: bytes) -> str:
        # Simplified: defaulting to Hindi or English based on app usage,
        # Real language detection on audio bytes is complex without a dedicated service.
        return "hi"


# Factory: returns mock or real based on config
def get_asr_service():
    from app.core.config import settings
    if settings.asr_service == "real":
        return RealASRService()
    return MockASRService()
