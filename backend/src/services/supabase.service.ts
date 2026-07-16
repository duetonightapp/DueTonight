import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';

dotenv.config();

const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';

if (!supabaseUrl || !supabaseAnonKey) {
  console.warn('Warning: SUPABASE_URL or SUPABASE_ANON_KEY is not defined in environment variables.');
}

export const supabase = createClient(supabaseUrl, supabaseAnonKey);

export async function verifyUserToken(token: string) {
  try {
    const { data: { user }, error } = await supabase.auth.getUser(token);
    if (error || !user) {
      return null;
    }
    return user;
  } catch (err) {
    console.error('Error verifying Supabase token:', err);
    return null;
  }
}
