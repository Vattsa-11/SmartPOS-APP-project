from datetime import timedelta, datetime
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordRequestForm
from sqlalchemy.orm import Session
from sqlalchemy import func, desc
from decimal import Decimal
import uuid

from database import create_tables, get_db, get_database_info
import models, schemas, auth

# Create database tables
create_tables()

app = FastAPI(
    title="SmartPOS API - Single Shop",
    description="Simple Point of Sale API for single shop management",
    version="1.0.0"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify exact origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.get("/")
async def root():
    db_info = get_database_info()
    return {
        "message": "Welcome to SmartPOS API - Single Shop Edition",
        "documentation": "/docs",
        "database": db_info
    }

# ===== AUTHENTICATION ENDPOINTS =====

@app.post("/auth/login")
async def login(form_data: OAuth2PasswordRequestForm = Depends(), db: Session = Depends(get_db)):
    """Login endpoint for token-based authentication"""
    # For development, create a test user if it doesn't exist
    user = db.query(models.User).filter(models.User.username == form_data.username).first()
    if not user:
        # Create a test user for development
        if form_data.username == "test@test.com" and form_data.password == "1234":
            user = models.User(
                username="test@test.com",
                email="test@test.com",
                owner_name="Test User",
                phone="1234567890",
                shop_name="Test Shop",
                password_hash=auth.get_password_hash("1234"),
                is_active=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Verify password
    if not auth.verify_password(form_data.password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create access token
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "owner_name": user.owner_name,
            "phone": user.phone
        }
    }

@app.post("/auth/json-login")
async def json_login(credentials: dict, db: Session = Depends(get_db)):
    """JSON login endpoint for frontend compatibility"""
    email = credentials.get("email")
    password = credentials.get("password")
    
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email and password required")
    
    # For development, create a test user if it doesn't exist
    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        # Create a test user for development
        if email == "test@test.com" and password == "1234":
            user = models.User(
                username=email,
                email=email,
                owner_name="Test User",
                phone="1234567890",
                shop_name="Test Shop",
                password_hash=auth.get_password_hash(password),
                is_active=True
            )
            db.add(user)
            db.commit()
            db.refresh(user)
        else:
            raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Verify password
    if not auth.verify_password(password, user.password_hash):
        raise HTTPException(status_code=401, detail="Invalid credentials")
    
    # Create access token
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    
    return {
        "access_token": access_token,
        "token_type": "bearer",
        "user": {
            "id": user.id,
            "email": user.email,
            "owner_name": user.owner_name,
            "phone": user.phone
        }
    }

# ===== USER MANAGEMENT =====
async def get_current_user(supabase_user_id: str, db: Session = Depends(get_db)) -> models.User:
    """Get current user from Supabase user ID (this would be called by middleware in production)"""
    user = db.query(models.User).filter(models.User.supabase_user_id == supabase_user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    return user

@app.post("/users", response_model=schemas.User)
async def create_user(user: schemas.UserCreate, db: Session = Depends(get_db)):
    """Create a new user/shop owner"""
    # Check if user already exists
    existing_user = db.query(models.User).filter(
        models.User.supabase_user_id == user.supabase_user_id
    ).first()
    if existing_user:
        raise HTTPException(status_code=400, detail="User already exists")
    
    # Check if email is already taken
    email_exists = db.query(models.User).filter(models.User.email == user.email).first()
    if email_exists:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    db_user = models.User(**user.model_dump())
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.get("/users/me", response_model=schemas.User)
async def get_user_profile(supabase_user_id: str, db: Session = Depends(get_db)):
    """Get current user profile"""
    return await get_current_user(supabase_user_id, db)

@app.put("/users/me", response_model=schemas.User)
async def update_user_profile(
    user_update: schemas.UserUpdate,
    supabase_user_id: str,
    db: Session = Depends(get_db)
):
    """Update current user profile"""
    user = await get_current_user(supabase_user_id, db)
    
    update_data = user_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(user, field, value)
    
    db.commit()
    db.refresh(user)
    return user

# ===== CATEGORIES =====
@app.post("/categories", response_model=schemas.Category)
async def create_category(
    category: schemas.CategoryCreate,
    db: Session = Depends(get_db)
):
    """Create a new product category"""
    db_category = models.Category(**category.model_dump())
    db.add(db_category)
    db.commit()
    db.refresh(db_category)
    return db_category

@app.get("/categories", response_model=List[schemas.Category])
async def list_categories(user_id: int, db: Session = Depends(get_db)):
    """List all categories for a user"""
    categories = db.query(models.Category).filter(
        models.Category.user_id == user_id,
        models.Category.is_active == True
    ).all()
    return categories

@app.put("/categories/{category_id}", response_model=schemas.Category)
async def update_category(
    category_id: int,
    category_update: schemas.CategoryUpdate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Update a category"""
    category = db.query(models.Category).filter(
        models.Category.id == category_id,
        models.Category.user_id == user_id
    ).first()
    
    if not category:
        raise HTTPException(status_code=404, detail="Category not found")
    
    update_data = category_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(category, field, value)
    
    db.commit()
    db.refresh(category)
    return category

# ===== PRODUCTS =====
@app.post("/products", response_model=schemas.Product)
async def create_product(product: schemas.ProductCreate, db: Session = Depends(get_db)):
    """Create a new product with initial inventory"""
    # Create product
    product_data = product.model_dump(exclude={'initial_stock', 'minimum_stock', 'maximum_stock'})
    db_product = models.Product(**product_data)
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    
    # Create initial inventory
    db_inventory = models.Inventory(
        product_id=db_product.id,
        current_stock=product.initial_stock,
        minimum_stock=product.minimum_stock,
        maximum_stock=product.maximum_stock
    )
    db.add(db_inventory)
    db.commit()
    
    return db_product

@app.get("/products", response_model=List[schemas.Product])
async def list_products(
    user_id: int,
    category_id: Optional[int] = None,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List all products for a user"""
    query = db.query(models.Product).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True
    )
    
    if category_id:
        query = query.filter(models.Product.category_id == category_id)
    
    if search:
        query = query.filter(
            models.Product.name.ilike(f"%{search}%") |
            models.Product.barcode.ilike(f"%{search}%")
        )
    
    products = query.all()
    
    # Add inventory info to each product
    for product in products:
        if product.inventory:
            product.current_stock = product.inventory.current_stock
            product.minimum_stock = product.inventory.minimum_stock
    
    return products

@app.get("/products/{product_id}", response_model=schemas.Product)
async def get_product(product_id: int, user_id: int, db: Session = Depends(get_db)):
    """Get a single product"""
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == user_id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    # Add inventory info
    if product.inventory:
        product.current_stock = product.inventory.current_stock
        product.minimum_stock = product.inventory.minimum_stock
    
    return product

@app.put("/products/{product_id}", response_model=schemas.Product)
async def update_product(
    product_id: int,
    product_update: schemas.ProductUpdate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Update a product"""
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == user_id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    update_data = product_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(product, field, value)
    
    db.commit()
    db.refresh(product)
    return product

@app.delete("/products/{product_id}")
async def delete_product(product_id: int, user_id: int, db: Session = Depends(get_db)):
    """Delete a product (soft delete)"""
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == user_id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    product.is_active = False
    db.commit()
    return {"message": "Product deleted successfully"}

# ===== INVENTORY =====
@app.get("/inventory", response_model=List[schemas.Inventory])
async def list_inventory(user_id: int, db: Session = Depends(get_db)):
    """List all inventory items for a user"""
    inventory = db.query(models.Inventory).join(models.Product).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True
    ).all()
    return inventory

@app.get("/inventory/low-stock", response_model=List[schemas.Product])
async def get_low_stock_products(user_id: int, db: Session = Depends(get_db)):
    """Get products with low stock"""
    products = db.query(models.Product).join(models.Inventory).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True,
        models.Inventory.current_stock <= models.Inventory.minimum_stock
    ).all()
    
    # Add inventory info
    for product in products:
        if product.inventory:
            product.current_stock = product.inventory.current_stock
            product.minimum_stock = product.inventory.minimum_stock
    
    return products

@app.put("/inventory/{product_id}", response_model=schemas.Inventory)
async def update_inventory(
    product_id: int,
    inventory_update: schemas.InventoryUpdate,
    user_id: int,
    db: Session = Depends(get_db)
):
    """Update inventory for a product"""
    # Verify product belongs to user
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == user_id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    inventory = db.query(models.Inventory).filter(
        models.Inventory.product_id == product_id
    ).first()
    
    if not inventory:
        raise HTTPException(status_code=404, detail="Inventory not found")
    
    update_data = inventory_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(inventory, field, value)
    
    db.commit()
    db.refresh(inventory)
    return inventory

# ===== CUSTOMERS =====
@app.post("/customers", response_model=schemas.Customer)
async def create_customer(customer: schemas.CustomerCreate, db: Session = Depends(get_db)):
    """Create a new customer"""
    db_customer = models.Customer(**customer.model_dump())
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer

@app.get("/customers", response_model=List[schemas.Customer])
async def list_customers(
    user_id: int,
    search: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List all customers for a user"""
    query = db.query(models.Customer).filter(
        models.Customer.user_id == user_id,
        models.Customer.is_active == True
    )
    
    if search:
        query = query.filter(
            models.Customer.name.ilike(f"%{search}%") |
            models.Customer.phone.ilike(f"%{search}%")
        )
    
    customers = query.all()
    return customers

@app.get("/customers/{customer_id}", response_model=schemas.Customer)
async def get_customer(customer_id: int, user_id: int, db: Session = Depends(get_db)):
    """Get a single customer"""
    customer = db.query(models.Customer).filter(
        models.Customer.id == customer_id,
        models.Customer.user_id == user_id
    ).first()
    
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    return customer

# ===== SALES =====
def generate_invoice_number() -> str:
    """Generate a unique invoice number"""
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    return f"INV-{timestamp}-{str(uuid.uuid4())[:6].upper()}"

@app.post("/sales", response_model=schemas.Sale)
async def create_sale(sale: schemas.SaleCreate, db: Session = Depends(get_db)):
    """Create a new sale"""
    # Calculate totals
    subtotal = Decimal("0.00")
    total_discount = Decimal("0.00")
    total_tax = Decimal("0.00")
    
    # Validate products and calculate totals
    sale_items_data = []
    for item in sale.items:
        product = db.query(models.Product).filter(
            models.Product.id == item.product_id,
            models.Product.user_id == sale.user_id
        ).first()
        
        if not product:
            raise HTTPException(status_code=404, detail=f"Product {item.product_id} not found")
        
        # Check inventory
        if product.inventory and product.inventory.current_stock < item.quantity:
            raise HTTPException(
                status_code=400, 
                detail=f"Insufficient stock for {product.name}. Available: {product.inventory.current_stock}"
            )
        
        # Calculate item totals
        item_subtotal = item.unit_price * item.quantity
        item_discount = item.discount_amount or (item_subtotal * item.discount_percentage / 100)
        item_tax = (item_subtotal - item_discount) * item.tax_percentage / 100
        item_total = item_subtotal - item_discount + item_tax
        
        subtotal += item_subtotal
        total_discount += item_discount
        total_tax += item_tax
        
        sale_items_data.append({
            **item.model_dump(),
            "discount_amount": item_discount,
            "tax_amount": item_tax,
            "total_price": item_total
        })
    
    total_amount = subtotal - total_discount + total_tax
    change_amount = sale.paid_amount - total_amount if sale.paid_amount >= total_amount else Decimal("0.00")
    payment_status = "completed" if sale.paid_amount >= total_amount else "partial"
    
    # Create sale
    db_sale = models.Sale(
        user_id=sale.user_id,
        customer_id=sale.customer_id,
        invoice_number=generate_invoice_number(),
        subtotal=subtotal,
        discount_amount=total_discount,
        tax_amount=total_tax,
        total_amount=total_amount,
        payment_method=sale.payment_method,
        payment_status=payment_status,
        paid_amount=sale.paid_amount,
        change_amount=change_amount,
        notes=sale.notes
    )
    
    db.add(db_sale)
    db.commit()
    db.refresh(db_sale)
    
    # Create sale items and update inventory
    for item_data in sale_items_data:
        db_sale_item = models.SaleItem(
            sale_id=db_sale.id,
            **item_data
        )
        db.add(db_sale_item)
        
        # Update inventory
        product = db.query(models.Product).filter(
            models.Product.id == item_data["product_id"]
        ).first()
        
        if product.inventory:
            product.inventory.current_stock -= item_data["quantity"]
            
            # Create inventory adjustment record
            adjustment = models.InventoryAdjustment(
                user_id=sale.user_id,
                inventory_id=product.inventory.id,
                adjustment_type="sale",
                quantity_change=-item_data["quantity"],
                reason=f"Sale: {db_sale.invoice_number}",
                reference_id=str(db_sale.id)
            )
            db.add(adjustment)
    
    db.commit()
    db.refresh(db_sale)
    return db_sale

@app.get("/sales", response_model=List[schemas.Sale])
async def list_sales(
    user_id: int,
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    payment_status: Optional[str] = None,
    db: Session = Depends(get_db)
):
    """List all sales for a user"""
    query = db.query(models.Sale).filter(models.Sale.user_id == user_id)
    
    if start_date:
        query = query.filter(models.Sale.sale_date >= start_date)
    
    if end_date:
        query = query.filter(models.Sale.sale_date <= end_date)
    
    if payment_status:
        query = query.filter(models.Sale.payment_status == payment_status)
    
    sales = query.order_by(desc(models.Sale.created_at)).all()
    return sales

@app.get("/sales/{sale_id}", response_model=schemas.Sale)
async def get_sale(sale_id: int, user_id: int, db: Session = Depends(get_db)):
    """Get a single sale with items"""
    sale = db.query(models.Sale).filter(
        models.Sale.id == sale_id,
        models.Sale.user_id == user_id
    ).first()
    
    if not sale:
        raise HTTPException(status_code=404, detail="Sale not found")
    
    return sale

# ===== DASHBOARD & ANALYTICS =====
@app.get("/dashboard", response_model=schemas.DashboardStats)
async def get_dashboard_stats(user_id: int, db: Session = Depends(get_db)):
    """Get dashboard statistics"""
    today = datetime.now().date()
    month_start = today.replace(day=1)
    
    # Sales today
    sales_today = db.query(func.sum(models.Sale.total_amount)).filter(
        models.Sale.user_id == user_id,
        func.date(models.Sale.sale_date) == today
    ).scalar() or Decimal("0.00")
    
    # Sales this month
    sales_month = db.query(func.sum(models.Sale.total_amount)).filter(
        models.Sale.user_id == user_id,
        func.date(models.Sale.sale_date) >= month_start
    ).scalar() or Decimal("0.00")
    
    # Count totals
    total_customers = db.query(models.Customer).filter(
        models.Customer.user_id == user_id,
        models.Customer.is_active == True
    ).count()
    
    total_products = db.query(models.Product).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True
    ).count()
    
    # Low stock count
    low_stock_count = db.query(models.Product).join(models.Inventory).filter(
        models.Product.user_id == user_id,
        models.Product.is_active == True,
        models.Inventory.current_stock <= models.Inventory.minimum_stock
    ).count()
    
    # Recent sales
    recent_sales = db.query(models.Sale).filter(
        models.Sale.user_id == user_id
    ).order_by(desc(models.Sale.created_at)).limit(5).all()
    
    return schemas.DashboardStats(
        total_sales_today=sales_today,
        total_sales_this_month=sales_month,
        total_customers=total_customers,
        total_products=total_products,
        low_stock_alerts=low_stock_count,
        recent_sales=recent_sales,
        top_selling_products=[]  # TODO: Implement top selling products
    )

# ===== HEALTH CHECK =====
@app.get("/health")
async def health_check():
    """Health check endpoint"""
    return {
        "status": "healthy",
        "timestamp": datetime.now(),
        "database": get_database_info()
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
