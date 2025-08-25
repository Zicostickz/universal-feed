import { Clarinet, Tx, Chain, Account, types } from 'https://deno.land/x/clarinet@v1.5.4/index.ts';
import { assertEquals } from 'https://deno.land/std@0.170.0/testing/asserts.ts';

Clarinet.test({
    name: "Ensure that creators can create a new content feed",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('universal-feed', 'create-feed', [
                types.ascii('Tech Updates'),
                types.utf8('Latest technology insights'),
                types.ascii('technology')
            ], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        assertEquals(block.height, 2);
        block.receipts[0].result.expectOk().expectUint(1);
    }
});

Clarinet.test({
    name: "Validate feed creation with invalid inputs",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const block = chain.mineBlock([
            Tx.contractCall('universal-feed', 'create-feed', [
                types.ascii(''),  // Empty title
                types.utf8('Some description'),
                types.ascii('technology')
            ], deployer.address)
        ]);

        assertEquals(block.receipts.length, 1);
        block.receipts[0].result.expectErr().expectUint(103);  // err-invalid-input
    }
});

Clarinet.test({
    name: "Ensure users can subscribe to a feed",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;
        const user = accounts.get('wallet_1')!;

        // First create a feed
        const createBlock = chain.mineBlock([
            Tx.contractCall('universal-feed', 'create-feed', [
                types.ascii('Science Feed'),
                types.utf8('Scientific discoveries and research'),
                types.ascii('science')
            ], deployer.address)
        ]);

        // Then subscribe to the feed
        const subscribeBlock = chain.mineBlock([
            Tx.contractCall('universal-feed', 'subscribe', [
                types.uint(1),  // Feed ID
                types.ascii('free')  // Tier
            ], user.address)
        ]);

        assertEquals(subscribeBlock.receipts.length, 1);
        subscribeBlock.receipts[0].result.expectOk().expectBool(true);
    }
});

Clarinet.test({
    name: "Validate content entry creation",
    async fn(chain: Chain, accounts: Map<string, Account>) {
        const deployer = accounts.get('deployer')!;

        // First create a feed
        const createBlock = chain.mineBlock([
            Tx.contractCall('universal-feed', 'create-feed', [
                types.ascii('Art Updates'),
                types.utf8('Contemporary art insights'),
                types.ascii('art')
            ], deployer.address)
        ]);

        // Add content entry
        const entryBlock = chain.mineBlock([
            Tx.contractCall('universal-feed', 'add-entry', [
                types.uint(1),  // Feed ID
                types.utf8('Exciting new exhibition opening next month!')
            ], deployer.address)
        ]);

        assertEquals(entryBlock.receipts.length, 1);
        entryBlock.receipts[0].result.expectOk().expectUint(1);
    }
});