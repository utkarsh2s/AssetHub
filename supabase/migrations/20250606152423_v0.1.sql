-- Core Database Setup Migration Script
-- This script sets up all necessary tables, RLS policies, triggers

-- First, let's ensure we have the necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
create extension vector;

-- Create enum types
DO $$ BEGIN
    CREATE TYPE source_type AS ENUM ('pdf', 'text', 'website', 'youtube', 'audio');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

create table public.n8n_chat_histories (
  id serial not null,
  session_id character varying(255) not null,
  message jsonb not null,
  constraint n8n_chat_histories_pkey primary key (id)
) TABLESPACE pg_default;

-- Create profiles table (if it doesn't exist)
CREATE TABLE IF NOT EXISTS public.profiles (
    id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email text NOT NULL,
    full_name text,
    avatar_url text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create notebooks table
CREATE TABLE IF NOT EXISTS public.notebooks (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id uuid NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title text NOT NULL,
    description text,
    color text DEFAULT 'gray',
    icon text DEFAULT '📝',
    generation_status text DEFAULT 'completed',
    audio_overview_generation_status text,
    audio_overview_url text,
    audio_url_expires_at timestamp with time zone,
    example_questions text[] DEFAULT '{}',
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create sources table
CREATE TABLE IF NOT EXISTS public.sources (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    notebook_id uuid NOT NULL REFERENCES public.notebooks(id) ON DELETE CASCADE,
    title text NOT NULL,
    type source_type NOT NULL,
    url text,
    file_path text,
    file_size bigint,
    display_name text,
    content text,
    summary text,
    processing_status text DEFAULT 'pending',
    metadata jsonb DEFAULT '{}',
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create notes table
CREATE TABLE IF NOT EXISTS public.notes (
    id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
    notebook_id uuid NOT NULL REFERENCES public.notebooks(id) ON DELETE CASCADE,
    title text NOT NULL,
    content text NOT NULL,
    source_type text DEFAULT 'user',
    extracted_text text,
    created_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at timestamp with time zone DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- Create documents table for vector embeddings
CREATE TABLE IF NOT EXISTS public.documents (
    id bigserial PRIMARY KEY,
    content text,
    metadata jsonb,
    embedding vector(1536)
);

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notebooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sources ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;

-- Drop existing policies
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can update own profile" ON public.profiles;
DROP POLICY IF EXISTS "Users can view own notebooks" ON public.notebooks;
DROP POLICY IF EXISTS "Users can create own notebooks" ON public.notebooks;
DROP POLICY IF EXISTS "Users can update own notebooks" ON public.notebooks;
DROP POLICY IF EXISTS "Users can delete own notebooks" ON public.notebooks;
DROP POLICY IF EXISTS "Users can view sources in own notebooks" ON public.sources;
DROP POLICY IF EXISTS "Users can create sources in own notebooks" ON public.sources;
DROP POLICY IF EXISTS "Users can update sources in own notebooks" ON public.sources;
DROP POLICY IF EXISTS "Users can delete sources in own notebooks" ON public.sources;
DROP POLICY IF EXISTS "Users can view notes in own notebooks" ON public.notes;
DROP POLICY IF EXISTS "Users can create notes in own notebooks" ON public.notes;
DROP POLICY IF EXISTS "Users can update notes in own notebooks" ON public.notes;
DROP POLICY IF EXISTS "Users can delete notes in own notebooks" ON public.notes;
DROP POLICY IF EXISTS "Public documents access" ON public.documents;

-- Profiles RLS
CREATE POLICY "Users can view own profile" ON public.profiles
    FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update own profile" ON public.profiles
    FOR UPDATE USING (auth.uid() = id);

-- Notebooks RLS
CREATE POLICY "Users can view own notebooks" ON public.notebooks
    FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can create own notebooks" ON public.notebooks
    FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update own notebooks" ON public.notebooks
    FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete own notebooks" ON public.notebooks
    FOR DELETE USING (auth.uid() = user_id);

-- Sources RLS
CREATE POLICY "Users can view sources in own notebooks" ON public.sources
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = sources.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can create sources in own notebooks" ON public.sources
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = sources.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can update sources in own notebooks" ON public.sources
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = sources.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can delete sources in own notebooks" ON public.sources
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = sources.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );

-- Notes RLS
CREATE POLICY "Users can view notes in own notebooks" ON public.notes
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = notes.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can create notes in own notebooks" ON public.notes
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = notes.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can update notes in own notebooks" ON public.notes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = notes.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );
CREATE POLICY "Users can delete notes in own notebooks" ON public.notes
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM public.notebooks 
            WHERE notebooks.id = notes.notebook_id 
            AND notebooks.user_id = auth.uid()
        )
    );

-- Documents RLS
CREATE POLICY "Public documents access" ON public.documents
    FOR ALL USING (true);

-- Triggers
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = timezone('utc'::text, now());
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email, full_name)
    VALUES (
        NEW.id,
        NEW.email,
        COALESCE(NEW.raw_user_meta_data ->> 'full_name', NEW.raw_user_meta_data ->> 'name')
    );
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Drop old triggers if exist
DROP TRIGGER IF EXISTS update_profiles_updated_at ON public.profiles;
DROP TRIGGER IF EXISTS update_notebooks_updated_at ON public.notebooks;
DROP TRIGGER IF EXISTS update_sources_updated_at ON public.sources;
DROP TRIGGER IF EXISTS update_notes_updated_at ON public.notes;
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

-- Create updated_at triggers
CREATE TRIGGER update_profiles_updated_at
    BEFORE UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_notebooks_updated_at
    BEFORE UPDATE ON public.notebooks
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_sources_updated_at
    BEFORE UPDATE ON public.sources
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();
CREATE TRIGGER update_notes_updated_at
    BEFORE UPDATE ON public.notes
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();

-- Auth user trigger
CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Enable realtime
ALTER TABLE public.notebooks REPLICA IDENTITY FULL;
ALTER TABLE public.sources REPLICA IDENTITY FULL;
ALTER TABLE public.notes REPLICA IDENTITY FULL;
ALTER TABLE public.profiles REPLICA IDENTITY FULL;

ALTER PUBLICATION supabase_realtime ADD TABLE public.notebooks;
ALTER PUBLICATION supabase_realtime ADD TABLE public.sources;
ALTER PUBLICATION supabase_realtime ADD TABLE public.notes;
ALTER PUBLICATION supabase_realtime ADD TABLE public.profiles;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_notebooks_user_id ON public.notebooks(user_id);
CREATE INDEX IF NOT EXISTS idx_sources_notebook_id ON public.sources(notebook_id);
CREATE INDEX IF NOT EXISTS idx_notes_notebook_id ON public.notes(notebook_id);
CREATE INDEX IF NOT EXISTS idx_documents_embedding ON public.documents USING hnsw (embedding vector_cosine_ops);


-- Storage Policies Migration Script
-- This script cleans up existing policies and creates proper RLS policies for all storage buckets

-- First, remove all existing conflicting policies
DROP POLICY IF EXISTS "Allow authenticated users to upload files" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to view their own files" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own files" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own files" ON storage.objects;
DROP POLICY IF EXISTS "Public bucket access" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload to public bucket" ON storage.objects;
DROP POLICY IF EXISTS "Everyone can view public bucket" ON storage.objects;
DROP POLICY IF EXISTS "Users can delete from public bucket" ON storage.objects;
DROP POLICY IF EXISTS "Users can update public bucket" ON storage.objects;
DROP POLICY IF EXISTS "Audio bucket access for notebook owners" ON storage.objects;
DROP POLICY IF EXISTS "Audio bucket upload for authenticated users" ON storage.objects;
DROP POLICY IF EXISTS "Audio bucket view for notebook owners" ON storage.objects;
DROP POLICY IF EXISTS "Audio bucket delete for notebook owners" ON storage.objects;
DROP POLICY IF EXISTS "Audio bucket update for notebook owners" ON storage.objects;

-- Create a helper function to check notebook ownership
CREATE OR REPLACE FUNCTION public.is_notebook_owner(notebook_id_param uuid)
RETURNS boolean
LANGUAGE sql
SECURITY DEFINER
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM public.notebooks 
    WHERE id = notebook_id_param 
    AND user_id = auth.uid()
  );
