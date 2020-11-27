const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {BN, toAscii} = require('web3-utils');
const { ZeroAddress, Zero } = require('@animoca/ethereum-contracts-core_library/src/constants');

const F1DTCrateKey = contract.fromArtifact('F1DTCrateKey');
const TOKEN_TOTAL_SUPPLY = '10000000000';
const TOKEN_DECIMALS = '18';

const [deployer, payout, owner, operator] = accounts;

const TOKENS = {
    F1DT_CCK: {symbol: 'F1DT.CCK', name: 'F1&#174; Delta Time Common Crate Key'},
    F1DT_ECK: {symbol: 'F1DT.ECK', name: 'F1&#174; Delta Time Epic Crate Key'},
    F1DT_LCK: {symbol: 'F1DT.LCK', name: 'F1&#174; Delta Time Legendary Crate Key'},
    F1DT_RCK: {symbol: 'F1DT.RCK', name: 'F1&#174; Delta Time Rare Crate Key'},
};

async function getInstance(token, account, totalSupply, config) {
    config = config || {from: deployer};

    return await F1DTCrateKey.new(
        token.symbol,
        token.name,
        (account || config.from),
        (totalSupply || TOKEN_TOTAL_SUPPLY), 
        config
    ); 
};

describe('F1DT Crate Key', function() {
    describe('constructor(symbol, name, holder, totalSupply', function() {
        it('should revert with invalid symbol', async function() {
            await expectRevert(
                getInstance({symbol: '', name: 'F1&#174; Delta Time Common Crate Key'}), 
                'F1DTCrateKey: invalid symbol'
            );
        });
        it('should revert with invalid name', async function() {
            await expectRevert(
                getInstance({symbol: 'F1DT.CCK', name: ''}), 
                'F1DTCrateKey: invalid name'
            );
        });
        it('should revert with invalid holder', async function() {
            await expectRevert(
                getInstance(TOKENS.F1DT_CCK, ZeroAddress), 
                'F1DTCrateKey: invalid holder'
            );
        });
        it('should revert with a zero supply', async function() {
            await expectRevert(
                getInstance(TOKENS.F1DT_CCK, deployer, Zero), 
                'F1DTCrateKey: invalid total supply'
            );
        });
        it('should deploy with correct parameters', async function() {
            await getInstance(TOKENS.F1DT_CCK);
        });
    });

    // describe('Token', function() {
    //     beforeEach(async function() {
    //         this.f1dtRck = await F1DT_RCK.new(deployer, TOKEN_TOTAL_SUPPLY, {from: deployer}); 
    //     });
    //     describe('Token Specification', function() {
    //         it('should return the correct name', async function() {
    //             const tokenName = await this.f1dtRck.name();
    //             tokenName.should.be.equal("F1&#174; Delta Time Rare Crate Key");
    //         });
    //         it('should return the correct symbol', async function() {
    //             const tokenSymbol = await this.f1dtRck.symbol();
    //             tokenSymbol.should.be.equal("F1DT.RCK");
    //         });
    //         it('should return the correct decimals', async function() {
    //             const tokenDecimals = await this.f1dtRck.decimals();
    //             tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
    //         });
    //     });

    //     describe('Token Total Supply', function() {
    //         it('should return the correct total supply', async function() {
    //             const totalSupply = await this.f1dtRck.totalSupply();
    //             totalSupply.should.be.bignumber.equal(TOKEN_TOTAL_SUPPLY);
    //         });
    //     });
    // });
});
