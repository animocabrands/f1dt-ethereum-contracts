const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {BN, toAscii} = require('web3-utils');
const { ZeroAddress, Zero } = require('@animoca/ethereum-contracts-core_library/src/constants');

const F1DTCrateKey = contract.fromArtifact('F1DTCrateKey');
const TOKEN_DECIMALS = '18';
const TOKEN_AMOUNT_TO_BURN = '1000';
const [deployer, payout, owner, operator] = accounts;

const TOKENS = {
    F1DT_CCK: {symbol: 'F1DT.CCK', name: getTokenDescription('Common'), totalSupply: '6700'},
    F1DT_RCK: {symbol: 'F1DT.RCK', name: getTokenDescription('Rare'), totalSupply: '5350'},
    F1DT_ECK: {symbol: 'F1DT.ECK', name: getTokenDescription('Epic'), totalSupply: '4050'},
    F1DT_LCK: {symbol: 'F1DT.LCK', name: getTokenDescription('Legendary'), totalSupply: '1320'},
};

async function getInstance(token, account, totalSupply, config) {
    config = config || {from: deployer};

    return await F1DTCrateKey.new(
        token.symbol,
        token.name,
        (account || config.from),
        (totalSupply || token.totalSupply), 
        config
    ); 
};

function getTokenDescription(type) {
    return `F1&#174; Delta Time ${type} Crate Key`;
}

function tokenConstructorChecks(token) {
    it('should revert with invalid symbol', async function() {
        await expectRevert(
            getInstance({...token, symbol: ''}), 
            'F1DTCrateKey: invalid symbol'
        );
    });
    it('should revert with invalid name', async function() {
        await expectRevert(
            getInstance({...token, name: ''}), 
            'F1DTCrateKey: invalid name'
        );
    });
    it('should revert with invalid holder', async function() {
        await expectRevert(
            getInstance(token, ZeroAddress), 
            'F1DTCrateKey: invalid holder'
        );
    });
    it('should revert with a zero supply', async function() {
        await expectRevert(
            getInstance(token, deployer, Zero), 
            'F1DTCrateKey: invalid total supply'
        );
    });
    it('should deploy with correct parameters', async function() {
        await getInstance(token);
    });
}

//FIX: * REVIEW -> Invalid contract instance
// function tokenSpecificationChecks(contractInstance, token) {
//     it('should return the correct name', async function() {
//         const tokenName = await contractInstance.name();
//         tokenName.should.be.equal(token.name);
//     });
//     it('should return the correct symbol', async function() {
//         const tokenSymbol = await contractInstance.symbol();
//         tokenSymbol.should.be.equal(token.symbol);
//     });
//     it('should return the correct decimals', async function() {
//         const tokenDecimals = await contractInstance.decimals();
//         tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
//     });
//     it('should return the correct supply', async function() {
//         const tokenSupply = await contractInstance.totalSupply();
//         tokenSupply.should.be.bignumber.equal(token.totalSupply);
//     });
// };

