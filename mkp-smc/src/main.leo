
program nft_market_place_atom_v2.aleo {
    // On-chain storage of an `account` map, with `address` as the key,
    // and `u64` as the value.
    mapping account: address => u64;
    mapping tokenExists: u128 => bool;
    mapping publicNftData: u128 => NFT;
    mapping publicNftOwners: u128 => address;

    record token {
        // The token owner.
        owner: address,
        // The token amount.
        amount: u64,
    }

    struct NFT {
        uri: String64
    }

    struct String64 {
        part0: u128,
        part1: u128,
        part2: u128,
        part3: u128,
        part4: u128,
        part5: u128
    }

    transition mint_nft_public(public token_id: u128, public uri: String64) {
        return then finalize(self.caller, token_id, uri);
    }

    finalize mint_nft_public(public receiver: address, public token_id: u128, public uri: String64) {
        let Nft: NFT = NFT {
            uri: uri
        };
        let token_exists: bool = tokenExists.contains(token_id);
        assert(token_exists.not());

        // decrease balance token
        let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, current_amount - 10u64);

        Mapping::set(publicNftData, token_id, Nft);
        Mapping::set(publicNftOwners, token_id, receiver);

        tokenExists.set(token_id, true);
    }

    /* Mint */

    // The function `mint_public` issues the specified token amount for the token receiver publicly on the network.
    transition mint_token_public(public receiver: address, public amount: u64) {
        // Mint the tokens publicly by invoking the computation on-chain.
        // let owner_program: address = aleo1hxy9p4dw5g8prtw72expa9x77dyx6jzqt6809er6l7rfrtddacrsh8r4sk;
        // credits.leo/transfer_public(
        //     owner_program,
        //     amount
        // );
        return then finalize(receiver, amount);
    }

    finalize mint_token_public(public receiver: address, public amount: u64) {
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `mint_public` is reverted.
        let current_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, current_amount + amount);
    }

    // The function `mint_private` initializes a new record with the specified amount of tokens for the receiver.
    transition mint_token_private(receiver: address, amount: u64) -> token {
        return token {
            owner: receiver,
            amount: amount,
        };
    }

    /* Burn */
    transition burn_token_public(public amount: u64) {
        return then finalize(self.caller ,amount);
    }

    finalize burn_token_public(public caller: address, public amount: u64) {
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `mint_public` is reverted.
        let current_amount: u64 = Mapping::get_or_use(account, caller, 0u64);
        Mapping::set(account, caller, current_amount - amount);
    }

    /* Transfer */
    transition transfer_token_public(public receiver: address, public amount: u64) {
        // Transfer the tokens publicly, by invoking the computation on-chain.
        return then finalize(self.caller, receiver, amount);
    }

    finalize transfer_token_public(public sender: address, public receiver: address, public amount: u64) {
        // Decrements `account[sender]` by `amount`.
        // If `account[sender]` does not exist, it will be created.
        // If `account[sender] - amount` underflows, `transfer_public` is reverted.
        let sender_amount: u64 = Mapping::get_or_use(account, sender, 0u64);
        Mapping::set(account, sender, sender_amount - amount);
        // Increments `account[receiver]` by `amount`.
        // If `account[receiver]` does not exist, it will be created.
        // If `account[receiver] + amount` overflows, `transfer_public` is reverted.
        let receiver_amount: u64 = Mapping::get_or_use(account, receiver, 0u64);
        Mapping::set(account, receiver, receiver_amount + amount);
    }

    // The function `transfer_private` sends the specified token amount to the token receiver from the specified token record.
    transition transfer_token_private(sender: token, receiver: address, amount: u64) -> (token, token) {
        // Checks the given token record has sufficient balance.
        // This `sub` operation is safe, and the proof will fail if an overflow occurs.
        // `difference` holds the change amount to be returned to sender.
        let difference: u64 = sender.amount - amount;

        // Produce a token record with the change amount for the sender.
        let remaining: token = token {
            owner: sender.owner,
            amount: difference,
        };

        // Produce a token record for the specified receiver.
        let transferred: token = token {
            owner: receiver,
            amount: amount,
        };

        // Output the sender's change record and the receiver's record.
        return (remaining, transferred);
    }

}

