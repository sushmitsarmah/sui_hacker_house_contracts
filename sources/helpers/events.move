module site_forge::events;

use sui::event;
use std::string::String;

/// Emitted when a new subscription NFT is minted.
public struct SubscriptionCreated has copy, drop {
    nft_id: ID,
    owner: address,
    expiration_timestamp_ms: Option<u64>, // Optional expiration
    purchase_token: u8, // 0 for SUI, 1 for SITE
}

/// Emitted when a user links a project/CID to their wallet.
public struct SiteDeployed has copy, drop {
    site_id: ID,         // ID of the DeployedSite object
    owner: address,
    project_cid: vector<u8>,
    suins_name: Option<String>, // If registered during deployment
    subscription_nft_id: Option<ID>, // NFT used for deployment (if required)
}

/// Emitted when a SUINS name is successfully registered for a site.
public struct SuinsRegistered has copy, drop {
    site_id: ID,
    owner: address,
    suins_name: String,
    project_cid: vector<u8>,
}

/// Emitted to signal configuration for Seal protocol access.
public struct SealAccessConfigured has copy, drop {
    site_id: ID,
    owner: address,
    policy_identifier: ID, // Typically the Subscription NFT ID
    // Add other relevant details Seal might need
}

// --- Event Emission Functions ---

public fun emit_subscription_created(
    nft_id: ID,
    owner: address,
    expiration_timestamp_ms: Option<u64>,
    purchase_token_type: u8, // 0 for SUI, 1 for SITE
    _ctx: &TxContext
) {
    event::emit(SubscriptionCreated {
        nft_id,
        owner,
        expiration_timestamp_ms,
        purchase_token: purchase_token_type,
    })
}

public fun emit_site_deployed(
    site_id: ID,
    owner: address,
    project_cid: vector<u8>,
    suins_name: Option<String>,
    subscription_nft_id: Option<ID>,
    _ctx: &TxContext
) {
    event::emit(SiteDeployed {
        site_id,
        owner,
        project_cid,
        suins_name,
        subscription_nft_id,
    })
}

public fun emit_suins_registered(
    site_id: ID,
    owner: address,
    suins_name: String,
    project_cid: vector<u8>,
    _ctx: &TxContext
) {
    event::emit(SuinsRegistered {
        site_id,
        owner,
        suins_name,
        project_cid,
    })
}

public fun emit_seal_access_configured(
    site_id: ID,
    owner: address,
    policy_identifier: ID, // e.g., the NFT ID
    _ctx: &TxContext
) {
    event::emit(SealAccessConfigured {
        site_id,
        owner,
        policy_identifier,
    })
}