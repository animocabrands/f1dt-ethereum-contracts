const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {BN, toAscii} = require('web3-utils');
const { ZeroAddress, Zero } = require('@animoca/ethereum-contracts-core_library/src/constants');
const ContractDeployer = require('../../helpers/ContractDeployer')
const { toWei } = require('web3-utils');
const [deployer, payout, owner, operator] = accounts;

const F1DTCrateKey = contract.fromArtifact('F1DTCrateKey');
const TOKEN_HOLDER = deployer;

const TOKENS = ContractDeployer.TOKENS;
const TOKEN_DECIMALS = ContractDeployer.TOKEN_DECIMALS;

async function getInstance(token, account, totalSupply, config) {
    config = config || {from: deployer};

    return await F1DTCrateKey.new(
        token.symbol,
        token.name,
        token.uri,
        (account || TOKEN_HOLDER),
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
            'F1DTCrateKey: invalid initial supply'
        );
    });
    it('should deploy with correct parameters', async function() {
        await getInstance(token);
    });
}

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
            this.f1dtRck = await getInstance(TOKENS.F1DT_RCK);
            this.f1dtEck = await getInstance(TOKENS.F1DT_ECK);
            this.f1dtLck = await getInstance(TOKENS.F1DT_LCK);            
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
                it('should return the correct total supply', async function() {
                    const tokenSupply = await this.f1dtCck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_CCK.totalSupply);
                });
                it('should return the correct holder', async function() {
                    const tokenHolder = await this.f1dtCck.holder();
                    tokenHolder.should.be.equal(TOKEN_HOLDER);
                });
                it('should return the tokenURI', async function() {
                    const tokenURI = await this.f1dtCck.tokenURI();
                    tokenURI.should.be.equal(TOKENS.F1DT_CCK.uri);
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
                it('should return the correct total supply', async function() {
                    const tokenSupply = await this.f1dtRck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_RCK.totalSupply);
                });
                it('should return the correct holder', async function() {
                    const tokenHolder = await this.f1dtRck.holder();
                    tokenHolder.should.be.equal(TOKEN_HOLDER);
                });
                it('should return the tokenURI', async function() {
                    const tokenURI = await this.f1dtRck.tokenURI();
                    tokenURI.should.be.equal(TOKENS.F1DT_RCK.uri);
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
                it('should return the correct total supply', async function() {
                    const tokenSupply = await this.f1dtEck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_ECK.totalSupply);
                });
                it('should return the correct holder', async function() {
                    const tokenHolder = await this.f1dtEck.holder();
                    tokenHolder.should.be.equal(TOKEN_HOLDER);
                });
                it('should return the tokenURI', async function() {
                    const tokenURI = await this.f1dtEck.tokenURI();
                    tokenURI.should.be.equal(TOKENS.F1DT_ECK.uri);
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
                it('should return the correct total supply', async function() {
                    const tokenSupply = await this.f1dtLck.totalSupply();
                    tokenSupply.should.be.bignumber.equal(TOKENS.F1DT_LCK.totalSupply);
                });
                it('should return the correct holder', async function() {
                    const tokenHolder = await this.f1dtLck.holder();
                    tokenHolder.should.be.equal(TOKEN_HOLDER);
                });
                it('should return the tokenURI', async function() {
                    const tokenURI = await this.f1dtLck.tokenURI();
                    tokenURI.should.be.equal(TOKENS.F1DT_LCK.uri);
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
                it('should fail due to zero amount', async function() {
                    await expectRevert(
                        this.f1dtCck.burn(Zero, {from: deployer}),
                        'F1DTCrateKey: invalid amount'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtCck.burn(toWei('100000'), {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtCck.burn(TOKENS.F1DT_CCK.totalSupply, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKENS.F1DT_CCK.totalSupply
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
                it('should fail due to zero amount', async function() {
                    await expectRevert(
                        this.f1dtRck.burn(Zero, {from: deployer}),
                        'F1DTCrateKey: invalid amount'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtRck.burn(toWei('100000'), {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtRck.burn(TOKENS.F1DT_RCK.totalSupply, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKENS.F1DT_RCK.totalSupply
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
                it('should fail due to zero amount', async function() {
                    await expectRevert(
                        this.f1dtEck.burn(Zero, {from: deployer}),
                        'F1DTCrateKey: invalid amount'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtEck.burn(toWei('100000'), {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtEck.burn(TOKENS.F1DT_ECK.totalSupply, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKENS.F1DT_ECK.totalSupply
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
                it('should fail due to zero amount', async function() {
                    await expectRevert(
                        this.f1dtLck.burn(Zero, {from: deployer}),
                        'F1DTCrateKey: invalid amount'
                    );
                });
                it('should fail due to invalid amount', async function() {
                    await expectRevert(
                        this.f1dtLck.burn(toWei('100000'), {from: deployer}),
                        'ERC20: burn amount exceeds balance'
                    );
                });
                it('should burn the tokens', async function() {
                    const receipt = await this.f1dtLck.burn(TOKENS.F1DT_LCK.totalSupply, {from: deployer});
                    expectEvent(receipt, 'Transfer', {
                        _from: deployer,
                        _to: ZeroAddress,
                        _value: TOKENS.F1DT_LCK.totalSupply
                    })
                });
            });
         });
    });
});
