"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.supabase = void 0;
exports.verifyUserToken = verifyUserToken;
const supabase_js_1 = require("@supabase/supabase-js");
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
const supabaseUrl = process.env.SUPABASE_URL || '';
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY || '';
if (!supabaseUrl || !supabaseAnonKey) {
    console.warn('Warning: SUPABASE_URL or SUPABASE_ANON_KEY is not defined in environment variables.');
}
exports.supabase = (0, supabase_js_1.createClient)(supabaseUrl, supabaseAnonKey);
async function verifyUserToken(token) {
    try {
        const { data: { user }, error } = await exports.supabase.auth.getUser(token);
        if (error || !user) {
            return null;
        }
        return user;
    }
    catch (err) {
        console.error('Error verifying Supabase token:', err);
        return null;
    }
}
