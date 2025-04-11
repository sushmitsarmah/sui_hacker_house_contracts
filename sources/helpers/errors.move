module site_forge::errors;

// --- Generic Errors ---
const EInvalidCaller: u64 = 1;
const EInsufficientFunds: u64 = 2;
const EInvalidAmount: u64 = 3;
const EAdminOnly: u64 = 4;

// --- Subscription Errors ---
const ESubscriptionExpired: u64 = 101;
const ENotSubscribed: u64 = 102;
const EAlreadySubscribed: u64 = 103; // Or handle renewals differently

// --- Deployment Errors ---
const ECidAlreadyDeployed: u64 = 201;
const EInvalidProjectCID: u64 = 202;

// --- SUINS Errors ---
const EInvalidSuinsNameFormat: u64 = 301;
const ESuinsNameTaken: u64 = 302;
const ESuinsRegistrationFailed: u64 = 303;
const ESuinsNameNotFound: u64 = 304;

// --- Access Control Errors ---
const ESealConfigurationFailed: u64 = 401;

// --- Getters for Error Codes ---
public fun invalid_caller(): u64 { EInvalidCaller }
public fun insufficient_funds(): u64 { EInsufficientFunds }
public fun invalid_amount(): u64 { EInvalidAmount }
public fun admin_only(): u64 { EAdminOnly }
public fun subscription_expired(): u64 { ESubscriptionExpired }
public fun not_subscribed(): u64 { ENotSubscribed }
public fun already_subscribed(): u64 { EAlreadySubscribed }
public fun cid_already_deployed(): u64 { ECidAlreadyDeployed }
public fun invalid_project_cid(): u64 { EInvalidProjectCID }
public fun invalid_suins_name_format(): u64 { EInvalidSuinsNameFormat }
public fun suins_name_taken(): u64 { ESuinsNameTaken }
public fun suins_registration_failed(): u64 { ESuinsRegistrationFailed }
public fun suins_name_not_found(): u64 { ESuinsNameNotFound }
public fun seal_configuration_failed(): u64 { ESealConfigurationFailed }
