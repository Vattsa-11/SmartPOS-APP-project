from sqlalchemy import Boolean, Column, ForeignKey, Integer, String, Float, DateTime, func
from sqlalchemy.orm import relationship
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    phone = Column(String)
    shop_name = Column(String)
    hashed_password = Column(String)
    language_preference = Column(String, default="en")
    created_at = Column(DateTime, default=func.now())

    products = relationship("Product", back_populates="owner")
    customers = relationship("Customer", back_populates="owner")
    transactions = relationship("Transaction", back_populates="user")

class Product(Base):
    __tablename__ = "products"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    barcode = Column(String, unique=True, index=True)
    price = Column(Float)
    category = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=func.now())

    owner = relationship("User", back_populates="products")
    inventory = relationship("Inventory", back_populates="product", uselist=False)

class Inventory(Base):
    __tablename__ = "inventory"

    id = Column(Integer, primary_key=True, index=True)
    product_id = Column(Integer, ForeignKey("products.id"))
    quantity = Column(Integer)
    reorder_level = Column(Integer)
    expiry_date = Column(DateTime, nullable=True)

    product = relationship("Product", back_populates="inventory")

class Customer(Base):
    __tablename__ = "customers"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    phone = Column(String)
    user_id = Column(Integer, ForeignKey("users.id"))
    created_at = Column(DateTime, default=func.now())

    owner = relationship("User", back_populates="customers")
    transactions = relationship("Transaction", back_populates="customer")

class Transaction(Base):
    __tablename__ = "transactions"

    id = Column(Integer, primary_key=True, index=True)
    customer_id = Column(Integer, ForeignKey("customers.id"))
    user_id = Column(Integer, ForeignKey("users.id"))
    total_amount = Column(Float)
    payment_type = Column(String)
    is_paid = Column(Boolean, default=False)
    created_at = Column(DateTime, default=func.now())

    customer = relationship("Customer", back_populates="transactions")
    user = relationship("User", back_populates="transactions")
