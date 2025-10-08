from pydantic import BaseModel, validator, Field
from typing import Optional, List
from datetime import datetime
from decimal import Decimal
from enum import Enum

# Enums for constrained values
class PaymentMethod(str, Enum):
    CASH = "cash"
    CARD = "card"
    UPI = "upi"
    CREDIT = "credit"
    BANK_TRANSFER = "bank_transfer"

class PaymentStatus(str, Enum):
    COMPLETED = "completed"
    PENDING = "pending"
    PARTIAL = "partial"
    CANCELLED = "cancelled"

class CustomerType(str, Enum):
    REGULAR = "regular"
    VIP = "vip"
    WHOLESALE = "wholesale"

class AdjustmentType(str, Enum):
    PURCHASE = "purchase"
    SALE = "sale"
    ADJUSTMENT = "adjustment"
    DAMAGE = "damage"
    RETURN = "return"
    EXPIRED = "expired"

# ===== USER SCHEMAS =====
class UserBase(BaseModel):
    email: str
    owner_name: str = Field(..., min_length=1, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    shop_name: str = Field(..., min_length=1, max_length=100)
    address: Optional[str] = None
    business_type: str = "retail"
    currency: str = "INR"
    tax_rate: Decimal = Field(default=Decimal("0.0"), ge=0, le=100)

class UserCreate(UserBase):
    supabase_user_id: str  # Links to Supabase auth user

class UserUpdate(BaseModel):
    owner_name: Optional[str] = None
    phone: Optional[str] = None
    shop_name: Optional[str] = None
    address: Optional[str] = None
    business_type: Optional[str] = None
    currency: Optional[str] = None
    tax_rate: Optional[Decimal] = None
    is_active: Optional[bool] = None

class User(UserBase):
    id: int
    supabase_user_id: str
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ===== CATEGORY SCHEMAS =====
class CategoryBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=50)
    description: Optional[str] = None

class CategoryCreate(CategoryBase):
    user_id: int

class CategoryUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    is_active: Optional[bool] = None

class Category(CategoryBase):
    id: int
    user_id: int
    is_active: bool
    created_at: datetime

    class Config:
        from_attributes = True

# ===== PRODUCT SCHEMAS =====
class ProductBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    description: Optional[str] = None
    barcode: Optional[str] = Field(None, max_length=50)
    sku: Optional[str] = Field(None, max_length=50)
    price: Decimal = Field(..., gt=0, decimal_places=2)
    cost_price: Decimal = Field(default=Decimal("0.0"), ge=0, decimal_places=2)
    selling_price: Decimal = Field(..., gt=0, decimal_places=2)
    discount_percentage: Decimal = Field(default=Decimal("0.0"), ge=0, le=100)
    tax_percentage: Decimal = Field(default=Decimal("0.0"), ge=0, le=100)
    unit: str = "pcs"
    is_featured: bool = False
    image_url: Optional[str] = None

class ProductCreate(ProductBase):
    category_id: Optional[int] = None
    # Initial inventory
    initial_stock: int = Field(default=0, ge=0)
    minimum_stock: int = Field(default=0, ge=0)
    maximum_stock: int = Field(default=1000, ge=0)

class ProductUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    category_id: Optional[int] = None
    barcode: Optional[str] = None
    sku: Optional[str] = None
    price: Optional[Decimal] = None
    cost_price: Optional[Decimal] = None
    selling_price: Optional[Decimal] = None
    discount_percentage: Optional[Decimal] = None
    tax_percentage: Optional[Decimal] = None
    unit: Optional[str] = None
    is_active: Optional[bool] = None
    is_featured: Optional[bool] = None
    image_url: Optional[str] = None

class Product(ProductBase):
    id: int
    user_id: int
    category_id: Optional[int]
    is_active: bool
    created_at: datetime
    updated_at: datetime
    # Include inventory info
    current_stock: Optional[int] = None
    minimum_stock: Optional[int] = None

    class Config:
        from_attributes = True

# ===== INVENTORY SCHEMAS =====
class InventoryBase(BaseModel):
    current_stock: int = Field(..., ge=0)
    minimum_stock: int = Field(default=0, ge=0)
    maximum_stock: int = Field(default=1000, ge=0)
    reorder_quantity: int = Field(default=0, ge=0)
    expiry_date: Optional[datetime] = None
    batch_number: Optional[str] = None
    supplier_info: Optional[str] = None

class InventoryUpdate(BaseModel):
    current_stock: Optional[int] = None
    minimum_stock: Optional[int] = None
    maximum_stock: Optional[int] = None
    reorder_quantity: Optional[int] = None
    expiry_date: Optional[datetime] = None
    batch_number: Optional[str] = None
    supplier_info: Optional[str] = None

