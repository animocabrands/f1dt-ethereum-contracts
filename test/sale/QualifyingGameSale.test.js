const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {ZeroAddress, Zero, One, Two} = require('@animoca/ethereum-contracts-core_library').constants;

const EthAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const Sale = contract.fromArtifact('QualifyingGameSale');

const price = ether('0.01');
const sku = web3.utils.asciiToHex('sku');
const gameSessionId = web3.utils.asciiToHex('gameSessionId');

const [payout, owner, operator, purchaser] = accounts;

describe('QualifyingGameSale', function () {
    beforeEach(async function () {
        this.contract = await Sale.new(payout, ZeroAddress, {from: owner});
        await this.contract.addInventorySkus([sku], {from: owner});
        await this.contract.addSupportedPayoutTokens([EthAddress], {from: owner});
        await this.contract.setSkuTokenPrices(sku, [EthAddress], [price], {from: owner});
        await this.contract.start({from: owner});
    });

    context('purchase quantity is 1', function () {
        it('should purchase successfully', async function () {
            const quantity = One;
            const paymentToken = EthAddress;

            const receipt = await this.contract.purchaseFor(
                purchaser,
                paymentToken,
                sku,
                quantity,
                [gameSessionId],
                {
                    from: operator,
                    value: price,
                });

            expectEvent.inTransaction(
                receipt.tx,
                this.contract,
                'Purchased',
                {
                    purchaser: purchaser,
                    operator: operator,
                    sku: web3.utils.padRight(sku, 64),
                    paymentToken: paymentToken,
                    quantity: quantity,
                    extData: ['0x' + price.toString(16, 64), web3.utils.padRight(gameSessionId, 64)],
                });
        });
    });

    context('purchase quantity is not 1', function () {
        it('should revert', async function () {
            await expectRevert(
                this.contract.purchaseFor(
                    purchaser,
                    EthAddress,
                    sku,
                    Two,
                    [gameSessionId],
                    {
                        from: operator,
                        value: price,
                    }),
                'QualifyingGameSale: Quantity must be 1');
        });
    });
});
