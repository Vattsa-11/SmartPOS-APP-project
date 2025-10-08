#!/usr/bin/env python3
"""
Simple test script to test products without authentication
"""
import requests
import json

BASE_URL = "http://localhost:8000"

def test_health():
    """Test the health endpoint"""
    print("❤️ Testing health endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/health")
        print(f"Health Status Code: {response.status_code}")
        if response.status_code == 200:
            print("✅ Health check passed!")
            print(f"Response: {response.json()}")
        else:
            print(f"❌ Health check failed: {response.text}")
    except Exception as e:
        print(f"❌ Health check error: {e}")

def test_root():
    """Test the root endpoint"""
    print("\n🏠 Testing root endpoint...")
    try:
        response = requests.get(f"{BASE_URL}/")
        print(f"Root Status Code: {response.status_code}")
        if response.status_code == 200:
            print("✅ Root endpoint works!")
            print(f"Response: {response.json()}")
        else:
            print(f"❌ Root endpoint failed: {response.text}")
    except Exception as e:
        print(f"❌ Root endpoint error: {e}")

if __name__ == "__main__":
    print("🚀 Starting Basic API Tests\n")
    test_health()
    test_root()
    print("\n✅ Basic tests completed!")