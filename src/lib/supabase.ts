import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';
const url=import.meta.env.VITE_SUPABASE_URL as string|undefined;
const key=(import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY||import.meta.env.VITE_SUPABASE_ANON_KEY) as string|undefined;
export const configured=Boolean(url&&key);
export const supabase=configured?createClient<Database>(url!,key!):null;