describe('F1DT Crate Key', function() {
    describe('constructor(symbol, name, holder, totalSupply', function() {
        describe('F1DT.CCK', function() {
            tokenConstructorChecks(TOKENS.F1DT_CCK);
        });
        describe('F1DT.RCK', function() {
            tokenConstructorChecks(TOKENS.F1DT_RCK);
        });
        describe('F1DT.ECK', function() {
            tokenConstructorChecks(TOKENS.F1DT_ECK);
        });
        describe('F1DT.LCK', function() {
            tokenConstructorChecks(TOKENS.F1DT_LCK);
        });
    });

    describe('Token', function() {
        beforeEach(async function() {
            this.f1dtCck = await getInstance(TOKENS.F1DT_CCK);
            this.f1dtEck = await getInstance(TOKENS.F1DT_ECK);
            this.f1dtLck = await getInstance(TOKENS.F1DT_LCK);
            this.f1dtRck = await getInstance(TOKENS.F1DT_RCK);
        });
        describe('Specification', function() {
            describe('F1DT.CCK', function() {
                it('should return the correct name', async function() {
                    const tokenName = await this.f1dtCck.name();
                    tokenName.should.be.equal(TOKENS.F1DT_CCK.name);
                });
                it('should return the correct symbol', async function() {
                    const tokenSymbol = await this.f1dtCck.symbol();
                    tokenSymbol.should.be.equal(TOKENS.F1DT_CCK.symbol);
                });
                it('should return the correct decimals', async function() {
                    const tokenDecimals = await this.f1dtCck.decimals();
                    tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
                });
                it('should return the correct supply', async function() {
                    const tokenSupply = await this.f1dtCck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_CCK.totalSupply);
                });
            });
            describe('F1DT.RCK', function() {
                it('should return the correct name', async function() {
                    const tokenName = await this.f1dtRck.name();
                    tokenName.should.be.equal(TOKENS.F1DT_RCK.name);
                });
                it('should return the correct symbol', async function() {
                    const tokenSymbol = await this.f1dtRck.symbol();
                    tokenSymbol.should.be.equal(TOKENS.F1DT_RCK.symbol);
                });
                it('should return the correct decimals', async function() {
                    const tokenDecimals = await this.f1dtRck.decimals();
                    tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
                });
                it('should return the correct supply', async function() {
                    const tokenSupply = await this.f1dtRck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_RCK.totalSupply);
                });
            });
            describe('F1DT.ECK', function() {
                it('should return the correct name', async function() {
                    const tokenName = await this.f1dtEck.name();
                    tokenName.should.be.equal(TOKENS.F1DT_ECK.name);
                });
                it('should return the correct symbol', async function() {
                    const tokenSymbol = await this.f1dtEck.symbol();
                    tokenSymbol.should.be.equal(TOKENS.F1DT_ECK.symbol);
                });
                it('should return the correct decimals', async function() {
                    const tokenDecimals = await this.f1dtEck.decimals();
                    tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
                });
                it('should return the correct supply', async function() {
                    const tokenSupply = await this.f1dtEck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_ECK.totalSupply);
                });
            });
            describe('F1DT.LCK', function() {
                it('should return the correct name', async function() {
                    const tokenName = await this.f1dtLck.name();
                    tokenName.should.be.equal(TOKENS.F1DT_LCK.name);
                });
                it('should return the correct symbol', async function() {
                    const tokenSymbol = await this.f1dtLck.symbol();
                    tokenSymbol.should.be.equal(TOKENS.F1DT_LCK.symbol);
                });
                it('should return the correct decimals', async function() {
                    const tokenDecimals = await this.f1dtLck.decimals();
                    tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
                });
                it('should return the correct supply', async function() {
                    const tokenSupply = await this.f1dtLck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_LCK.totalSupply);
                });
            });
            
        });
        describe('Burn Operation', function() {
            describe('F1DT.CCK', function() { 
                it('should fail due to invalid onwer', async function() {
                    await expectRevert(
                        this.f1dtCck.burn(TOKENS.F1DT_CCK.totalSupply, {from: operator}),
                        'Ownable: caller is not the owner'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtCck.burn('100000', {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtCck.burn(TOKEN_AMOUNT_TO_BURN, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKEN_AMOUNT_TO_BURN
                    })
                });
            });

            describe('F1DT.RCK', function() { 
                it('should fail due to invalid onwer', async function() {
                    await expectRevert(
                        this.f1dtRck.burn(TOKENS.F1DT_RCK.totalSupply, {from: operator}),
                        'Ownable: caller is not the owner'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtRck.burn('100000', {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtRck.burn(TOKEN_AMOUNT_TO_BURN, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKEN_AMOUNT_TO_BURN
                    })
                });
            });
            describe('F1DT.ECK', function() { 
                it('should fail due to invalid onwer', async function() {
                    await expectRevert(
                        this.f1dtEck.burn(TOKENS.F1DT_ECK.totalSupply, {from: operator}),
                        'Ownable: caller is not the owner'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtEck.burn('100000', {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtEck.burn(TOKEN_AMOUNT_TO_BURN, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKEN_AMOUNT_TO_BURN
                    })
                });
            });
            describe('F1DT.LCK', function() { 
                it('should fail due to invalid onwer', async function() {
                    await expectRevert(
                        this.f1dtLck.burn(TOKENS.F1DT_LCK.totalSupply, {from: operator}),
                        'Ownable: caller is not the owner'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtLck.burn('100000', {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtLck.burn(TOKEN_AMOUNT_TO_BURN, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKEN_AMOUNT_TO_BURN
                    })
                });
            });
         });
    });
});
