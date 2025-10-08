from datetime import timedelta, datetime
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from decimal import Decimal

from database import create_tables, get_db, get_database_info
import models, schemas, auth

# Create database tables
create_tables()

app = FastAPI(
    title="SmartPOS Simple API",
    description="Simplified API for frontend development",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ===== SIMPLE AUTHENTICATION =====
@app.post("/api/login")
async def simple_login(credentials: dict, db: Session = Depends(get_db)):
    """Simple login endpoint"""
    email = credentials.get("email")
    password = credentials.get("password")
    
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password required")
    
    # Find or create user
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        # Auto-create user for development
        user = models.User(
            supabase_user_id=f"user-{len(db.query(models.User).all()) + 1}",
            username=email,
            email=email,
            owner_name=email.split('@')[0].title(),
            phone="1234567890",
            shop_name=f"{email.split('@')[0].title()}'s Shop",
            password_hash=auth.get_password_hash(password),
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # Verify password
    if not auth.verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create token
    access_token = auth.create_access_token(data={"sub": str(user.id)})
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "owner_name": user.owner_name,
            "phone": user.phone,
            "shop_name": user.shop_name
        }
    }

@app.post("/api/register")
async def simple_register(user_data: dict, db: Session = Depends(get_db)):
    """Simple registration endpoint"""
    email = user_data.get("email")
    password = user_data.get("password")
    name = user_data.get("name", email.split('@')[0].title() if email else "User")
    
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password required")
    
    # Check if user exists
    existing = db.query(models.User).filter(models.User.email == email).first()
    if existing:
        raise HTTPException(status_code=400, detail="User already exists")
    
    # Create user
    user = models.User(
        supabase_user_id=f"user-{len(db.query(models.User).all()) + 1}",
        username=email,
        email=email,
        owner_name=name,
        phone="1234567890",
        shop_name=f"{name}'s Shop",
        password_hash=auth.get_password_hash(password),
        is_active=True
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    
    return {
        "message": "User created successfully",
        "user": {
            "id": user.id,
            "email": user.email,
            "owner_name": user.owner_name,
            "shop_name": user.shop_name
        }
    }

# ===== PRODUCT MANAGEMENT =====
@app.post("/api/products")
async def create_product_simple(product_data: dict, db: Session = Depends(get_db)):
    """Create product with simple data structure"""
    # Use default user ID 1 for now (in production, get from token)
    user_id = 1
    
    # Ensure user exists
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        # Create default user
        user = models.User(
            supabase_user_id="default-user",
            username="default@shop.com",
            email="default@shop.com",
            owner_name="Default User",
            phone="1234567890",
            shop_name="Default Shop",
            password_hash=auth.get_password_hash("password"),
            is_active=True
        )
        db.add(user)
        db.commit()
        db.refresh(user)
    
    # Create product
    product = models.Product(
        user_id=user_id,
        name=product_data.get("name", "Unnamed Product"),
        barcode=product_data.get("barcode") or f"AUTO-{int(datetime.now().timestamp())}",
        price=Decimal(str(product_data.get("price", 0))),
        selling_price=Decimal(str(product_data.get("selling_price", product_data.get("price", 0)))),
        cost_price=Decimal(str(product_data.get("cost_price", 0))),
        discount_percentage=Decimal(str(product_data.get("discount_percentage", 0))),
        tax_percentage=Decimal(str(product_data.get("tax_percentage", 0))),
        unit=product_data.get("unit", "pcs"),
        is_active=True,
        is_featured=product_data.get("is_featured", False)
    )
    
    db.add(product)
    db.commit()
    db.refresh(product)
    
    # Create inventory
    inventory = models.Inventory(
        product_id=product.id,
        current_stock=int(product_data.get("initial_stock", 0)),
        minimum_stock=int(product_data.get("minimum_stock", 5)),
        maximum_stock=int(product_data.get("maximum_stock", 1000))
    )
    db.add(inventory)
    db.commit()
    
    return {
        "id": product.id,
        "name": product.name,
        "barcode": product.barcode,
        "price": float(product.price),
        "selling_price": float(product.selling_price),
        "cost_price": float(product.cost_price),
        "discount_percentage": float(product.discount_percentage),
        "tax_percentage": float(product.tax_percentage),
        "unit": product.unit,
        "current_stock": inventory.current_stock,
        "minimum_stock": inventory.minimum_stock,
        "is_featured": product.is_featured
    }

@app.get("/api/products")
async def get_products_simple(db: Session = Depends(get_db)):
    """Get all products for default user"""
    user_id = 1
    
    products = db.query(models.Product).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True
    ).all()
    
    result = []
    for product in products:
        inventory = db.query(models.Inventory).filter(
            models.Inventory.product_id == product.id
        ).first()
        
        result.append({
            "id": product.id,
            "name": product.name,
            "barcode": product.barcode,
            "price": float(product.price),
            "selling_price": float(product.selling_price),
            "cost_price": float(product.cost_price),
            "discount_percentage": float(product.discount_percentage),
            "tax_percentage": float(product.tax_percentage),
            "unit": product.unit,
            "current_stock": inventory.current_stock if inventory else 0,
            "minimum_stock": inventory.minimum_stock if inventory else 0,
            "is_featured": product.is_featured,
            "created_at": product.created_at.isoformat(),
            "updated_at": product.updated_at.isoformat()
        })
    
    return result

