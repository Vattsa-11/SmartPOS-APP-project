from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, func, Text, Numeric
from sqlalchemy.orm import relationship
from database import Base
from decimal import Decimal

# User/Owner Entity (single shop per user)
class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    supabase_user_id = Column(String, unique=True, index=True, nullable=True)  # Links to Supabase auth
    username = Column(String, unique=True, index=True, nullable=True)  # For direct auth
    email = Column(String, unique=True, index=True)
    password_hash = Column(String, nullable=True)  # For direct auth
    owner_name = Column(String, nullable=False)
    phone = Column(String)
    shop_name = Column(String, nullable=False, default="My Shop")
    address = Column(Text)
    business_type = Column(String, default="retail")
    currency = Column(String, default="INR")
    tax_rate = Column(Numeric(5, 2), default=0.0)  # GST/VAT percentage
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    products = relationship("Product", back_populates="owner", cascade="all, delete-orphan")
    categories = relationship("Category", back_populates="owner", cascade="all, delete-orphan")
    customers = relationship("Customer", back_populates="owner", cascade="all, delete-orphan")
    sales = relationship("Sale", back_populates="owner", cascade="all, delete-orphan")
    inventory_adjustments = relationship("InventoryAdjustment", back_populates="owner")

# Product Categories
class Category(Base):
    __tablename__ = "categories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False, index=True)
    description = Column(Text)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())

    # Relationships
    owner = relationship("User", back_populates="categories")
    products = relationship("Product", back_populates="category")

# Products
class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    category_id = Column(Integer, ForeignKey("categories.id"), nullable=True)
    name = Column(String, nullable=False, index=True)
    description = Column(Text)
    barcode = Column(String, unique=True, index=True)  # Unique barcode
    sku = Column(String, index=True)  # Stock Keeping Unit
    price = Column(Numeric(10, 2), nullable=False)
    cost_price = Column(Numeric(10, 2), default=0.0)  # Purchase price
    selling_price = Column(Numeric(10, 2), nullable=False)  # Same as price, for clarity
    discount_percentage = Column(Numeric(5, 2), default=0.0)
    tax_percentage = Column(Numeric(5, 2), default=0.0)
    unit = Column(String, default="pcs")  # pcs, kg, liter, etc.
    is_active = Column(Boolean, default=True)
    is_featured = Column(Boolean, default=False)
    image_url = Column(String)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    owner = relationship("User", back_populates="products")
    category = relationship("Category", back_populates="products")
    inventory = relationship("Inventory", back_populates="product", uselist=False, cascade="all, delete-orphan")
    sale_items = relationship("SaleItem", back_populates="product")

# Inventory Management
class Inventory(Base):
    __tablename__ = "inventory"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False, unique=True)
    current_stock = Column(Integer, default=0)
    minimum_stock = Column(Integer, default=0)  # Reorder level
    maximum_stock = Column(Integer, default=1000)
    reorder_quantity = Column(Integer, default=0)
    last_restocked_at = Column(DateTime)
    expiry_date = Column(DateTime, nullable=True)
    batch_number = Column(String)
    supplier_info = Column(Text)
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    product = relationship("Product", back_populates="inventory")
    adjustments = relationship("InventoryAdjustment", back_populates="inventory")

# Inventory Adjustments (for tracking stock changes)
class InventoryAdjustment(Base):
    __tablename__ = "inventory_adjustments"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    inventory_id = Column(Integer, ForeignKey("inventory.id"), nullable=False)
    adjustment_type = Column(String, nullable=False)  # 'purchase', 'sale', 'adjustment', 'damage', 'return'
    quantity_change = Column(Integer, nullable=False)  # Positive for additions, negative for reductions
    reason = Column(Text)
    reference_id = Column(String)  # Reference to sale_id, purchase_id, etc.
    created_at = Column(DateTime, default=func.now())

    # Relationships
    owner = relationship("User", back_populates="inventory_adjustments")
    inventory = relationship("Inventory", back_populates="adjustments")

# Customers
class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    name = Column(String, nullable=False, index=True)
    phone = Column(String, index=True)
    email = Column(String)
    address = Column(Text)
    customer_type = Column(String, default="regular")  # regular, vip, wholesale
    credit_limit = Column(Numeric(10, 2), default=0.0)
    current_balance = Column(Numeric(10, 2), default=0.0)  # Outstanding amount
    total_purchases = Column(Numeric(12, 2), default=0.0)  # Lifetime purchases
    last_purchase_at = Column(DateTime)
    is_active = Column(Boolean, default=True)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    owner = relationship("User", back_populates="customers")
    sales = relationship("Sale", back_populates="customer")

# Sales/Transactions
class Sale(Base):
    __tablename__ = "sales"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    customer_id = Column(Integer, ForeignKey("customers.id"), nullable=True)  # Can be walk-in customer
    invoice_number = Column(String, unique=True, index=True)
    subtotal = Column(Numeric(10, 2), nullable=False)
    discount_amount = Column(Numeric(10, 2), default=0.0)
    tax_amount = Column(Numeric(10, 2), default=0.0)
    total_amount = Column(Numeric(10, 2), nullable=False)
    payment_method = Column(String, nullable=False)  # cash, card, upi, credit
    payment_status = Column(String, default="completed")  # completed, pending, partial, cancelled
    paid_amount = Column(Numeric(10, 2), default=0.0)
    change_amount = Column(Numeric(10, 2), default=0.0)
    notes = Column(Text)
    sale_date = Column(DateTime, default=func.now())
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    # Relationships
    owner = relationship("User", back_populates="sales")
    customer = relationship("Customer", back_populates="sales")
    items = relationship("SaleItem", back_populates="sale", cascade="all, delete-orphan")

# Sale Items (Individual products in a sale)
class SaleItem(Base):
    __tablename__ = "sale_items"

    id = Column(Integer, primary_key=True, index=True)
    sale_id = Column(Integer, ForeignKey("sales.id"), nullable=False)
    product_id = Column(Integer, ForeignKey("products.id"), nullable=False)
    quantity = Column(Integer, nullable=False)
    unit_price = Column(Numeric(10, 2), nullable=False)
    discount_percentage = Column(Numeric(5, 2), default=0.0)
    discount_amount = Column(Numeric(10, 2), default=0.0)
    tax_percentage = Column(Numeric(5, 2), default=0.0)
    tax_amount = Column(Numeric(10, 2), default=0.0)
    total_price = Column(Numeric(10, 2), nullable=False)  # (quantity * unit_price) - discount + tax
    created_at = Column(DateTime, default=func.now())

    # Relationships
    sale = relationship("Sale", back_populates="items")
    product = relationship("Product", back_populates="sale_items")
