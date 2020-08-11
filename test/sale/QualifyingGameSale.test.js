const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {ZeroAddress, Zero, One, Two} = require('@animoca/ethereum-contracts-core_library').constants;
const {asciiToHex, padLeft, toBN, toHex} = web3.utils;

const EthAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const Sale = contract.fromArtifact('QualifyingGameSale');

const price = ether('0.01');
const sku = stringToBytes32('sku');
const gameSessionId = toHex('gameSessionId');

const [payout, owner, operator, purchaser] = accounts;

function stringToBytes32(value) {
    return padLeft(asciiToHex(value.slice(0, 32), 64));
}

function bnToBytes32(value) {
    return padLeft(toHex(value), 64);
}

describe('QualifyingGameSale', function () {
    beforeEach(async function () {
        this.contract = await Sale.new(payout, ZeroAddress, {from: owner});
        await this.contract.addInventorySkus([sku], {from: owner});
        await this.contract.addSupportedPaymentTokens([EthAddress], {from: owner});
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
                gameSessionId,
                {
                    from: operator,
                    value: price,
                });

            const totalPrice = toBN(price).mul(quantity);

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
                    userData: gameSessionId,
                    purchaseData: [ bnToBytes32(totalPrice) ]
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
                    gameSessionId,
                    {
                        from: operator,
                        value: price,
                    }),
                'QualifyingGameSale: Quantity must be 1');
        });
    });
});
