/// Module for the SITE utility token. Uses the Managed Token standard.
module site_forge::site_forge_token;

use sui::coin::{Self, TreasuryCap};
use site_forge::constants as project_constants;

public struct SITE_FORGE_TOKEN has drop {}

/// Capability granting admin rights over the token (e.g., modifying metadata).
public struct AdminCap has key, store { id: UID }

fun init(witness: SITE_FORGE_TOKEN, ctx: &mut TxContext) {
		let (treasury, coin_metadata) = coin::create_currency(
            witness,
project_constants::site_token_decimals(),
        project_constants::site_token_symbol(),
        project_constants::site_token_name(),
            b"",
            option::none(),
            ctx,
		);
        // Transfer TreasuryCap and AdminCap to the deployer/admin
        let admin_addr = tx_context::sender(ctx);
        transfer::public_transfer(treasury, admin_addr);
        transfer::transfer(AdminCap { id: object::new(ctx) }, admin_addr);
        // Make CoinMetadata shared so wallets can display token info
        transfer::public_share_object(coin_metadata);
}

public fun mint(
		treasury_cap: &mut TreasuryCap<SITE_FORGE_TOKEN>,
		amount: u64,
		recipient: address,
		ctx: &mut TxContext,
) {
		let coin = coin::mint(treasury_cap, amount, ctx);
		transfer::public_transfer(coin, recipient)
}