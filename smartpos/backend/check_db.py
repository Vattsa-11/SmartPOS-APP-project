import sqlite3
import os

# Database path
db_path = 'smartpos.db'

if os.path.exists(db_path):
    print(f"Database exists at: {db_path}")
    
    # Connect to database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Check users table structure
    cursor.execute("PRAGMA table_info(users);")
    user_columns = cursor.fetchall()
    print("Users table columns:", user_columns)
    
    # Check products table structure
    cursor.execute("PRAGMA table_info(products);")
    product_columns = cursor.fetchall()
    print("Products table columns:", product_columns)
    
    # Check inventory table structure
    cursor.execute("PRAGMA table_info(inventory);")
    inventory_columns = cursor.fetchall()
    print("Inventory table columns:", inventory_columns)
    
    # Check actual data counts
    cursor.execute("SELECT COUNT(*) FROM users;")
    user_count = cursor.fetchone()[0]
    print(f"Users count: {user_count}")
    
    cursor.execute("SELECT COUNT(*) FROM products;")
    product_count = cursor.fetchone()[0]
    print(f"Products count: {product_count}")
    
    cursor.execute("SELECT COUNT(*) FROM inventory;")
    inventory_count = cursor.fetchone()[0]
    print(f"Inventory count: {inventory_count}")
    
    # Show sample data if exists
    if user_count > 0:
        cursor.execute("SELECT * FROM users LIMIT 3;")
        users = cursor.fetchall()
        print("Sample users:", users)
    
    if product_count > 0:
        cursor.execute("SELECT * FROM products LIMIT 3;")
        products = cursor.fetchall()
        print("Sample products:", products)
    
    if inventory_count > 0:
        cursor.execute("SELECT * FROM inventory LIMIT 3;")
        inventory = cursor.fetchall()
        print("Sample inventory:", inventory)
    
    conn.close()
else:
    print(f"Database does not exist at: {db_path}")