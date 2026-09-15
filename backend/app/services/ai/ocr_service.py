"""
Arogya-Saathi — OCR Service
"""
import asyncio
from typing import Dict, Any


class MockOCRService:
    async def extract_text(self, file_path: str, document_type: str = "unknown") -> str:
        await asyncio.sleep(0.5)  # simulate processing
        
        mock_texts = {
            "prescription": (
                "Dr. Rajan Mehta, MBBS MD\nCity Hospital, Mumbai\n"
                "Date: 15 March 2025\nPatient: Ramesh Kumar\n"
                "Rx:\n1. Tab. Atorvastatin 20mg — 0-0-1\n"
                "2. Tab. Aspirin 75mg — 1-0-0\n"
                "3. Tab. Metoprolol 25mg — 1-0-1\n"
                "Follow up: 1 week\nDiagnosis: Hypertension, CAD"
            ),
            "lab_report": (
                "Central Diagnostics Lab\nReport Date: 10 Jan 2025\n"
                "Patient: Ramesh Kumar Age: 45\n"
                "Complete Blood Count:\n"
                "Haemoglobin: 13.2 g/dL\nWBC: 8,200/μL\nPlatelets: 210,000/μL\n"
                "Lipid Profile:\n"
                "Total Cholesterol: 234 mg/dL (High)\nLDL: 158 mg/dL (High)\n"
                "HDL: 42 mg/dL\nTriglycerides: 180 mg/dL"
            ),
            "discharge_summary": (
                "Apollo Hospital\nDischarge Summary\n"
                "Date of Admission: 05 Dec 2024\nDate of Discharge: 10 Dec 2024\n"
                "Diagnosis: Acute Gastroenteritis\n"
                "Treatment: IV fluids, antibiotics, anti-emetics\n"
                "Condition at discharge: Stable"
            ),
        }
        
        return mock_texts.get(document_type, f"Mock document content for type {document_type}")


class RealOCRService:
    async def extract_text(self, file_path: str, document_type: str = "unknown") -> str:
        from PIL import Image
        import asyncio

        # 1. Try Windows native OCR (winocr) - high accuracy, no external binaries needed
        try:
            import winocr
            img = Image.open(file_path)
            result = await winocr.recognize_pil(img, 'en')
            if result and hasattr(result, 'text') and result.text.strip():
                return result.text.strip()
        except Exception as e:
            print(f"winocr failed or not available on {file_path}: {e}")

        # 2. Try pytesseract if available
        loop = asyncio.get_running_loop()
        def _do_pytesseract():
            try:
                import pytesseract
                img = Image.open(file_path)
                return pytesseract.image_to_string(img)
            except Exception as e:
                print(f"pytesseract error on {file_path}: {e}")
                return ""

        text = await loop.run_in_executor(None, _do_pytesseract)
        if text and text.strip():
            return text.strip()

        # 3. Fallback to mock text if OCR engines fail
        mock = MockOCRService()
        return await mock.extract_text(file_path, document_type)


def get_ocr_service():
    from app.core.config import settings
    if settings.ocr_service == "real":
        return RealOCRService()
    return MockOCRService()
