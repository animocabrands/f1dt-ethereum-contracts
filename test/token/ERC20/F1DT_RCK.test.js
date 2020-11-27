const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {BN, toAscii} = require('web3-utils');

const F1DT_RCK = contract.fromArtifact('F1DT_RCK');
const TOKEN_TOTAL_SUPPLY = '10000000123';
const TOKEN_INITIAL_AMOUNT = '1000000'
const TOKEN_DECIMALS = '18';

const [deployer, payout, owner, operator] = accounts;

describe('F1DT RCK', function() {
    describe('constructor(holders, amounts, totalSupply', function() {
        it('should revert with invalid arguments', async function() {
            await expectRevert(
                F1DT_RCK.new([deployer], [TOKEN_INITIAL_AMOUNT, TOKEN_INITIAL_AMOUNT], TOKEN_TOTAL_SUPPLY, {from: deployer}), 
                'F1DT_RCK: wrong arguments'
            );
        });
        it('should revert with a zero supply', async function() {
            await expectRevert(
                F1DT_RCK.new([deployer], [TOKEN_INITIAL_AMOUNT], 0, {from: deployer}), 
                'ERC20: invalid total supply'
            );
        });
        it('should deploy with correct parameters', async function() {
            await F1DT_RCK.new([deployer], [TOKEN_INITIAL_AMOUNT], TOKEN_TOTAL_SUPPLY, {from: deployer}); 
        });
    });

    describe('Token', function() {
        beforeEach(async function() {
            this.f1dtRck = await F1DT_RCK.new([deployer], [TOKEN_INITIAL_AMOUNT], TOKEN_TOTAL_SUPPLY, {from: deployer});
        });
        describe('Token Specification', function() {
            it('should return the correct name', async function() {
                const tokenName = await this.f1dtRck.name();
                tokenName.should.be.equal("F1&#174; Delta Time Rare Crate Key");
            });

            it('should return the correct symbol', async function() {
                const tokenSymbol = await this.f1dtRck.symbol();
                tokenSymbol.should.be.equal("F1DT.RCK");
            });

            it('should return the correct decimals', async function() {
                const tokenDecimals = await this.f1dtRck.decimals();
                tokenDecimals.should.be.bignumber.equal(TOKEN_DECIMALS);
            });
        });

        describe('Token Total Supply', function() {
            it('should return the correct total supply', async function() {
                const totalSupply = await this.f1dtRck.totalSupply();
                totalSupply.should.be.bignumber.equal(TOKEN_TOTAL_SUPPLY);
            });
        });
        describe('Token Mint', function() {
            it('should return the correct total supply after minting', async function() {
                
                // console.log("===============================");
                // console.log("CHECK MINT...")
            });
        });
    });
});