@app.put("/api/products/{product_id}")
async def update_product_simple(product_id: int, product_data: dict, db: Session = Depends(get_db)):
    """Update product"""
    user_id = 1
    
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == user_id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Update product fields
    if "name" in product_data:
        product.name = product_data["name"]
    if "barcode" in product_data:
        product.barcode = product_data["barcode"]
    if "price" in product_data:
        product.price = Decimal(str(product_data["price"]))
    if "selling_price" in product_data:
        product.selling_price = Decimal(str(product_data["selling_price"]))
    if "cost_price" in product_data:
        product.cost_price = Decimal(str(product_data["cost_price"]))
    if "discount_percentage" in product_data:
        product.discount_percentage = Decimal(str(product_data["discount_percentage"]))
    if "tax_percentage" in product_data:
        product.tax_percentage = Decimal(str(product_data["tax_percentage"]))
    if "unit" in product_data:
        product.unit = product_data["unit"]
    if "is_featured" in product_data:
        product.is_featured = product_data["is_featured"]
    
    db.commit()
    db.refresh(product)
    
    # Update inventory if provided
    inventory = db.query(models.Inventory).filter(
        models.Inventory.product_id == product.id
    ).first()
    
    if inventory and ("current_stock" in product_data or "minimum_stock" in product_data):
        if "current_stock" in product_data:
            inventory.current_stock = int(product_data["current_stock"])
        if "minimum_stock" in product_data:
            inventory.minimum_stock = int(product_data["minimum_stock"])
        db.commit()
    
    return {
        "id": product.id,
        "name": product.name,
        "barcode": product.barcode,
        "price": float(product.price),
        "selling_price": float(product.selling_price),
        "cost_price": float(product.cost_price),
        "discount_percentage": float(product.discount_percentage),
        "tax_percentage": float(product.tax_percentage),
        "unit": product.unit,
        "current_stock": inventory.current_stock if inventory else 0,
        "minimum_stock": inventory.minimum_stock if inventory else 0,
        "is_featured": product.is_featured
    }

@app.delete("/api/products/{product_id}")
async def delete_product_simple(product_id: int, db: Session = Depends(get_db)):
    """Delete product (soft delete)"""
    user_id = 1
    
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == user_id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    product.is_active = False
    db.commit()
    
    return {"message": "Product deleted successfully"}

@app.get("/api/inventory")
async def get_inventory_simple(db: Session = Depends(get_db)):
    """Get inventory with product info"""
    user_id = 1
    
    inventory_items = db.query(models.Inventory).join(models.Product).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True
    ).all()
    
    result = []
    for item in inventory_items:
        result.append({
            "id": item.id,
            "product_id": item.product_id,
            "product_name": item.product.name,
            "current_stock": item.current_stock,
            "minimum_stock": item.minimum_stock,
            "maximum_stock": item.maximum_stock,
            "is_low_stock": item.current_stock <= item.minimum_stock
        })
    
    return result

@app.get("/")
async def root():
    """Root endpoint"""
    return {
        "message": "SmartPOS Simple API is running",
        "docs": "/docs",
        "database": get_database_info()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001, reload=True)