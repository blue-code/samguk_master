import json
import concurrent.futures
from deep_translator import GoogleTranslator

def translate_item(item):
    tl_en = GoogleTranslator(source='ko', target='en')
    tl_zh = GoogleTranslator(source='ko', target='zh-CN')
    tl_ja = GoogleTranslator(source='ko', target='ja')
    
    def safe_translate(tl, text):
        if not text: return ""
        try:
            return tl.translate(text)
        except:
            return text

    new_item = {
        "id": item["id"],
        "category": {
            "ko": item["category"] if isinstance(item["category"], str) else item["category"].get("ko", ""),
            "en": safe_translate(tl_en, item["category"] if isinstance(item["category"], str) else item["category"].get("ko", "")),
            "zh": safe_translate(tl_zh, item["category"] if isinstance(item["category"], str) else item["category"].get("ko", "")),
            "ja": safe_translate(tl_ja, item["category"] if isinstance(item["category"], str) else item["category"].get("ko", "")),
        },
        "difficulty": item["difficulty"],
        "question": {
            "ko": item["question"] if isinstance(item["question"], str) else item["question"].get("ko", ""),
            "en": safe_translate(tl_en, item["question"] if isinstance(item["question"], str) else item["question"].get("ko", "")),
            "zh": safe_translate(tl_zh, item["question"] if isinstance(item["question"], str) else item["question"].get("ko", "")),
            "ja": safe_translate(tl_ja, item["question"] if isinstance(item["question"], str) else item["question"].get("ko", "")),
        },
        "choices": {
            "ko": item["choices"] if isinstance(item["choices"], list) else item["choices"].get("ko", []),
        },
        "answerIndex": item["answerIndex"],
        "explanation": {
            "ko": item["explanation"] if isinstance(item["explanation"], str) else item["explanation"].get("ko", ""),
            "en": safe_translate(tl_en, item["explanation"] if isinstance(item["explanation"], str) else item["explanation"].get("ko", "")),
            "zh": safe_translate(tl_zh, item["explanation"] if isinstance(item["explanation"], str) else item["explanation"].get("ko", "")),
            "ja": safe_translate(tl_ja, item["explanation"] if isinstance(item["explanation"], str) else item["explanation"].get("ko", "")),
        },
        "tags": item["tags"]
    }
    
    # Translate choices
    ko_choices = new_item["choices"]["ko"]
    new_item["choices"]["en"] = [safe_translate(tl_en, c) for c in ko_choices]
    new_item["choices"]["zh"] = [safe_translate(tl_zh, c) for c in ko_choices]
    new_item["choices"]["ja"] = [safe_translate(tl_ja, c) for c in ko_choices]
    
    print(f"Processed ID: {item['id']}")
    return new_item

def main():
    print("Loading data...")
    with open("assets/data/questions.json", "r", encoding="utf-8") as f:
        data = json.load(f)
        
    print(f"Translating {len(data)} items...")
    results = []
    
    # Use max_workers=5 to avoid being blocked
    with concurrent.futures.ThreadPoolExecutor(max_workers=5) as executor:
        results = list(executor.map(translate_item, data))
        
    print("Saving data...")
    with open("assets/data/questions.json", "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)
        
    print("Done!")

if __name__ == "__main__":
    main()
