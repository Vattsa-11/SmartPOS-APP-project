from pydantic import BaseModel, Field
from typing import Optional
from datetime import datetime

class UserBase(BaseModel):
    username: str
    phone: str
    shop_name: str
    language_preference: str = "en"

class UserCreate(UserBase):
    password: str = Field(..., min_length=4, max_length=4)  # 4-digit PIN

class UserLogin(BaseModel):
    username: str
    password: str = Field(..., min_length=4, max_length=4)
    
class TokenResponse(BaseModel):
    access_token: str
    token_type: str

class UserResponse(UserBase):
    id: int
    created_at: datetime

    class Config:
        from_attributes = True

class ProductBase(BaseModel):
    name: str
    barcode: str
    price: float
    category: str

class ProductCreate(ProductBase):
    pass

class ProductUpdate(ProductBase):
    name: Optional[str] = None
    barcode: Optional[str] = None
    price: Optional[float] = None
    category: Optional[str] = None

class ProductResponse(ProductBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class InventoryBase(BaseModel):
    product_id: int
    quantity: int
    reorder_level: int
    expiry_date: Optional[datetime] = None

class InventoryResponse(InventoryBase):
    id: int
    product: ProductResponse

    class Config:
        from_attributes = True

class CustomerBase(BaseModel):
    name: str
    phone: str

class CustomerCreate(CustomerBase):
    pass

class CustomerResponse(CustomerBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class TransactionBase(BaseModel):
    customer_id: int
    total_amount: float
    payment_type: str
    is_paid: bool = False

class TransactionCreate(TransactionBase):
    pass

class TransactionResponse(TransactionBase):
    id: int
    user_id: int
    created_at: datetime
    customer: CustomerResponse

    class Config:
        from_attributes = True
