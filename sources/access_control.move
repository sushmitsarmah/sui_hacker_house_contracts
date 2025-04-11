/// Module for managing access control signaling, intended for Seal Protocol integration.
module site_forge::access_control;

use site_forge::site_deployment::{Self as site_deploy, DeployedSite};
use site_forge::subscription_nft::{Self as sub_nft, SubscriptionNFT}; // Needed if policy is based on NFT ID
use site_forge::errors;
use site_forge::events;

/// Capability for admin actions (e.g., defining default policies).
public struct AdminCap has key, store { id: UID }

fun init(ctx: &mut TxContext) {
    transfer::transfer(AdminCap { id: object::new(ctx) }, tx_context::sender(ctx));
}

/// Sets up access control for a deployed site, typically based on NFT ownership.
/// This function primarily emits an event for an off-chain Seal service to process.
public entry fun setup_seal_access_for_site(
    site: &DeployedSite,        // The site requiring access control
    subscription_nft: &SubscriptionNFT, // The NFT governing access
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    // 1. Verify Ownership: Ensure the sender owns both the site and the NFT
    assert!(site_deploy::owner(site) == sender, errors::invalid_caller());
    assert!(sub_nft::owner(subscription_nft) == sender, errors::invalid_caller());

    let subscription_nft_id = site_deploy::sub_nft_id(site);

    // 2. Verify Linkage (Optional but recommended): Ensure the NFT used matches the one stored on the site
    assert!(option::is_some(&subscription_nft_id), errors::seal_configuration_failed()); // Site must have linked NFT
    assert!(option::contains(&subscription_nft_id, &object::id(subscription_nft)), errors::seal_configuration_failed()); // NFT must match the one used for deployment

    // 3. Define Policy Identifier: Use the Subscription NFT ID as the key for the access group/policy in Seal.
    let policy_identifier = object::id(subscription_nft);

    // 4. Emit Event: Signal to the off-chain Seal service to configure access.
    // The off-chain service will listen for this event and use the Seal SDK/API
    // to associate the `site.project_cid` (or Walrus asset ID derived from it)
    // with an access policy gated by ownership of the `policy_identifier` (the NFT).
    events::emit_seal_access_configured(
        object::id(site),
        sender,
        policy_identifier,
        ctx
    );

    // Note: No on-chain state is typically modified here unless tracking configuration status.
    // The core logic resides within the Seal system, triggered by this event.
}

/// Function to signal revocation (e.g., when NFT is burned or transferred).
/// This would likely be called by the NFT module's transfer/burn logic or an admin.
/// Again, primarily emits an event.
public fun signal_seal_revocation(
    site_id: ID, // ID of the site whose access is being revoked/updated
    owner: address, // Owner triggering the revocation (for logging/auth)
    policy_identifier: ID, // The NFT ID whose policy is affected
    ctx: &mut TxContext, // Context needed for event emission
) {
    // Emit a different event, e.g., `SealAccessRevoked`
    // event::emit(SealAccessRevoked { site_id, owner, policy_identifier });
    // For simplicity, we'll reuse the configuration event, and the off-chain service
    // interprets the context (e.g., if the NFT no longer exists for the owner).
    // A dedicated revocation event is cleaner. Let's assume one exists or reuse:
        events::emit_seal_access_configured( // Reusing event; context implies update/revocation
            site_id,
            owner,
            policy_identifier,
            ctx
        );
}


// #[test_only]
// use sui::test_scenario::{Self as ts, Scenario, next_tx, ctx};
// #[test_only]
// use site_forge::site_deployment;
// #[test_only]
// use site_forge::subscription_nft;

// #[test_only]
// const ADMIN: address = @0xADMIN;
// #[test_only]
// const USER: address = @0xUSER;

// #[test_only]
// fun setup_access_control_test(scenario: &mut Scenario) {
//     // Init dependent modules, create NFT and DeployedSite for user
//     subscription_nft::init(ctx(scenario)); next_tx(scenario, ADMIN);
//     site_deployment::init(ctx(scenario)); next_tx(scenario, ADMIN);
//     init(ctx(scenario)); next_tx(scenario, ADMIN); // Init this module

//     // Mint NFT for user
//     {
//         let mint_cap = ts::take_shared<subscription_nft::MintCap>(scenario);
//         let clock = ts::clock(scenario);
//         subscription_nft::_mint_internal(&mint_cap, USER, clock, ctx(scenario), 0);
//         ts::return_shared(mint_cap);
//     };
//     next_tx(scenario, ADMIN);

//     // Deploy a site for user (capturing the NFT ID)
//     {
//         let nft = ts::take_from_address<SubscriptionNFT>(scenario, USER);
//         let clock = ts::clock(scenario);
//         let cid = b"QmAccessControlExampleCid";
//         site_deployment::deploy_site(&nft, cid, clock, ctx(scenario));
//             // Return NFT BEFORE the deploy site transaction finishes if deploy_site doesn't consume it
//             ts::return_to_address(USER, nft);
//     };
//     next_tx(scenario, USER);
// }

// #[test]
// fun test_setup_access() {
//         let mut scenario = ts::begin(ADMIN);
//         setup_access_control_test(&mut scenario);

//         // --- User Setup Seal Access Transaction ---
//     {
//         let site = ts::take_from_address<DeployedSite>(&scenario, USER);
//         let nft = ts::take_from_address<SubscriptionNFT>(&scenario, USER); // Take the NFT again

//         setup_seal_access_for_site(&site, &nft, ctx(&mut scenario));

//         // Event emission check should be done via test framework capabilities

//             // Return objects
//             ts::return_to_address(USER, site);
//             ts::return_to_address(USER, nft);
//     };
//     next_tx(&mut scenario, USER); // End setup access tx

//         ts::end(scenario);
// }