import urllib.request
import json
import time

def fetch_products():
    base_url = "https://restomart.pk/wp-json/wc/store/products"
    all_products = []
    page = 1
    
    print("Fetching products from Restomart.pk...")
    while True:
        url = f"{base_url}?page={page}&per_page=100"
        try:
            req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
            with urllib.request.urlopen(req) as response:
                data = json.loads(response.read().decode('utf-8'))
                
                if not data:
                    break
                    
                all_products.extend(data)
                print(f"Fetched page {page} ({len(data)} products)")
                page += 1
                time.sleep(1) # Be polite to the server
                
        except Exception as e:
            print(f"Finished fetching or encountered an error: {e}")
            break
            
    print(f"Total products fetched: {len(all_products)}")
    
    # Save to file
    with open('fetched_products.json', 'w', encoding='utf-8') as f:
        json.dump(all_products, f, indent=4, ensure_ascii=False)
        
    print("Successfully saved to fetched_products.json")

if __name__ == "__main__":
    fetch_products()
