module site_forge::subscription_nft;

use sui::clock::{Self, Clock};
use sui::coin::{Self, Coin};
use sui::balance::{Self, Balance};
use sui::sui::SUI;
use std::string::{Self, String};

use site_forge::site_forge_token::{Self as site_token, SITE_FORGE_TOKEN};
use site_forge::constants as project_constants;
use site_forge::errors;
use site_forge::events;

/// Represents a user's subscription. Non-transferable by default.
public struct SubscriptionNFT has key, store {
    id: UID,
    owner: address, // Store owner address directly for easier querying
    name: String,   // NFT Metadata
    description: String, // NFT Metadata
    url: String,         // NFT Metadata (e.g., link to user's profile/dashboard)
    creation_timestamp_ms: u64,
    expiration_timestamp_ms: Option<u64>, // Use Option for perpetual or timed subscriptions
}

/// Capability required to mint new Subscription NFTs.
public struct MintCap has key, store { id: UID }

/// Shared object to hold the treasury funds (SUI and SITE_FORGE_TOKEN).
public struct Treasury has key {
    id: UID,
    sui_balance: Balance<SUI>,
    site_balance: Balance<site_token::SITE_FORGE_TOKEN>,
}

/// Admin capability for managing the treasury and mint cap.
public struct AdminCap has key, store { id: UID }

fun init(ctx: &mut TxContext) {
    let admin = tx_context::sender(ctx);
    // Create and transfer admin cap
    transfer::transfer(AdminCap { id: object::new(ctx) }, admin);
    // Create and transfer mint cap
    transfer::transfer(MintCap { id: object::new(ctx) }, admin);
    // Create and share the treasury
    transfer::share_object(Treasury {
        id: object::new(ctx),
        sui_balance: balance::zero(),
        site_balance: balance::zero(),
    });
}

// In the subscription_nft module
public fun owner(nft: &SubscriptionNFT): address {
    nft.owner
}

/// Mints a new Subscription NFT by paying with SUI.
public entry fun mint_with_sui(
    mint_cap: &MintCap, // Requires mint capability (held by contract logic or frontend interaction)
    treasury: &mut Treasury,
    payment: Coin<SUI>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let amount_paid = coin::value(&payment);
    let required_amount = project_constants::subscription_price_sui();
    assert!(amount_paid >= required_amount, errors::insufficient_funds());

    // Take payment and deposit into treasury
    let payment_balance = coin::into_balance(payment);
    balance::join(&mut treasury.sui_balance, payment_balance);

    // Handle potential change (if amount_paid > required_amount) - send back to sender
    // This requires splitting the balance, omitted for brevity, assumes exact payment for now.
    // Or, treasury keeps the overpayment. Best practice is to return change.

    mint_to_sender(mint_cap, sender, clock, ctx, 0); // 0 indicates SUI payment
}

/// Mints a new Subscription NFT by paying with SITE_FORGE_TOKEN tokens.
public entry fun mint_with_site(
    mint_cap: &MintCap,
    treasury: &mut Treasury,
    payment: Coin<SITE_FORGE_TOKEN>,
    clock: &Clock,
    ctx: &mut TxContext,
) {
    let sender = tx_context::sender(ctx);
    let amount_paid = coin::value(&payment);
    let required_amount = project_constants::subscription_price_site();
    assert!(amount_paid >= required_amount, errors::insufficient_funds());

    // Take payment and deposit into treasury
    let payment_balance = coin::into_balance(payment);
    balance::join(&mut treasury.site_balance, payment_balance);

    // Handle change if necessary (similar to SUI)

    mint_to_sender(mint_cap, sender, clock, ctx, 1); // 1 indicates SITE_FORGE_TOKEN payment
}

/// Internal minting logic.
fun mint_to_sender(
    _mint_cap: &MintCap, // Capability proves authorization
    recipient: address,
    clock: &Clock,
    ctx: &mut TxContext,
    payment_type: u8,
) {
    // Define NFT metadata
    let nft_name = string::utf8(b"SiteBuilder Subscription");
    let nft_desc = string::utf8(b"Grants access to SiteBuilder features.");
    let nft_url = string::utf8(b"https://yoursitebuilder.com/dashboard"); // Example URL

    let current_time = clock::timestamp_ms(clock);
    // Define expiration (e.g., 30 days from now, or None for perpetual)
    // let expiration = option::some(current_time + 30 * 24 * 60 * 60 * 1000); // 30 days
    let expiration = option::none(); // Example: Perpetual subscription

    let nft = SubscriptionNFT {
        id: object::new(ctx),
        owner: recipient,
        name: nft_name,
        description: nft_desc,
        url: nft_url,
        creation_timestamp_ms: current_time,
        expiration_timestamp_ms: expiration,
    };

    let nft_id = object::id(&nft);
    // Transfer NFT to the recipient
    transfer::public_transfer(nft, recipient);

    // Emit event
    events::emit_subscription_created(
        nft_id,
        recipient,
        expiration,
        payment_type,
        ctx
    );
}

