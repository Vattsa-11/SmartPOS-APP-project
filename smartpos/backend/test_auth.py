#!/usr/bin/env python3
"""
Simple test script to verify authentication and product creation
"""
import requests
import json

# Test configuration
BASE_URL = "http://localhost:8000"
TEST_EMAIL = "test@test.com"
TEST_PASSWORD = "1234"

def test_login():
    """Test the login endpoint"""
    print("🔐 Testing login...")
    
    login_data = {
        "email": TEST_EMAIL,
        "password": TEST_PASSWORD
    }
    
    try:
        response = requests.post(
            f"{BASE_URL}/auth/json-login",
            headers={"Content-Type": "application/json"},
            json=login_data
        )
        
        print(f"Login Status Code: {response.status_code}")
        if response.status_code == 200:
            data = response.json()
            print("✅ Login successful!")
            print(f"Access Token: {data.get('access_token', 'N/A')[:50]}...")
            print(f"User: {data.get('user', {})}")
            return data.get('access_token')
        else:
            print(f"❌ Login failed: {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Login error: {e}")
        return None

def test_product_creation(token):
    """Test product creation with authentication"""
    if not token:
        print("❌ No token available for product creation test")
        return
    
    print("\n📦 Testing product creation...")
    
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
            f"{BASE_URL}/products",
            headers={
                "Content-Type": "application/json",
                "Authorization": f"Bearer {token}"
            },
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

def test_product_list(token):
    """Test getting product list"""
    if not token:
        print("❌ No token available for product list test")
        return
    
    print("\n📋 Testing product list...")
    
    try:
        response = requests.get(
            f"{BASE_URL}/products",
            headers={"Authorization": f"Bearer {token}"}
        )
        
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
    print("🚀 Starting SmartPOS API Tests\n")
    
    # Test login
    token = test_login()
    
    # Test product creation
    product_id = test_product_creation(token)
    
    # Test product list
    test_product_list(token)
    
    print("\n✅ Tests completed!")