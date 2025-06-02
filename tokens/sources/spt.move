// Copyright (c) Web3 Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module seapad::spt {
    use std::ascii::string;
    use std::option;
    use sui::balance;
    use sui::coin::{Self, TreasuryCap, Coin};
    use sui::transfer::{self, public_freeze_object};
    use sui::tx_context::{TxContext, sender};
    use sui::url;
    use w3libs::payment;

    /// Constants
    const SYMBOL: vector<u8> = b"SPT";
    const NAME: vector<u8> = b"SPT";
    const DESCRIPTION: vector<u8> = b"Seapad launchpad foundation token";
    const DECIMAL: u8 = 9;
    const ICON_URL: vector<u8> = b"https://seapad.s3.ap-southeast-1.amazonaws.com/uploads/TEST/public/media/images/logo_1679906850804.png";

    /// Token definition
    struct SPT has drop {}

    // ===========================
    // Initialization
    // ===========================

    fun init(witness: SPT, ctx: &mut TxContext) {
        let (treasury_cap, metadata) = coin::create_currency<SPT>(
            witness,
            DECIMAL,
            SYMBOL,
            NAME,
            DESCRIPTION,
            option::some(url::new_unsafe(string(ICON_URL))),
            ctx
        );

        public_freeze_object(metadata);
        transfer::public_transfer(treasury_cap, sender(ctx));
    }

    #[test_only]
    public fun init_for_testing(ctx: &mut TxContext) {
        init(SPT {}, ctx);
    }

    // ===========================
    // Minting & Supply Management
    // ===========================

    /// Mint to a specified address
    public entry fun minto(
        treasury_cap: &mut TreasuryCap<SPT>,
        to: address,
        amount: u64,
        ctx: &mut TxContext
    ) {
        coin::mint_and_transfer(treasury_cap, amount, to, ctx);
    }

    /// Mint to sender (increase supply)
    public entry fun increase_supply(
        treasury_cap: &mut TreasuryCap<SPT>,
        value: u64,
        ctx: &mut TxContext
    ) {
        minto(treasury_cap, sender(ctx), value, ctx);
    }

    /// Decrease supply (burn coins and adjust supply)
    public entry fun decrease_supply(
        treasury_cap: &mut TreasuryCap<SPT>,
        coins: vector<Coin<SPT>>,
        value: u64,
        ctx: &mut TxContext
    ) {
        let taken = payment::take_from(coins, value, ctx);
        let total_supply = coin::supply_mut(treasury_cap);
        balance::decrease_supply(total_supply, coin::into_balance(taken));
    }

    // ===========================
    // Burning
    // ===========================

    /// Burn specific amount of tokens from coins
    public entry fun burn(
        treasury_cap: &mut TreasuryCap<SPT>,
        coins: vector<Coin<SPT>>,
        value: u64,
        ctx: &mut TxContext
    ) {
        let taken = payment::take_from(coins, value, ctx);
        coin::burn(treasury_cap, taken);
    }

    /// Critical: Burn mint authority permanently
    public entry fun burn_mint_cap(
        treasury_cap: TreasuryCap<SPT>,
        _ctx: &mut TxContext
    ) {
        public_freeze_object(treasury_cap);
    }
}
