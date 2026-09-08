"""
Arogya-Saathi — Prakriti (Ayurvedic Constitution) Scoring Engine

Deterministic questionnaire-based scoring.
20 questions across Vata / Pitta / Kapha domains.
Result: dominant dosha label + numeric scores.
Label: "Questionnaire-based assessment" — never "AI diagnosed".
"""
from dataclasses import dataclass


@dataclass
class PrakritiQuestion:
    id: str
    text_en: str
    text_hi: str
    options: dict[str, str]   # {"vata": "...", "pitta": "...", "kapha": "..."}


@dataclass
class PrakritiScore:
    vata: float
    pitta: float
    kapha: float
    result: str          # e.g. "Pitta-Vata"
    primary: str         # "Vata" / "Pitta" / "Kapha"
    secondary: str | None
    assessment_method: str = "questionnaire"


PRAKRITI_QUESTIONS: list[PrakritiQuestion] = [
    PrakritiQuestion(
        id="body_frame",
        text_en="How would you describe your body frame?",
        text_hi="आपका शारीरिक ढांचा कैसा है?",
        options={
            "vata": "Thin, light, difficult to gain weight",
            "pitta": "Medium build, moderate weight",
            "kapha": "Heavy, large frame, easy to gain weight",
        },
    ),
    PrakritiQuestion(
        id="skin_texture",
        text_en="How would you describe your skin?",
        text_hi="आपकी त्वचा कैसी है?",
        options={
            "vata": "Dry, rough, thin, cool",
            "pitta": "Soft, warm, oily, prone to rashes",
            "kapha": "Thick, smooth, oily, cool and moist",
        },
    ),
    PrakritiQuestion(
        id="hair_type",
        text_en="What is your natural hair type?",
        text_hi="आपके बाल कैसे हैं?",
        options={
            "vata": "Dry, frizzy, thin, prone to breakage",
            "pitta": "Fine, oily, prone to premature greying",
            "kapha": "Thick, wavy, lustrous, oily",
        },
    ),
    PrakritiQuestion(
        id="eyes",
        text_en="How would you describe your eyes?",
        text_hi="आपकी आँखें कैसी हैं?",
        options={
            "vata": "Small, dry, nervous movement",
            "pitta": "Sharp, penetrating, light-sensitive",
            "kapha": "Large, calm, attractive",
        },
    ),
    PrakritiQuestion(
        id="appetite",
        text_en="How is your appetite generally?",
        text_hi="आपकी भूख आमतौर पर कैसी है?",
        options={
            "vata": "Variable, irregular, sometimes skip meals",
            "pitta": "Strong, cannot skip meals, irritable when hungry",
            "kapha": "Steady, can skip meals, emotional eating",
        },
    ),
    PrakritiQuestion(
        id="digestion",
        text_en="How is your digestion?",
        text_hi="आपकी पाचन शक्ति कैसी है?",
        options={
            "vata": "Irregular, tendency to bloating and gas",
            "pitta": "Sharp and quick, sometimes acidic",
            "kapha": "Slow and steady, heavy after meals",
        },
    ),
    PrakritiQuestion(
        id="elimination",
        text_en="How would you describe your bowel habits?",
        text_hi="आपकी मल-प्रवृत्ति कैसी है?",
        options={
            "vata": "Dry, hard, tendency to constipation",
            "pitta": "Regular, loose sometimes, yellowish",
            "kapha": "Regular, heavy, slow, well-formed",
        },
    ),
    PrakritiQuestion(
        id="sleep",
        text_en="How is your sleep pattern?",
        text_hi="आपकी नींद कैसी है?",
        options={
            "vata": "Light, interrupted, difficulty falling asleep",
            "pitta": "Moderate, intense dreams, wakes easily",
            "kapha": "Heavy, long, deep, difficult to wake",
        },
    ),
    PrakritiQuestion(
        id="energy",
        text_en="How is your energy level through the day?",
        text_hi="दिन भर आपकी ऊर्जा कैसी रहती है?",
        options={
            "vata": "Variable, bursts of energy then fatigue",
            "pitta": "High and consistent, competitive",
            "kapha": "Slow to start, steady endurance",
        },
    ),
    PrakritiQuestion(
        id="mental_activity",
        text_en="How is your mental activity / thinking style?",
        text_hi="आपकी मानसिक गतिविधि कैसी है?",
        options={
            "vata": "Quick, creative, easily distracted",
            "pitta": "Sharp, focused, analytical, critical",
            "kapha": "Steady, calm, good memory, slow to learn but retains well",
        },
    ),
    PrakritiQuestion(
        id="speech",
        text_en="How would you describe your speech?",
        text_hi="आपकी बोलने की शैली कैसी है?",
        options={
            "vata": "Fast, talkative, may jump topics",
            "pitta": "Sharp, precise, persuasive",
            "kapha": "Slow, melodious, thoughtful",
        },
    ),
    PrakritiQuestion(
        id="memory",
        text_en="How is your memory?",
        text_hi="आपकी याददाश्त कैसी है?",
        options={
            "vata": "Quick to learn, quick to forget",
            "pitta": "Good short and long term memory",
            "kapha": "Slow to learn, but never forgets",
        },
    ),
    PrakritiQuestion(
        id="temperature_preference",
        text_en="What temperature do you prefer?",
        text_hi="आपको किस तापमान में आराम मिलता है?",
        options={
            "vata": "Prefer warm, dislike cold and wind",
            "pitta": "Prefer cool, dislike heat",
            "kapha": "Prefer warm and dry, dislike cold and damp",
        },
    ),
    PrakritiQuestion(
        id="emotional_tendency",
        text_en="Under stress, what is your emotional tendency?",
        text_hi="तनाव में आपकी भावनात्मक प्रवृत्ति क्या है?",
        options={
            "vata": "Anxiety, fear, worry",
            "pitta": "Anger, irritability, criticism",
            "kapha": "Withdrawal, sadness, attachment",
        },
    ),
    PrakritiQuestion(
        id="physical_activity",
        text_en="What is your activity preference?",
        text_hi="शारीरिक गतिविधि में आपकी रुचि कैसी है?",
        options={
            "vata": "Love activity but tire quickly",
            "pitta": "Moderate and goal-oriented exercise",
            "kapha": "Prefer rest, motivated with encouragement",
        },
    ),
    PrakritiQuestion(
        id="walk_pace",
        text_en="How would you describe your walking pace?",
        text_hi="आप कितनी तेज चलते हैं?",
        options={
            "vata": "Fast, light steps, may trip",
            "pitta": "Medium, purposeful stride",
            "kapha": "Slow, steady, graceful",
        },
    ),
    PrakritiQuestion(
        id="weather_sensitivity",
        text_en="How sensitive are you to weather changes?",
        text_hi="मौसम परिवर्तन से आप कितने प्रभावित होते हैं?",
        options={
            "vata": "Very sensitive, symptoms worsen in cold/dry",
            "pitta": "Sensitive to heat, summer is difficult",
            "kapha": "Sensitive to cold and humidity",
        },
    ),
    PrakritiQuestion(
        id="voice",
        text_en="How is your natural voice?",
        text_hi="आपकी आवाज़ कैसी है?",
        options={
            "vata": "Thin, high-pitched, may crack",
            "pitta": "Sharp, clear, moderate pitch",
            "kapha": "Deep, resonant, pleasant",
        },
    ),
    PrakritiQuestion(
        id="thirst",
        text_en="How is your thirst?",
        text_hi="आपको प्यास कितनी लगती है?",
        options={
            "vata": "Variable, sometimes forget to drink water",
            "pitta": "High, frequent thirst",
            "kapha": "Low, rarely thirsty",
        },
    ),
    PrakritiQuestion(
        id="reaction_to_change",
        text_en="How do you generally adapt to change?",
        text_hi="बदलाव के प्रति आप कैसे प्रतिक्रिया करते हैं?",
        options={
            "vata": "Excited but anxious, adapts quickly then gets overwhelmed",
            "pitta": "Analytical, plans carefully, dislikes disruption",
            "kapha": "Resistant to change, prefers routine and stability",
        },
    ),
]