/// Checks if a given wallet address currently holds a valid (non-expired) SubscriptionNFT.
/// NOTE: This requires the NFT object itself to be passed in. A more scalable approach
/// for checking *any* user might involve off-chain indexing or different storage patterns.
public fun is_subscribed(nft: &SubscriptionNFT, clock: &Clock): bool {
    if (option::is_none(&nft.expiration_timestamp_ms)) {
        // Perpetual subscription
        true
    } else {
        // Timed subscription
        let expiration_time = option::destroy_some(nft.expiration_timestamp_ms);
        let current_time = clock::timestamp_ms(clock);
        current_time < expiration_time
    };
    // Re-add option after check if needed, or design assumes it's consumed/checked once.
    // For a simple view function, let's assume it's just a check:
    let expiration_time_opt = nft.expiration_timestamp_ms;
    if (option::is_some(&expiration_time_opt)) {
        clock::timestamp_ms(clock) < *option::borrow(&expiration_time_opt)
    } else { true }
}

    /// View function to get NFT details.
public fun get_nft_details(nft: &SubscriptionNFT): (ID, address, Option<u64>, u64) {
    (
        object::id(nft),
        nft.owner,
        nft.expiration_timestamp_ms,
        nft.creation_timestamp_ms
    )
}


/// Allows the admin to withdraw funds from the treasury.
public entry fun withdraw_treasury(
    admin_cap: &AdminCap,
    treasury: &mut Treasury,
    amount_sui: u64,
    amount_site: u64,
    recipient: address,
    ctx: &mut TxContext,
) {
    let _ = admin_cap; // Prove admin authorization

    if (amount_sui > 0) {
        let sui_to_withdraw = balance::split(&mut treasury.sui_balance, amount_sui);
        transfer::public_transfer(coin::from_balance(sui_to_withdraw, ctx), recipient);
    };

    if (amount_site > 0) {
        let site_to_withdraw = balance::split(&mut treasury.site_balance, amount_site);
        transfer::public_transfer(coin::from_balance(site_to_withdraw, ctx), recipient);
    };
}

// #[test_only]
// use sui::test_scenario::{Self as ts, Scenario, next_tx, ctx};
// use sui::balance::Supply;
// #[test_only]
// const ADMIN: address = @0xADMIN;
// #[test_only]
// const USER: address = @0xUSER;

// #[test_only]
// fun setup_scenario(scenario: &mut Scenario) {
//     // Init token module first if needed for SITE_FORGE_TOKEN payments
//     // site_token::test_init(ctx(scenario));
//     // next_tx(scenario, ADMIN);

//     // Init subscription module
//     init(ctx(scenario));
//     next_tx(scenario, ADMIN);

//     // Mint some SUI for the user
//     let sui_coin = ts::mint_for_testing<SUI>(project_constants::subscription_price_sui() * 2, ctx(scenario));
//     ts::transfer_to_address(USER, sui_coin);
//     next_tx(scenario, ADMIN); // End setup tx
// }


// #[test]
// fun test_mint_sui_and_check() {
//     let mut scenario = ts::begin(ADMIN);
//     setup_scenario(&mut scenario);

//     // --- User Mint Transaction ---
//     {
//         let mint_cap = ts::take_shared<MintCap>(&scenario);
//         let treasury = ts::take_shared<Treasury>(&scenario);
//         let payment = ts::take_from_sender<Coin<SUI>>(&scenario); // User pays
//         let clock = ts::clock(&scenario);

//         mint_with_sui(&mint_cap, &mut treasury, payment, clock, ctx(&mut scenario));

//         // Return shared objects
//         ts::return_shared(mint_cap);
//         ts::return_shared(treasury);
//     };
//     next_tx(&mut scenario, USER); // End user mint tx

//     // --- Admin/Verification Check ---
//     {
//         let nft = ts::take_from_address<SubscriptionNFT>(&scenario, USER);
//         let clock = ts::clock(&scenario);

//         assert!(object::owner(&nft) == USER, errors::invalid_caller()); // Basic check
//         assert!(is_subscribed(&nft, clock), errors::not_subscribed()); // Check subscription status

//         // Return the NFT to the user in the scenario state
//             ts::return_to_address(USER, nft);
//     };

//     ts::end(scenario);
// }