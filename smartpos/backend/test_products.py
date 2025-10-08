#!/usr/bin/env python3
"""
Test product creation without authentication
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_product_creation_no_auth():
    """Test product creation without authentication"""
    print("📦 Testing product creation (no auth)...")
    
    product_data = {
        "name": "Test Product",
        "description": "A test product for verification",
        "price": 10.99,
        "selling_price": 12.99,
        "cost_price": 8.50,
        "sku": "TEST001",
        "unit": "pcs"
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/test/products",
            headers={"Content-Type": "application/json"},
            json=product_data
        )
        
        print(f"Product Creation Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Product created successfully!")
            print(f"Product ID: {data.get('id')}")
            print(f"Product Name: {data.get('name')}")
            return data.get('id')
        else:
            print(f"❌ Product creation failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Product creation error: {e}")
        return None

def test_product_list_no_auth():
    """Test getting product list without authentication"""
    print("\n📋 Testing product list (no auth)...")
    
    try:
        response = requests.get(f"{BASE_URL}/test/products")
        
        print(f"Product List Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print(f"✅ Found {len(data)} products")
            for i, product in enumerate(data):
                print(f"  {i+1}. {product.get('name')} (ID: {product.get('id')})")
        else:
            print(f"❌ Product list failed: {response.text}")
            
    except Exception as e:
        print(f"❌ Product list error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Product Tests (No Auth)\n")
    
    # Test product creation
    product_id = test_product_creation_no_auth()
    
    # Test product list
    test_product_list_no_auth()
    
    print("\n✅ Tests completed!")