"""
Arogya-Saathi — Live End-to-End Test Script
Tests the full pipeline: Patient → Encounter → Interview → Ollama NLP → Red Flags
"""
import httpx
import json
import time
import sys

BASE = "http://localhost:8000/api/v1"

def test_full_flow():
    client = httpx.Client(timeout=60.0)  # longer timeout for Ollama

    print("=" * 60)
    print("  AROGYA-SAATHI — LIVE END-TO-END TEST")
    print("=" * 60)

    # 1. Create Patient
    print("\n[1] Creating patient...")
    r = client.post(f"{BASE}/patients", json={
        "name": "Live Test Patient",
        "age": "30",
        "gender": "Male",
        "mobile": "9876500002",
        "preferred_language": "en",
    })
    assert r.status_code == 201, f"Patient create failed: {r.text}"
    patient = r.json()
    print(f"  ✓ Patient created: {patient['id']} ({patient['name']})")

    # 2. Create Encounter
    print("\n[2] Creating encounter...")
    r = client.post(f"{BASE}/encounters", json={
        "patient_id": patient["id"],
    })
    assert r.status_code == 201, f"Encounter create failed: {r.text}"
    encounter = r.json()
    print(f"  ✓ Encounter created: {encounter['id']} (status: {encounter['status']})")

    # 3. Start Interview
    print("\n[3] Starting interview...")
    r = client.post(f"{BASE}/interviews/start", json={
        "encounter_id": encounter["id"],
        "language": "en",
    })
    assert r.status_code == 201, f"Interview start failed: {r.text}"
    interview = r.json()
    print(f"  ✓ Interview started: {interview['interview_id']}")
    print(f"  → First question: {interview['current_question']}")

    # 4. Submit audio (mock ASR → Ollama NLP)
    print("\n[4] Submitting response (ASR mock → Ollama NLP)...")
    print("  Sending scenario: chest pain in English...")
    start_time = time.time()
    r = client.post(
        f"{BASE}/interviews/{interview['interview_id']}/audio",
        data={"language": "en", "scenario_hint": "chest_en"},
    )
    elapsed = time.time() - start_time
    assert r.status_code == 200, f"Audio submit failed: {r.text}"
    result = r.json()
    
    print(f"  ✓ Response received in {elapsed:.1f}s")
    print(f"  Transcript: {result['transcript']}")
    print(f"  ASR is_mock: {result['is_mock']}")
    print(f"\n  Extracted Fields ({len(result['extracted_fields'])} total):")
    for field in result["extracted_fields"]:
        print(f"    - {field['field_type']}: {field['value']} "
              f"(conf: {field['confidence']}, src: {field['source']})")
    
    # Check if Ollama was used (mock has specific confidence values)
    confidences = [f['confidence'] for f in result['extracted_fields']]
    mock_confidences = {0.92, 0.85, 0.80, 0.83, 0.82, 0.78}
    is_ollama = not all(c in mock_confidences for c in confidences)
    
    print(f"\n  NLP Engine: {'🤖 OLLAMA (Real AI)' if is_ollama else '📋 MOCK (Regex fallback)'}")
    
    if result["has_red_flags"]:
        print(f"\n  🚨 Red Flags ({len(result['red_flags'])}):")
        for rf in result["red_flags"]:
            print(f"    - [{rf['severity'].upper()}] {rf['rule_name']}")
            print(f"      Patient msg: {rf['patient_message']}")
            print(f"      Physician: {rf['physician_reason'][:100]}...")
    else:
        print("\n  ✅ No red flags detected")
    
    print(f"\n  Next question: {result['next_question']}")

    # 5. Submit second response (fever scenario)
    print("\n[5] Submitting second response (fever scenario)...")
    start_time = time.time()
    r = client.post(
        f"{BASE}/interviews/{interview['interview_id']}/audio",
        data={"language": "en", "scenario_hint": "fever_en"},
    )
    elapsed = time.time() - start_time
    result2 = r.json()
    print(f"  ✓ Response received in {elapsed:.1f}s")
    print(f"  Transcript: {result2['transcript']}")
    print(f"  Extracted: {json.dumps(result2['extracted_fields'], indent=2)}")

    # 6. Complete Interview
    print("\n[6] Completing interview...")
    r = client.post(f"{BASE}/interviews/{interview['interview_id']}/complete")
    assert r.status_code == 200, f"Interview complete failed: {r.text}"
    print(f"  ✓ Interview completed")

    # 7. Submit encounter to physician queue
    print("\n[7] Submitting encounter for physician review...")
    r = client.put(f"{BASE}/encounters/{encounter['id']}/submit")
    assert r.status_code == 200, f"Encounter submit failed: {r.text}"
    print(f"  ✓ Encounter submitted to physician queue")

    # 8. Login as physician and check queue
    print("\n[8] Logging in as physician...")
    r = client.post(f"{BASE}/auth/login", json={
        "email": "dr.sharma@arogyasaathi.demo",
        "password": "demo@123",
    })
    assert r.status_code == 200, f"Login failed: {r.text}"
    auth = r.json()
    print(f"  ✓ Logged in as {auth['name']} (role: {auth['role']})")
    
    headers = {"Authorization": f"Bearer {auth['access_token']}"}

    # 9. Check physician queue
    print("\n[9] Checking physician queue...")
    r = client.get(f"{BASE}/physician/queue", headers=headers)
    assert r.status_code == 200, f"Queue fetch failed: {r.text}"
    queue = r.json()
    print(f"  ✓ Queue has {queue['total']} patients")
    for item in queue["queue"]:
        flag = "🚨" if item["has_red_flags"] else "✅"
        print(f"    {flag} {item['patient_name']} — {item['chief_complaint']} "
              f"(priority: {item['priority']}, flags: {item['red_flag_count']})")

    # 10. Get encounter summary
    print("\n[10] Getting encounter summary...")
    r = client.get(f"{BASE}/encounters/{encounter['id']}/summary", headers=headers)
    assert r.status_code == 200, f"Summary fetch failed: {r.text}"
    summary = r.json()
    print(f"  ✓ Encounter: {summary['encounter_id']}")
    print(f"    Patient: {summary['patient']['name']} ({summary['patient']['age']}y, {summary['patient']['gender']})")
    print(f"    Status: {summary['status']}, Priority: {summary['priority']}")
    print(f"    Chief Complaint: {summary['chief_complaint']}")
    print(f"    Findings: {json.dumps(summary['findings'], indent=4)}")
    
    if summary['red_flags']:
        print(f"    Red Flags:")
        for rf in summary['red_flags']:
            print(f"      🚨 [{rf['severity']}] {rf['rule_name']}: {rf['reason'][:80]}...")

    # 11. Check FHIR metadata
    print("\n[11] Checking FHIR metadata...")
    r = client.get(f"{BASE}/fhir/metadata")
    assert r.status_code == 200
    fhir_meta = r.json()
    print(f"  ✓ FHIR version: {fhir_meta['fhirVersion']}")

    print("\n" + "=" * 60)
    print("  ALL TESTS PASSED ✓")
    print("=" * 60)
    print(f"\n  NLP Engine used: {'🤖 OLLAMA (gemma3:4b)' if is_ollama else '📋 MOCK (regex)'}")
    print(f"  Backend: http://localhost:8000")
    print(f"  API Docs: http://localhost:8000/api/docs")
    print(f"  Physician: dr.sharma@arogyasaathi.demo / demo@123")
    print()


if __name__ == "__main__":
    try:
        test_full_flow()
    except Exception as e:
        print(f"\n❌ TEST FAILED: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