def calculate_prakriti(answers: dict[str, str]) -> PrakritiScore:
    """
    Calculate Prakriti from a dict of {question_id: dosha_key}.
    dosha_key must be "vata", "pitta", or "kapha".

    Returns deterministic PrakritiScore.
    """
    counts = {"vata": 0, "pitta": 0, "kapha": 0}

    for question_id, dosha_answer in answers.items():
        dosha_lower = dosha_answer.lower().strip()
        if dosha_lower in counts:
            counts[dosha_lower] += 1

    total = sum(counts.values()) or 1  # avoid division by zero

    vata_pct = round(counts["vata"] / total * 100, 1)
    pitta_pct = round(counts["pitta"] / total * 100, 1)
    kapha_pct = round(counts["kapha"] / total * 100, 1)

    # Determine primary and secondary
    sorted_doshas = sorted(counts.items(), key=lambda x: x[1], reverse=True)
    primary_key, primary_count = sorted_doshas[0]
    secondary_key, secondary_count = sorted_doshas[1]

    primary = primary_key.capitalize()
    secondary = secondary_key.capitalize() if secondary_count > 0 else None

    # Result label
    if secondary and secondary_count >= primary_count * 0.6:
        result = f"{primary}-{secondary}"
    else:
        result = primary

    return PrakritiScore(
        vata=vata_pct,
        pitta=pitta_pct,
        kapha=kapha_pct,
        result=result,
        primary=primary,
        secondary=secondary,
    )


def get_prakriti_questions() -> list[PrakritiQuestion]:
    return PRAKRITI_QUESTIONS
