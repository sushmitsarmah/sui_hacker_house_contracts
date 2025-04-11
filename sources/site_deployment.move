module site_forge::site_deployment;

use sui::clock::{Clock}; // Needed if checking NFT expiration during deployment
use std::string::String;

use site_forge::subscription_nft::{Self as sub_nft, SubscriptionNFT};
use site_forge::errors;
use site_forge::events;
// Potentially SUINS module if registration happens concurrently
// use site_forge::suins_integration;

/// Represents a deployed site linked to a user and potentially a SUINS name.
public struct DeployedSite has key, store {
    id: UID,
    owner: address,
    project_cid: vector<u8>, // Content Identifier (e.g., IPFS CID)
    suins_name: Option<String>, // Optional linked SUINS name
    subscription_nft_id: Option<ID>, // ID of the NFT used for this deployment (if gated)
    deployment_timestamp_ms: u64,
}

/// Admin capability (optional, e.g., for managing deployment rules).
public struct AdminCap has key, store { id: UID }

// Initialization function (optional, e.g., to create AdminCap)
fun init(ctx: &mut TxContext) {
        transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx));
}

/// Deploys a site, linking a CID to the user's wallet.
/// Requires a valid SubscriptionNFT to proceed.
public entry fun deploy_site(
    subscription_nft: &SubscriptionNFT, // Pass the user's NFT object
    project_cid: vector<u8>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    // 1. Verify Ownership: Check if the sender owns the provided NFT
    assert!(sub_nft::owner(subscription_nft) == sender, errors::invalid_caller());

    // 2. Verify Subscription Status: Check if the NFT is valid/active
    assert!(sub_nft::is_subscribed(subscription_nft, clock), errors::subscription_expired());

    // 3. Validate CID (basic check)
    assert!(vector::length(&project_cid) > 10, errors::invalid_project_cid()); // Example: Basic length check

    // 4. Optional: Prevent duplicate CIDs per user?
    // This would require querying existing DeployedSite objects, complex on-chain.
    // Often handled off-chain or by assuming unique CIDs represent new deployments.

    // 5. Create the DeployedSite object
    let current_time = sui::clock::timestamp_ms(clock);
    let site = DeployedSite {
        id: object::new(ctx),
        owner: sender,
        project_cid: project_cid,
        suins_name: option::none(), // SUINS registration is a separate step typically
        subscription_nft_id: option::some(object::id(subscription_nft)),
        deployment_timestamp_ms: current_time,
    };
    let site_id = object::id(&site);

    // 6. Emit event for backend processing (Walrus deployment)
    events::emit_site_deployed(
        site_id,
        sender,
        site.project_cid, // Use the stored CID
        site.suins_name,   // None initially
        site.subscription_nft_id,
        ctx
    );

    // 7. Transfer the DeployedSite object to the owner
    transfer::public_transfer(site, sender);
}

    /// View function to get deployment details.
public fun get_deployment_details(site: &DeployedSite): (ID, address, vector<u8>, Option<String>, Option<ID>) {
    (
        object::id(site),
        site.owner,
        site.project_cid,
        site.suins_name,
        site.subscription_nft_id
    )
}


// #[test_only]
// use sui::test_scenario::{Self as ts, Scenario, next_tx, ctx};
// #[test_only]
// use site_forge::subscription_nft::MintCap as SubMintCap;
// #[test_only]
// use site_forge::subscription_nft::Treasury as SubTreasury;

// #[test_only]
// const ADMIN: address = @0xADMIN;
// #[test_only]
// const USER: address = @0xUSER;

// #[test_only]
// fun setup_deployment_test(scenario: &mut Scenario) {
//     // Init subscription module and give user an NFT
//     sub_nft::init(ctx(scenario));
//     next_tx(scenario, ADMIN);

//     {
//         // Mint an NFT for the user (simplified: directly without payment for test)
//         let mint_cap = ts::take_shared<SubMintCap>(scenario);
//         let clock = ts::clock(scenario);
//         // Internal mint needs payment type, let's say SUI (0)
//         sub_nft::_mint_internal(&mint_cap, USER, clock, ctx(scenario), 0);
//         ts::return_shared(mint_cap);
//     };
//         next_tx(scenario, ADMIN); // End NFT minting tx

//         // Init deployment module
//         init(ctx(scenario));
//         next_tx(scenario, ADMIN); // End deployment init tx
// }

// #[test]
// fun test_deploy() {
//     let mut scenario = ts::begin(ADMIN);
//     setup_deployment_test(&mut scenario);

//     // --- User Deploy Transaction ---
//     {
//         let nft = ts::take_from_address<SubscriptionNFT>(&scenario, USER);
//         let clock = ts::clock(&scenario);
//         let cid = b"QmExampleCidThatIsLongEnough"; // Example CID

//         deploy_site(&nft, cid, clock, ctx(&mut scenario));

//         // Return NFT to user
//         ts::return_to_address(USER, nft);
//     };
//     next_tx(&mut scenario, USER); // End user deploy tx

//     // --- Verification ---
//     {
//         let site = ts::take_from_address<DeployedSite>(&scenario, USER);
//         assert!(site.owner == USER, 1);
//         assert!(vector::length(&site.project_cid) > 0, 2);
//         assert!(option::is_some(&site.subscription_nft_id), 3);

//             // Check event emission (requires test framework support or off-chain check)

//         // Clean up test object
//         ts::return_to_address(USER, site); // Or burn if test logic requires
//     };

//     ts::end(scenario);
// }