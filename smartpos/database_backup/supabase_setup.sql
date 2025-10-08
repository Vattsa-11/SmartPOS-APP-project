-- SmartPOS Supabase Database Setup
-- Run this script in your Supabase SQL Editor

-- 1. Create or update profiles table (One record per user, stores owner info)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
    email text UNIQUE NOT NULL,
    owner_name text NOT NULL,
    phone text UNIQUE NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 1a. Create shops table (Multiple shops per owner)
CREATE TABLE IF NOT EXISTS public.shops (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    owner_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    shop_name text NOT NULL,
    shop_description text,
    address text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(owner_id, shop_name)
);

-- 1b. Create user_sessions table to track current shop selection
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    current_shop_id uuid REFERENCES public.shops ON DELETE CASCADE,
    session_token text UNIQUE,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id)
);

-- Add owner_name column if it doesn't exist (for existing installations)
DO $$ 
BEGIN
    -- Remove shop_name from profiles if it exists (now handled by shops table)
    IF EXISTS (SELECT 1 FROM information_schema.columns 
               WHERE table_name = 'profiles' AND column_name = 'shop_name') THEN
        ALTER TABLE public.profiles DROP COLUMN shop_name;
    END IF;
    
    -- Add owner_name column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'profiles' AND column_name = 'owner_name') THEN
        ALTER TABLE public.profiles ADD COLUMN owner_name text NOT NULL DEFAULT '';
    END IF;
END $$;

-- 2. Create products table (linked to shop instead of user)
CREATE TABLE IF NOT EXISTS public.products (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    shop_id uuid REFERENCES public.shops ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    name text NOT NULL,
    category text NOT NULL,
    price decimal(10,2) NOT NULL DEFAULT 0,
    stock_quantity integer NOT NULL DEFAULT 0,
    description text,
    barcode text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 3. Create inventory_logs table for tracking stock changes
CREATE TABLE IF NOT EXISTS public.inventory_logs (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    product_id uuid REFERENCES public.products ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    change_type text NOT NULL CHECK (change_type IN ('increase', 'decrease', 'adjustment')),
    quantity_change integer NOT NULL,
    previous_quantity integer NOT NULL,
    new_quantity integer NOT NULL,
    notes text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 4. Create sales table for future sales tracking (linked to shop)
CREATE TABLE IF NOT EXISTS public.sales (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    shop_id uuid REFERENCES public.shops ON DELETE CASCADE NOT NULL,
    user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    customer_name text,
    customer_phone text,
    total_amount decimal(10,2) NOT NULL DEFAULT 0,
    discount_amount decimal(10,2) NOT NULL DEFAULT 0,
    final_amount decimal(10,2) NOT NULL DEFAULT 0,
    payment_method text NOT NULL DEFAULT 'cash',
    status text NOT NULL DEFAULT 'completed' CHECK (status IN ('pending', 'completed', 'cancelled')),
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 5. Create sale_items table for sale line items
CREATE TABLE IF NOT EXISTS public.sale_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id uuid REFERENCES public.sales ON DELETE CASCADE NOT NULL,
    product_id uuid REFERENCES public.products ON DELETE CASCADE NOT NULL,
    quantity integer NOT NULL DEFAULT 1,
    unit_price decimal(10,2) NOT NULL DEFAULT 0,
    total_price decimal(10,2) NOT NULL DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 6. Enable Row Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS Policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

-- 7a. Create RLS Policies for shops
CREATE POLICY "Users can view own shops" ON public.shops
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own shops" ON public.shops
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own shops" ON public.shops
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own shops" ON public.shops
    FOR DELETE USING (auth.uid() = owner_id);

-- 7b. Create RLS Policies for user_sessions
CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.user_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON public.user_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions" ON public.user_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- 8. Create RLS Policies for products (now shop-based)
CREATE POLICY "Users can view products from own shops" ON public.products
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert products to own shops" ON public.products
    FOR INSERT WITH CHECK (auth.uid() = user_id AND 
        shop_id IN (SELECT id FROM public.shops WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update products in own shops" ON public.products
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete products from own shops" ON public.products
    FOR DELETE USING (auth.uid() = user_id);

-- 9. Create RLS Policies for inventory_logs
CREATE POLICY "Users can view own inventory logs" ON public.inventory_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own inventory logs" ON public.inventory_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- 10. Create RLS Policies for sales (now shop-based)
CREATE POLICY "Users can view sales from own shops" ON public.sales
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert sales to own shops" ON public.sales
    FOR INSERT WITH CHECK (auth.uid() = user_id AND 
        shop_id IN (SELECT id FROM public.shops WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update sales in own shops" ON public.sales
    FOR UPDATE USING (auth.uid() = user_id);

-- 11. Create RLS Policies for sale_items (now shop-based)
CREATE POLICY "Users can view sale items from own shops" ON public.sale_items
    FOR SELECT USING (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

CREATE POLICY "Users can insert sale items to own shops" ON public.sale_items
    FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

CREATE POLICY "Users can update sale items in own shops" ON public.sale_items
    FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

CREATE POLICY "Users can delete sale items from own shops" ON public.sale_items
    FOR DELETE USING (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

-- 12. Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_shops_owner_id ON public.shops(owner_id);
CREATE INDEX IF NOT EXISTS idx_shops_owner_shop_name ON public.shops(owner_id, shop_name);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user_id ON public.user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_products_shop_id ON public.products(shop_id);
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_category ON public.products(category);
CREATE INDEX IF NOT EXISTS idx_products_name ON public.products(name);
CREATE INDEX IF NOT EXISTS idx_inventory_logs_product_id ON public.inventory_logs(product_id);
CREATE INDEX IF NOT EXISTS idx_inventory_logs_user_id ON public.inventory_logs(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_shop_id ON public.sales(shop_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON public.sales(user_id);
CREATE INDEX IF NOT EXISTS idx_sales_created_at ON public.sales(created_at);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON public.sale_items(sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON public.sale_items(product_id);

-- 13. Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 14. Create triggers for updated_at
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.shops
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.user_sessions
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- 15. Grant permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;