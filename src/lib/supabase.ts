import { createClient } from '@supabase/supabase-js';
import type { Database } from './database.types';

const url=(import.meta.env.VITE_SUPABASE_URL||'https://jltlnmycbjlvcajfgiff.supabase.co') as string;
const key=(import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY||import.meta.env.VITE_SUPABASE_ANON_KEY||'sb_publishable_yqWXUq32qXV6gGuikXEmbw_j3RmouVc') as string;

export const configured=Boolean(url&&key);
export const supabase=createClient<Database>(url,key);
