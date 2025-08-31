from datetime import timedelta, datetime
from typing import List, Optional
from fastapi import FastAPI, Depends, HTTPException, status, Query, Form, Request
from fastapi.security import OAuth2PasswordRequestForm
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy.orm import Session
from sqlalchemy import func

from database import engine, get_db
import models, schemas, auth

# Create database tables
models.Base.metadata.create_all(bind=engine)

app = FastAPI(title="SmartPOS API")

@app.get("/")
async def root():
    return {"message": "Welcome to SmartPOS API", "documentation": "/docs"}

@app.get("/cors-test")
async def cors_test():
    return {"status": "success", "message": "CORS is working properly!"}
    
@app.options("/auth/register")
async def options_register():
    # This handles the preflight OPTIONS request for /auth/register
    return {}

@app.options("/auth/json-login")
async def options_json_login():
    # This handles the preflight OPTIONS request for /auth/json-login
    return {}

# Configure CORS
origins = [
    "http://localhost:3000",  # Next.js default
    "http://localhost:8080",  # Common dev server
    "http://localhost:8000",  # FastAPI server
    "http://localhost:5000",  # Flutter web default
    "http://localhost:5173",  # Vite default
    "http://127.0.0.1:5173",  # Vite default with IP
    "http://127.0.0.1:3000",  # Next.js with IP
    "http://127.0.0.1:5000",  # Flutter web with IP
    "http://localhost",       # Generic localhost
    "http://127.0.0.1",       # Generic localhost IP
]

# IMPORTANT: Configure CORS properly for Flutter Web
# When using "*" for allow_origins, allow_credentials must be False
# For specific origins, allow_credentials can be True
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # For development, allow all origins
    allow_credentials=False,  # Must be False when using allow_origins=["*"]
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "HEAD", "PATCH"],
    allow_headers=["*"],  # Allow all headers for simplicity in development
    expose_headers=["Content-Length", "Content-Type", "Authorization"],
    max_age=86400,  # Cache preflight results for 24 hours
)

# Authentication endpoints
@app.post("/auth/register", response_model=schemas.UserResponse)
async def register(user: schemas.UserCreate, db: Session = Depends(get_db)):
    # Check if username already exists
    db_user = db.query(models.User).filter(models.User.username == user.username).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Username already registered")
    
    # Check if phone number is already registered
    db_user_phone = db.query(models.User).filter(models.User.phone == user.phone).first()
    if db_user_phone:
        raise HTTPException(status_code=400, detail="Phone number already registered")
    
    # Hash the password (PIN)
    hashed_password = auth.get_password_hash(user.password)
    
    # Create new user
    db_user = models.User(
        username=user.username,
        phone=user.phone,
        shop_name=user.shop_name,
        hashed_password=hashed_password,
        language_preference=user.language_preference
    )
    db.add(db_user)
    db.commit()
    db.refresh(db_user)
    return db_user

@app.post("/auth/login")
async def login(
    request: Request,
    form_data: OAuth2PasswordRequestForm = Depends(),
    db: Session = Depends(get_db)
):
    print(f"Login request received with username: {form_data.username}")
    
    # Check if login is using phone number or username
    user = None
    if form_data.username.isdigit() and len(form_data.username) == 10:  # 10-digit Indian phone number
        user = db.query(models.User).filter(models.User.phone == form_data.username).first()
    else:
        user = db.query(models.User).filter(models.User.username == form_data.username).first()
    
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/phone or PIN",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    print(f"Login successful for user: {user.username}")
    return {"access_token": access_token, "token_type": "bearer"}