class Inventory(InventoryBase):
    id: int
    product_id: int
    last_restocked_at: Optional[datetime]
    updated_at: datetime

    class Config:
        from_attributes = True

# ===== INVENTORY ADJUSTMENT SCHEMAS =====
class InventoryAdjustmentCreate(BaseModel):
    inventory_id: int
    adjustment_type: AdjustmentType
    quantity_change: int  # Can be negative
    reason: Optional[str] = None
    reference_id: Optional[str] = None

class InventoryAdjustment(BaseModel):
    id: int
    user_id: int
    inventory_id: int
    adjustment_type: AdjustmentType
    quantity_change: int
    reason: Optional[str]
    reference_id: Optional[str]
    created_at: datetime

    class Config:
        from_attributes = True

# ===== CUSTOMER SCHEMAS =====
class CustomerBase(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    phone: Optional[str] = Field(None, max_length=20)
    email: Optional[str] = None
    address: Optional[str] = None
    customer_type: CustomerType = CustomerType.REGULAR
    credit_limit: Decimal = Field(default=Decimal("0.0"), ge=0, decimal_places=2)

class CustomerCreate(CustomerBase):
    user_id: int

class CustomerUpdate(BaseModel):
    name: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[str] = None
    address: Optional[str] = None
    customer_type: Optional[CustomerType] = None
    credit_limit: Optional[Decimal] = None
    is_active: Optional[bool] = None

class Customer(CustomerBase):
    id: int
    user_id: int
    current_balance: Decimal
    total_purchases: Decimal
    last_purchase_at: Optional[datetime]
    is_active: bool
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True

# ===== SALE ITEM SCHEMAS =====
class SaleItemBase(BaseModel):
    product_id: int
    quantity: int = Field(..., gt=0)
    unit_price: Decimal = Field(..., gt=0, decimal_places=2)
    discount_percentage: Decimal = Field(default=Decimal("0.0"), ge=0, le=100)
    discount_amount: Decimal = Field(default=Decimal("0.0"), ge=0, decimal_places=2)
    tax_percentage: Decimal = Field(default=Decimal("0.0"), ge=0, le=100)
    tax_amount: Decimal = Field(default=Decimal("0.0"), ge=0, decimal_places=2)

class SaleItemCreate(SaleItemBase):
    pass

class SaleItem(SaleItemBase):
    id: int
    sale_id: int
    total_price: Decimal
    created_at: datetime
    # Include product info
    product_name: Optional[str] = None

    class Config:
        from_attributes = True

# ===== SALE SCHEMAS =====
class SaleBase(BaseModel):
    customer_id: Optional[int] = None
    payment_method: PaymentMethod
    notes: Optional[str] = None

class SaleCreate(SaleBase):
    user_id: int
    items: List[SaleItemCreate] = Field(..., min_items=1)
    paid_amount: Decimal = Field(..., ge=0, decimal_places=2)

    @validator('items')
    @classmethod
    def validate_items(cls, v):
        if not v:
            raise ValueError('Sale must have at least one item')
        return v

class SaleUpdate(BaseModel):
    customer_id: Optional[int] = None
    payment_method: Optional[PaymentMethod] = None
    payment_status: Optional[PaymentStatus] = None
    paid_amount: Optional[Decimal] = None
    notes: Optional[str] = None

class Sale(SaleBase):
    id: int
    user_id: int
    invoice_number: str
    subtotal: Decimal
    discount_amount: Decimal
    tax_amount: Decimal
    total_amount: Decimal
    payment_status: PaymentStatus
    paid_amount: Decimal
    change_amount: Decimal
    sale_date: datetime
    created_at: datetime
    updated_at: datetime
    # Related data
    items: List[SaleItem] = []
    customer_name: Optional[str] = None

    class Config:
        from_attributes = True

# ===== ANALYTICS/DASHBOARD SCHEMAS =====
class DashboardStats(BaseModel):
    total_sales_today: Decimal
    total_sales_this_month: Decimal
    total_customers: int
    total_products: int
    low_stock_alerts: int
    recent_sales: List[Sale]
    top_selling_products: List[dict]

class SalesReport(BaseModel):
    period: str
    total_sales: Decimal
    total_transactions: int
    average_transaction_value: Decimal
    sales_by_payment_method: dict
    daily_sales: List[dict]

# ===== RESPONSE SCHEMAS =====
class APIResponse(BaseModel):
    success: bool
    message: str
    data: Optional[dict] = None

class PaginatedResponse(BaseModel):
    items: List[dict]
    total: int
    page: int
    per_page: int
    pages: int

# ===== AUTHENTICATION SCHEMAS (for internal user management) =====
class UserAuth(BaseModel):
    supabase_user_id: str
    email: str
    is_active: bool = True
