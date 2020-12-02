const { accounts, contract } = require('@openzeppelin/test-environment');
const { toWei } = require('web3-utils');
const { BN, expectRevert, expectEvent } = require('@openzeppelin/test-helpers');
const { ZeroAddress, Zero, One, Two } = require('@animoca/ethereum-contracts-core_library').constants;
const ContractDeployer = require('../helpers/ContractDeployer')

const [holder] = accounts;
const TOKENS = ContractDeployer.TOKENS;
const TOKEN_DECIMALS = ContractDeployer.TOKEN_DECIMALS;

/**
 * 
 * @param {string} deployer 
 * @param {string} operation 
 * @param {*} prepaidContract 
 */
module.exports.createCrateKeyTokens = function(
        tokenHolder = holder, 
        f1dtCckContract,
        f1dtRckContract,
        f1dtEckContract,
        f1dtLckContract) {
    context("deploy tokens phrase", function() {
    
        before(async function() {
            this.f1dtCck = f1dtCckContract || this.f1dtCck;
            this.f1dtRck = f1dtRckContract || this.f1dtRck;
            this.f1dtEck = f1dtEckContract || this.f1dtEck;
            this.f1dtLck = f1dtLckContract || this.f1dtLck;
        });

        describe('F1DT.CCK', function() {
            it('should return the correct name', async function() {
                (await this.f1dtCck.name()).should.be.equal(TOKENS.F1DT_CCK.name);
            });
            it('should return the correct symbol', async function() {
                (await this.f1dtCck.symbol()).should.be.equal(TOKENS.F1DT_CCK.symbol);
            });
            it('should return the correct decimals', async function() {
                (await this.f1dtCck.decimals()).should.be.bignumber.equal(TOKEN_DECIMALS);
            });
            it('should return the correct total supply', async function() {
                (await this.f1dtCck.totalSupply()).should.be.bignumber.equal(TOKENS.F1DT_CCK.totalSupply);
            });
            it('should return the correct holder', async function() {
                (await this.f1dtCck.holder()).should.be.equal(tokenHolder);
            });
        });

        describe('F1DT.RCK', function() {
            it('should return the correct name', async function() {
                (await this.f1dtRck.name()).should.be.equal(TOKENS.F1DT_RCK.name);
            });
            it('should return the correct symbol', async function() {
                (await this.f1dtRck.symbol()).should.be.equal(TOKENS.F1DT_RCK.symbol);
            });
            it('should return the correct decimals', async function() {
                (await this.f1dtRck.decimals()).should.be.bignumber.equal(TOKEN_DECIMALS);
            });
            it('should return the correct total supply', async function() {
                (await this.f1dtRck.totalSupply()).should.be.bignumber.equal(TOKENS.F1DT_RCK.totalSupply);
            });
            it('should return the correct holder', async function() {
                (await this.f1dtRck.holder()).should.be.equal(tokenHolder);
            });
        });

        describe('F1DT.ECK', function() {
            it('should return the correct name', async function() {
                (await this.f1dtEck.name()).should.be.equal(TOKENS.F1DT_ECK.name);
            });
            it('should return the correct symbol', async function() {
                (await this.f1dtEck.symbol()).should.be.equal(TOKENS.F1DT_ECK.symbol);
            });
            it('should return the correct decimals', async function() {
                (await this.f1dtEck.decimals()).should.be.bignumber.equal(TOKEN_DECIMALS);
            });
            it('should return the correct total supply', async function() {
                (await this.f1dtEck.totalSupply()).should.be.bignumber.equal(TOKENS.F1DT_ECK.totalSupply);
            });
            it('should return the correct holder', async function() {
                (await this.f1dtEck.holder()).should.be.equal(tokenHolder);
            });
        });

        describe('F1DT.LCK', function() {
            it('should return the correct name', async function() {
                (await this.f1dtLck.name()).should.be.equal(TOKENS.F1DT_LCK.name);
            });
            it('should return the correct symbol', async function() {
                (await this.f1dtLck.symbol()).should.be.equal(TOKENS.F1DT_LCK.symbol);
            });
            it('should return the correct decimals', async function() {
                (await this.f1dtLck.decimals()).should.be.bignumber.equal(TOKEN_DECIMALS);
            });
            it('should return the correct total supply', async function() {
                (await this.f1dtLck.totalSupply()).should.be.bignumber.equal(TOKENS.F1DT_LCK.totalSupply);
            });
            it('should return the correct holder', async function() {
                (await this.f1dtLck.holder()).should.be.equal(tokenHolder);
            });
        });
    });
};
