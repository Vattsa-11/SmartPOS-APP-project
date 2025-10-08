-- SmartPOS Supabase Database Setup - Multi-Shop System
-- Run this script in your Supabase SQL Editor

-- Drop existing tables if they exist (to start fresh)
DROP TABLE IF EXISTS public.sale_items CASCADE;
DROP TABLE IF EXISTS public.sales CASCADE;
DROP TABLE IF EXISTS public.inventory_logs CASCADE;
DROP TABLE IF EXISTS public.products CASCADE;
DROP TABLE IF EXISTS public.user_sessions CASCADE;
DROP TABLE IF EXISTS public.shops CASCADE;
DROP TABLE IF EXISTS public.profiles CASCADE;
DROP TABLE IF EXISTS public.inventory CASCADE; -- Drop old inventory table

-- 1. Create profiles table (One record per user, stores owner info)
CREATE TABLE public.profiles (
    id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL PRIMARY KEY,
    email text UNIQUE NOT NULL,
    owner_name text NOT NULL,
    phone text UNIQUE NOT NULL,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- 2. Create shops table (Multiple shops per owner)
CREATE TABLE public.shops (
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

-- 3. Create user_sessions table to track current shop selection
CREATE TABLE public.user_sessions (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id uuid REFERENCES auth.users ON DELETE CASCADE NOT NULL,
    current_shop_id uuid REFERENCES public.shops ON DELETE CASCADE,
    session_token text UNIQUE,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    UNIQUE(user_id)
);

-- 4. Create products table (linked to shop instead of user)
CREATE TABLE public.products (
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

-- 5. Create inventory_logs table for tracking stock changes
CREATE TABLE public.inventory_logs (
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

-- 6. Create sales table for future sales tracking (linked to shop)
CREATE TABLE public.sales (
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

-- 7. Create sale_items table for sale line items
CREATE TABLE public.sale_items (
    id uuid DEFAULT gen_random_uuid() PRIMARY KEY,
    sale_id uuid REFERENCES public.sales ON DELETE CASCADE NOT NULL,
    product_id uuid REFERENCES public.products ON DELETE CASCADE NOT NULL,
    quantity integer NOT NULL DEFAULT 1,
    unit_price decimal(10,2) NOT NULL DEFAULT 0,
    total_price decimal(10,2) NOT NULL DEFAULT 0,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Enable Row Level Security (RLS) on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.shops ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.inventory_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sale_items ENABLE ROW LEVEL SECURITY;

-- Create RLS policies for profiles
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert own profile" ON public.profiles
    FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Create RLS policies for shops
CREATE POLICY "Users can view own shops" ON public.shops
    FOR SELECT USING (auth.uid() = owner_id);

CREATE POLICY "Users can insert own shops" ON public.shops
    FOR INSERT WITH CHECK (auth.uid() = owner_id);

CREATE POLICY "Users can update own shops" ON public.shops
    FOR UPDATE USING (auth.uid() = owner_id);

CREATE POLICY "Users can delete own shops" ON public.shops
    FOR DELETE USING (auth.uid() = owner_id);

-- Create RLS policies for user_sessions
CREATE POLICY "Users can view own sessions" ON public.user_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions" ON public.user_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions" ON public.user_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions" ON public.user_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for products (now shop-based)
CREATE POLICY "Users can view products from own shops" ON public.products
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert products to own shops" ON public.products
    FOR INSERT WITH CHECK (auth.uid() = user_id AND 
        shop_id IN (SELECT id FROM public.shops WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update products in own shops" ON public.products
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete products from own shops" ON public.products
    FOR DELETE USING (auth.uid() = user_id);

-- Create RLS policies for inventory_logs
CREATE POLICY "Users can view own inventory logs" ON public.inventory_logs
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own inventory logs" ON public.inventory_logs
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Create RLS policies for sales (now shop-based)
CREATE POLICY "Users can view sales from own shops" ON public.sales
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert sales to own shops" ON public.sales
    FOR INSERT WITH CHECK (auth.uid() = user_id AND 
        shop_id IN (SELECT id FROM public.shops WHERE owner_id = auth.uid()));

CREATE POLICY "Users can update sales in own shops" ON public.sales
    FOR UPDATE USING (auth.uid() = user_id);

-- Create RLS policies for sale_items (now shop-based)
CREATE POLICY "Users can view sale items from own shops" ON public.sale_items
    FOR SELECT USING (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

CREATE POLICY "Users can insert sale items to own shops" ON public.sale_items
    FOR INSERT WITH CHECK (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

CREATE POLICY "Users can update sale items in own shops" ON public.sale_items
    FOR UPDATE USING (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

CREATE POLICY "Users can delete sale items from own shops" ON public.sale_items
    FOR DELETE USING (auth.uid() IN (SELECT user_id FROM public.sales WHERE id = sale_id));

-- Create updated trigger function for new multi-shop schema
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, owner_name, phone)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(
            NEW.raw_user_meta_data->>'owner_name', 
            NEW.raw_user_meta_data->>'ownerName',
            NEW.raw_user_meta_data->>'full_name',
            NEW.raw_user_meta_data->>'display_name',
            NEW.raw_user_meta_data->>'username',
            ''
        ),
        COALESCE(NEW.raw_user_meta_data->>'phone', '')
    );
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop existing trigger if it exists
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create trigger to automatically create profile when user is created
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Create function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at on all tables
CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.shops
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.user_sessions
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

CREATE TRIGGER handle_updated_at BEFORE UPDATE ON public.products
    FOR EACH ROW EXECUTE PROCEDURE public.handle_updated_at();

-- Create indexes for better performance
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

-- Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated;

-- Additional helper functions for the multi-shop system

-- Function to get user's shops
CREATE OR REPLACE FUNCTION public.get_user_shops(user_uuid uuid)
RETURNS TABLE (
    shop_id uuid,
    shop_name text,
    shop_description text,
    address text,
    is_active boolean,
    created_at timestamp with time zone
) 
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT id, shop_name, shop_description, address, is_active, created_at
    FROM public.shops
    WHERE owner_id = user_uuid AND is_active = true
    ORDER BY created_at DESC;
$$;

-- Function to get current shop for user
CREATE OR REPLACE FUNCTION public.get_current_shop(user_uuid uuid)
RETURNS TABLE (
    shop_id uuid,
    shop_name text,
    shop_description text,
    address text
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT s.id, s.shop_name, s.shop_description, s.address
    FROM public.shops s
    JOIN public.user_sessions us ON s.id = us.current_shop_id
    WHERE us.user_id = user_uuid AND s.is_active = true;
$$;

-- Function to set current shop for user
CREATE OR REPLACE FUNCTION public.set_current_shop(user_uuid uuid, shop_uuid uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- Verify the shop belongs to the user
    IF NOT EXISTS (
        SELECT 1 FROM public.shops 
        WHERE id = shop_uuid AND owner_id = user_uuid AND is_active = true
    ) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Shop not found or access denied'
        );
    END IF;

    -- Insert or update user session
    INSERT INTO public.user_sessions (user_id, current_shop_id, updated_at)
    VALUES (user_uuid, shop_uuid, now())
    ON CONFLICT (user_id) 
    DO UPDATE SET current_shop_id = shop_uuid, updated_at = now();

    RETURN json_build_object(
        'success', true,
        'message', 'Current shop updated successfully'
    );
END;
$$;

-- Function to check if user has existing profile (for strict validation)
CREATE OR REPLACE FUNCTION public.check_existing_user_profile(user_email text)
RETURNS TABLE (
    user_id uuid,
    email text,
    owner_name text,
    phone text,
    shops_count bigint
)
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT 
        p.id,
        p.email,
        p.owner_name,
        p.phone,
        COUNT(s.id) as shops_count
    FROM public.profiles p
    LEFT JOIN public.shops s ON p.id = s.owner_id AND s.is_active = true
    WHERE LOWER(p.email) = LOWER(user_email)
    GROUP BY p.id, p.email, p.owner_name, p.phone;
$$;

-- Function to check if shop name exists for user (for multi-shop validation)
CREATE OR REPLACE FUNCTION public.check_shop_name_exists(user_uuid uuid, shop_name_input text)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.shops 
        WHERE owner_id = user_uuid 
        AND LOWER(shop_name) = LOWER(shop_name_input)
        AND is_active = true
    );
$$;

-- Function to create new shop for existing user
CREATE OR REPLACE FUNCTION public.create_shop_for_user(
    user_uuid uuid, 
    shop_name_input text, 
    shop_description_input text DEFAULT '',
    address_input text DEFAULT ''
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    new_shop_id uuid;
BEGIN
    -- Check if shop name already exists for this user
    IF public.check_shop_name_exists(user_uuid, shop_name_input) THEN
        RETURN json_build_object(
            'success', false,
            'message', 'Shop name already exists for this user'
        );
    END IF;

    -- Create new shop
    INSERT INTO public.shops (owner_id, shop_name, shop_description, address)
    VALUES (user_uuid, shop_name_input, shop_description_input, address_input)
    RETURNING id INTO new_shop_id;

    -- Set as current shop
    PERFORM public.set_current_shop(user_uuid, new_shop_id);

    RETURN json_build_object(
        'success', true,
        'message', 'Shop created successfully',
        'shop_id', new_shop_id
    );
END;
$$;

-- Verification queries to check table structure and data
SELECT 
    'profiles' as table_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'profiles'
UNION ALL
SELECT 
    'shops' as table_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'shops'
UNION ALL
SELECT 
    'user_sessions' as table_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'user_sessions'
UNION ALL
SELECT 
    'products' as table_name,
    column_name, 
    data_type, 
    is_nullable
FROM information_schema.columns
WHERE table_schema = 'public' AND table_name = 'products'
ORDER BY table_name, column_name;