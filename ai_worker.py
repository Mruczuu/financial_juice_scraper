import requests
import openai
import time
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# --- KONFIGURACJA ---
SUPABASE_URL = os.getenv('SUPABASE_URL')
SUPABASE_API_KEY = os.getenv('SUPABASE_SERVICE_ROLE_KEY')
OPENAI_API_KEY = os.getenv('OPENAI_API_KEY')
RAW_TABLE = "raw_news"
NEWS_TABLE = "news"

# Validate required environment variables
if not SUPABASE_URL or not SUPABASE_API_KEY or not OPENAI_API_KEY:
    raise ValueError("Missing required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, and OPENAI_API_KEY")

openai.api_key = OPENAI_API_KEY

def fetch_raw_news():
    url = f"{SUPABASE_URL}/rest/v1/{RAW_TABLE}?select=id,title"
    headers = {
        "apikey": SUPABASE_API_KEY,
        "Authorization": f"Bearer {SUPABASE_API_KEY}"
    }
    resp = requests.get(url, headers=headers)
    data = resp.json()
    # Check if response is an error
    if isinstance(data, dict) and 'message' in data:
        print(f"⚠️ Database error: {data.get('message')}")
        return []
    # Return empty list if not a list
    if not isinstance(data, list):
        return []
    return data

def check_if_exists(news_id):
    url = f"{SUPABASE_URL}/rest/v1/{NEWS_TABLE}?id=eq.{news_id}"
    headers = {
        "apikey": SUPABASE_API_KEY,
        "Authorization": f"Bearer {SUPABASE_API_KEY}"
    }
    resp = requests.get(url, headers=headers)
    return len(resp.json()) > 0

def push_to_news(news):
    url = f"{SUPABASE_URL}/rest/v1/{NEWS_TABLE}"
    headers = {
        "apikey": SUPABASE_API_KEY,
        "Authorization": f"Bearer {SUPABASE_API_KEY}",
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
    }
    resp = requests.post(url, headers=headers, json=news)
    print(f"Wysłano: {news['title']} | Status: {resp.status_code} | {resp.text}")

def ai_process(title):
    import openai
    import json
    prompt = f"""
Oryginalny news (ENG):
{title}

Zadanie:
1. Przetłumacz powyższą wiadomość na język polski.
2. W 2-3 zdaniach wyjaśnij, czym jest ten raport lub wydarzenie, jak można je interpretować oraz jakie ogólne znaczenie może mieć dla głównych walut (np. USD, EUR, JPY). Nie przewiduj konkretnych ruchów rynku, nie spekuluj.
3. Oceń wagę tego wydarzenia dla rynków finansowych jako jedno z: "mało ważne", "średnie", "ważne". Odpowiedz tylko jednym z tych trzech słów.

Zwróć wynik w formacie JSON:
{{
  "title": "[tłumaczenie]",
  "ai_explanation": "[wyjaśnienie]",
  "impact": "[ważne/średnie/mało ważne]"
}}
"""
    client = openai.OpenAI(api_key=OPENAI_API_KEY)
    response = client.chat.completions.create(
        model="gpt-3.5-turbo",
        messages=[{"role": "user", "content": prompt}],
        temperature=0.2,
        max_tokens=512
    )
    try:
        text = response.choices[0].message.content
        data = json.loads(text)
        return data
    except Exception as e:
        print("Błąd parsowania AI:", e)
        print("Odpowiedź AI:", response.choices[0].message.content)
        return None

def main():
    while True:
        raw_news = fetch_raw_news()
        if not raw_news:
            print("📭 Brak surowych wiadomości do przetworzenia (lub błąd bazy danych)")
            time.sleep(30)
            continue
        
        print(f"📰 Znaleziono {len(raw_news)} surowych wiadomości")
        for item in raw_news:
            news_id = item["id"]
            if check_if_exists(news_id):
                continue  # już przetworzone
            print(f"Przetwarzam: {item['title']}")
            ai_result = ai_process(item["title"])
            if ai_result:
                news = {
                    "id": news_id,
                    "title": ai_result["title"],
                    "ai_explanation": ai_result["ai_explanation"],
                    "impact": ai_result["impact"],
                    "timestamp": time.strftime("%Y-%m-%dT%H:%M:%S")
                }
                push_to_news(news)
            time.sleep(2)  # nie spamuj API
        print("Czekam na nowe newsy...")
        time.sleep(30)

if __name__ == "__main__":
    main()
