module site_forge::constants;

// use sui::coin::Coin;
// use sui::sui::SUI;
// use site_builder::utility_token::SITE;

// --- Subscription Prices ---
// Price in SUI (e.g., 1 SUI = 1_000_000_000 MIST)
const SUBSCRIPTION_PRICE_SUI: u64 = 1_000_000_000; // 1 SUI
// Price in SITE token (adjust decimals as needed)
const SUBSCRIPTION_PRICE_SITE: u64 = 100_000_000_000; // 100 SITE (assuming 9 decimals)

// --- Token Info ---
const SITE_TOKEN_NAME: vector<u8> = b"Site Forge Token";
const SITE_TOKEN_SYMBOL: vector<u8> = b"SFT";
const SITE_TOKEN_DECIMALS: u8 = 9;
const SITE_TOKEN_ICON_URL: vector<u8> = b"https://example.com/site_token_icon.png"; // Replace with actual URL

// --- Capabilities ---
// Define struct tags for capabilities if needed, or rely on module structure

// --- Getters ---
public fun subscription_price_sui(): u64 { SUBSCRIPTION_PRICE_SUI }
public fun subscription_price_site(): u64 { SUBSCRIPTION_PRICE_SITE }
public fun site_token_name(): vector<u8> { SITE_TOKEN_NAME }
public fun site_token_symbol(): vector<u8> { SITE_TOKEN_SYMBOL }
public fun site_token_decimals(): u8 { SITE_TOKEN_DECIMALS }
public fun site_token_icon_url(): vector<u8> { SITE_TOKEN_ICON_URL }

// --- SUINS Related ---
// Example TLD - adjust as per your requirements with SUINS
const SUINS_ALLOWED_TLD: vector<u8> = b".ai.sui";
const MIN_SUINS_NAME_LENGTH: u64 = 3;

public fun suins_allowed_tld(): vector<u8> { SUINS_ALLOWED_TLD }
public fun min_suins_name_length(): u64 { MIN_SUINS_NAME_LENGTH }