# Special login endpoint for Flutter frontend that accepts JSON
@app.post("/auth/json-login", response_model=schemas.TokenResponse)
async def json_login(
    login_data: schemas.UserLogin,
    db: Session = Depends(get_db)
):
    # Check if login is using phone number or username
    user = None
    if login_data.username.isdigit() and len(login_data.username) == 10:  # 10-digit Indian phone number
        user = db.query(models.User).filter(models.User.phone == login_data.username).first()
    else:
        user = db.query(models.User).filter(models.User.username == login_data.username).first()
    
    if not user or not auth.verify_password(login_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username/phone or PIN",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.username}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}



# User endpoints
@app.get("/user/profile", response_model=schemas.UserResponse)
async def read_user_profile(current_user: models.User = Depends(auth.get_current_user)):
    return current_user

@app.put("/user/language", response_model=schemas.UserResponse)
async def update_language_preference(
    language: str,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    if language not in ['en', 'hi']:  # Support for English and Hindi
        raise HTTPException(status_code=400, detail="Unsupported language. Supported languages: en, hi")
    
    current_user.language_preference = language
    db.commit()
    db.refresh(current_user)
    return current_user

# Product endpoints
@app.post("/products", response_model=schemas.ProductResponse)
async def create_product(
    product: schemas.ProductCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_product = models.Product(**product.model_dump(), user_id=current_user.id)
    db.add(db_product)
    db.commit()
    db.refresh(db_product)
    return db_product

@app.get("/products", response_model=List[schemas.ProductResponse])
async def list_products(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    products = db.query(models.Product).filter(models.Product.user_id == current_user.id).all()
    return products

@app.get("/products/{product_id}", response_model=schemas.ProductResponse)
async def get_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == current_user.id
    ).first()
    
    if not product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    return product

@app.put("/products/{product_id}", response_model=schemas.ProductResponse)
async def update_product(
    product_id: int,
    product_update: schemas.ProductUpdate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == current_user.id
    ).first()
    
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    update_data = product_update.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(db_product, field, value)
    
    db.commit()
    db.refresh(db_product)
    return db_product

@app.delete("/products/{product_id}")
async def delete_product(
    product_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_product = db.query(models.Product).filter(
        models.Product.id == product_id,
        models.Product.user_id == current_user.id
    ).first()
    
    if not db_product:
        raise HTTPException(status_code=404, detail="Product not found")
    
    db.delete(db_product)
    db.commit()
    return {"message": "Product deleted successfully"}

@app.get("/inventory", response_model=List[schemas.InventoryResponse])
async def get_inventory(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    inventory = (
        db.query(models.Inventory)
        .join(models.Product)
        .filter(models.Product.user_id == current_user.id)
        .all()
    )
    return inventory

@app.get("/inventory/low-stock", response_model=List[schemas.InventoryResponse])
async def get_low_stock_alerts(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    low_stock = (
        db.query(models.Inventory)
        .join(models.Product)
        .filter(
            models.Product.user_id == current_user.id,
            models.Inventory.quantity <= models.Inventory.reorder_level
        )
        .all()
    )
    return low_stock

# Customer endpoints
@app.post("/customers", response_model=schemas.CustomerResponse)
async def create_customer(
    customer: schemas.CustomerCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    db_customer = models.Customer(**customer.model_dump(), user_id=current_user.id)
    db.add(db_customer)
    db.commit()
    db.refresh(db_customer)
    return db_customer

@app.get("/customers", response_model=List[schemas.CustomerResponse])
async def list_customers(
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    customers = db.query(models.Customer).filter(models.Customer.user_id == current_user.id).all()
    return customers

@app.get("/customers/{customer_id}", response_model=schemas.CustomerResponse)
async def get_customer(
    customer_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    customer = db.query(models.Customer).filter(
        models.Customer.id == customer_id,
        models.Customer.user_id == current_user.id
    ).first()
    
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    return customer

# Transaction endpoints
@app.post("/transactions", response_model=schemas.TransactionResponse)
async def create_transaction(
    transaction: schemas.TransactionCreate,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # Verify the customer belongs to the current user
    customer = db.query(models.Customer).filter(
        models.Customer.id == transaction.customer_id,
        models.Customer.user_id == current_user.id
    ).first()
    
    if not customer:
        raise HTTPException(status_code=404, detail="Customer not found")
    
    db_transaction = models.Transaction(**transaction.model_dump(), user_id=current_user.id)
    db.add(db_transaction)
    db.commit()
    db.refresh(db_transaction)
    return db_transaction

@app.get("/transactions", response_model=List[schemas.TransactionResponse])
async def list_transactions(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    is_paid: Optional[bool] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    query = db.query(models.Transaction).filter(models.Transaction.user_id == current_user.id)
    
    if start_date:
        query = query.filter(models.Transaction.created_at >= start_date)
    
    if end_date:
        query = query.filter(models.Transaction.created_at <= end_date)
    
    if is_paid is not None:
        query = query.filter(models.Transaction.is_paid == is_paid)
    
    transactions = query.order_by(models.Transaction.created_at.desc()).all()
    return transactions

@app.get("/transactions/{transaction_id}", response_model=schemas.TransactionResponse)
async def get_transaction(
    transaction_id: int,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    transaction = db.query(models.Transaction).filter(
        models.Transaction.id == transaction_id,
        models.Transaction.user_id == current_user.id
    ).first()
    
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    return transaction

@app.put("/transactions/{transaction_id}", response_model=schemas.TransactionResponse)
async def update_transaction_payment(
    transaction_id: int,
    is_paid: bool,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    transaction = db.query(models.Transaction).filter(
        models.Transaction.id == transaction_id,
        models.Transaction.user_id == current_user.id
    ).first()
    
    if not transaction:
        raise HTTPException(status_code=404, detail="Transaction not found")
    
    transaction.is_paid = is_paid
    db.commit()
    db.refresh(transaction)
    return transaction

# Reporting endpoints
@app.get("/reports/sales-summary")
async def get_sales_summary(
    start_date: Optional[datetime] = None,
    end_date: Optional[datetime] = None,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    query = db.query(
        func.sum(models.Transaction.total_amount),
        func.count(models.Transaction.id)
    ).filter(models.Transaction.user_id == current_user.id)
    
    if start_date:
        query = query.filter(models.Transaction.created_at >= start_date)
    if end_date:
        query = query.filter(models.Transaction.created_at <= end_date)
    
    total_amount, total_transactions = query.first()
    
    # Get pending payments (credit/udhaar)
    pending_query = db.query(
        func.sum(models.Transaction.total_amount)
    ).filter(
        models.Transaction.user_id == current_user.id,
        models.Transaction.is_paid == False
    )
    
    if start_date:
        pending_query = pending_query.filter(models.Transaction.created_at >= start_date)
    if end_date:
        pending_query = pending_query.filter(models.Transaction.created_at <= end_date)
    
    pending_amount = pending_query.scalar() or 0
    
    return {
        "total_sales": total_amount or 0,
        "total_transactions": total_transactions or 0,
        "pending_amount": pending_amount,
        "start_date": start_date,
        "end_date": end_date
    }

@app.get("/reports/top-products")
async def get_top_products(
    limit: int = 5,
    db: Session = Depends(get_db),
    current_user: models.User = Depends(auth.get_current_user)
):
    # This would require a transaction items table to implement fully
    # For now, we'll return a placeholder response
    products = db.query(models.Product).filter(
        models.Product.user_id == current_user.id
    ).limit(limit).all()
    
    return [schemas.ProductResponse.model_validate(p) for p in products]

# Health check endpoint
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": datetime.utcnow(),
        "version": "1.0.0"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)