$$;

-- SOURCES BUCKET POLICIES (Private files - notebook owners only)
-- Allow notebook owners to INSERT files into their notebook folders
CREATE POLICY "Sources: Insert files for owned notebooks" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'sources' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- Allow notebook owners to SELECT their files
CREATE POLICY "Sources: View files from owned notebooks" ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'sources' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- Allow notebook owners to UPDATE their files
CREATE POLICY "Sources: Update files in owned notebooks" ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'sources' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- Allow notebook owners to DELETE their files
CREATE POLICY "Sources: Delete files from owned notebooks" ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'sources' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- AUDIO BUCKET POLICIES (Audio files - notebook owners only)
-- Allow notebook owners to INSERT audio files
CREATE POLICY "Audio: Insert files for owned notebooks" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (
  bucket_id = 'audio' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- Allow notebook owners to SELECT their audio files
CREATE POLICY "Audio: View files from owned notebooks" ON storage.objects
FOR SELECT
TO authenticated
USING (
  bucket_id = 'audio' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- Allow notebook owners to UPDATE their audio files
CREATE POLICY "Audio: Update files in owned notebooks" ON storage.objects
FOR UPDATE
TO authenticated
USING (
  bucket_id = 'audio' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- Allow notebook owners to DELETE their audio files
CREATE POLICY "Audio: Delete files from owned notebooks" ON storage.objects
FOR DELETE
TO authenticated
USING (
  bucket_id = 'audio' 
  AND public.is_notebook_owner((string_to_array(name, '/'))[1]::uuid)
);

-- PUBLIC-IMAGES BUCKET POLICIES (Public files - all authenticated users)
-- Allow any authenticated user to INSERT public images
CREATE POLICY "Public Images: Insert for authenticated users" ON storage.objects
FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'public-images');

-- Allow anyone to SELECT public images (including anonymous users for public access)
CREATE POLICY "Public Images: View for everyone" ON storage.objects
FOR SELECT
TO anon, authenticated
USING (bucket_id = 'public-images');

-- Allow any authenticated user to UPDATE public images
CREATE POLICY "Public Images: Update for authenticated users" ON storage.objects
FOR UPDATE
TO authenticated
USING (bucket_id = 'public-images');

-- Allow any authenticated user to DELETE public images
CREATE POLICY "Public Images: Delete for authenticated users" ON storage.objects
FOR DELETE
TO authenticated
USING (bucket_id = 'public-images');

-- Update bucket configurations for better security and file management
UPDATE storage.buckets 
SET 
  file_size_limit = 52428800, -- 50MB limit
  allowed_mime_types = ARRAY[
    'application/pdf',
    'text/plain',
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/ogg',
    'audio/m4a',
    'audio/aac',
    'text/markdown',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
  ]
WHERE id = 'sources';

UPDATE storage.buckets 
SET 
  file_size_limit = 104857600, -- 100MB limit for audio files
  allowed_mime_types = ARRAY[
    'audio/mpeg',
    'audio/mp3',
    'audio/wav',
    'audio/ogg',
    'audio/m4a',
    'audio/aac'
  ]
WHERE id = 'audio';

UPDATE storage.buckets 
SET 
  file_size_limit = 10485760, -- 10MB limit for images
  allowed_mime_types = ARRAY[
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/gif',
    'image/webp',
    'image/svg+xml'
  ]
WHERE id = 'public-images';

