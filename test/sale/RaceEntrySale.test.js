const { accounts, contract, web3 } = require('@openzeppelin/test-environment');
const { ether, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const { ZeroAddress, Zero, One, Two } = require('@animoca/ethereum-contracts-core_library').constants;

const EthAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const Sale = contract.fromArtifact('RaceEntrySaleMock');

const price = {
    eth: ether('0.01'),
    erc20: Zero
};

const sku = web3.utils.asciiToHex('sku');
const gameSessionId = web3.utils.asciiToHex('gameSessionId');

const [
    payout,
    owner,
    operator,
    purchaser
] = accounts;

describe('RaceEntrySale', function () {

    beforeEach(async function () {
        this.contract = await Sale.new(payout, ZeroAddress, { from: owner });
        await this.contract.setPrice(sku, price.eth, price.erc20, { from: owner });
    });

    context('purchase quantity is 1', function () {
        it('should purchase successfully', async function () {
            const receipt = await this.contract.purchaseFor(
                purchaser,
                sku,
                One,
                EthAddress,
                gameSessionId,
                {
                    from: operator,
                    value: price.eth
                });

            expectEvent.inTransaction(
                receipt.tx,
                this.contract,
                'PurchasedMock',
                {
                    purchaser: purchaser,
                    operator: operator,
                    sku: web3.utils.padRight(sku, 64),
                    paymentToken: EthAddress,
                    quantity: One,
                    totalPrice: price.eth,
                    unitPrice: price.eth,
                    gameSessionId: web3.utils.padRight(gameSessionId, 64)
                });
        });
    });

    context('purchase quantity is not 1', function () {
        it('should revert', async function () {
            await expectRevert(
                this.contract.purchaseFor(
                    purchaser,
                    sku,
                    Two,
                    EthAddress,
                    gameSessionId,
                    {
                        from: operator,
                        value: price.eth
                    }),
                'RaceEntrySale: Quantity must be 1');
        });
    });

});
