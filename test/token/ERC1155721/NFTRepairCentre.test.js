const {accounts, contract, web3} = require('@openzeppelin/test-environment');
const {expect} = require('chai');
const {ether, expectEvent, expectRevert} = require('@openzeppelin/test-helpers');
const {BN, toAscii} = require('web3-utils');
const {
    ZeroAddress,
    // EthAddress,
    EmptyByte,
    // Zero,
    One,
    Two,
    Three,
    Four,
    Five,
    ZeroBytes32,
} = require('@animoca/ethereum-contracts-core_library').constants;

const EthAddress = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

const {createTokenId} = require('@animoca/f1dt-core_metadata').utils;

const RepairCentre = contract.fromArtifact('NFTRepairCentre');
const REVV = contract.fromArtifact('REVV');
contract.artifactsDir = './imports';
const Bytes = contract.fromArtifact('Bytes');
const DeltaTimeInventory = contract.fromArtifact('DeltaTimeInventory');

const [deployer, payout, owner, operator] = accounts;

const graveyard = EthAddress;

const defectiveTokens = [
    createTokenId({counter: 1}, false),
    createTokenId({counter: 2}, false),
    createTokenId({counter: 3}, false),
];

const replacementTokens = [
    createTokenId({counter: 4}, false),
    createTokenId({counter: 5}, false),
    createTokenId({counter: 6}, false),
];

describe('NFTRepairCentre', function () {
    describe('constructor(inventoryContractAddress, graveyardAddress, revvContractAddress, revvCompensation)', function () {
        it('should revert with a zero address for the inventory contract', async function () {
            await expectRevert(RepairCentre.new(ZeroAddress, EthAddress, EthAddress, 0), 'RepairCentre: zero address');
        });
        it('should revert with a zero address for the graveyard', async function () {
            await expectRevert(RepairCentre.new(EthAddress, ZeroAddress, EthAddress, 0), 'RepairCentre: zero address');
        });
        it('should revert with a zero address for the REVV contract', async function () {
            await expectRevert(RepairCentre.new(EthAddress, EthAddress, ZeroAddress, 0), 'RepairCentre: zero address');
        });
    });

    describe('addTokensToRepair([defectiveTokens], [replacementTokens])', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([deployer], ['10000000000'], {from: deployer});
            this.repairCentre = await RepairCentre.new(EthAddress, graveyard, this.revv.address, 1, {from: deployer});
        });

        it('should revert with inconsistent array lengths', async function () {
            await expectRevert(
                this.repairCentre.addTokensToRepair(['0x1'], ['0xa', '0xb'], {from: deployer}),
                'RepairCentre: wrong lengths'
            );
        });

        it('should revert if not called by the owner', async function () {
            await expectRevert(
                this.repairCentre.addTokensToRepair(['0x1'], ['0xa'], {from: payout}),
                'Ownable: caller is not the owner'
            );
        });

        it('should revert if the REVV transfer fails', async function () {
            const defectiveTokens = [One, Two];
            const replacementTokens = [Three, Four];

            // no REVV approval
            await expectRevert.unspecified(
                this.repairCentre.addTokensToRepair(defectiveTokens, replacementTokens, {from: deployer})
            );
        });

        it('should add tokens successfully in correct conditions', async function () {
            const defectiveTokens = [One, Two];
            const replacementTokens = [Three, Four];

            await this.revv.approve(this.repairCentre.address, Two, {from: deployer});
            const receipt = await this.repairCentre.addTokensToRepair(defectiveTokens, replacementTokens, {
                from: deployer,
            });

            await expectEvent.inTransaction(receipt.tx, this.repairCentre, 'TokensToRepairAdded', {
                defectiveTokens: defectiveTokens.map((bn) => bn.toString()),
                replacementTokens: replacementTokens.map((bn) => bn.toString()),
            });
            await expectEvent.inTransaction(receipt.tx, this.revv, 'Transfer', {
                _from: deployer,
                _to: this.repairCentre.address,
                _value: Two,
            });
        });
    });

    describe('containsDefectiveToken([tokens])', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([deployer], ['10000000000'], {from: deployer});
            this.repairCentre = await RepairCentre.new(EthAddress, graveyard, this.revv.address, One, {from: deployer});
            await this.revv.approve(this.repairCentre.address, Two, {from: deployer});
            await this.repairCentre.addTokensToRepair([One], [Two], {from: deployer});
            await this.repairCentre.addTokensToRepair([Three], [Four], {from: deployer});
        });

        it('should return true when the tokens contain a defective token', async function () {
            expect(await this.repairCentre.containsDefectiveToken([One])).to.be.true;
            expect(await this.repairCentre.containsDefectiveToken([Five, One])).to.be.true;
            expect(await this.repairCentre.containsDefectiveToken([Three])).to.be.true;
            expect(await this.repairCentre.containsDefectiveToken([One, Three])).to.be.true;
            expect(await this.repairCentre.containsDefectiveToken([One, Three, Five])).to.be.true;
        });

        it('should return false when the tokens do not contain a defective token', async function () {
            expect(await this.repairCentre.containsDefectiveToken([Two])).to.be.false;
            expect(await this.repairCentre.containsDefectiveToken([Four])).to.be.false;
            expect(await this.repairCentre.containsDefectiveToken([Two, Four, Five])).to.be.false;
        });
    });

    describe('repair token with ERC1155 safeTransferFrom', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([deployer], ['10000000000'], {from: deployer});
            this.bytes = await Bytes.new({from: deployer});
            DeltaTimeInventory.network_id = 1337;
            await DeltaTimeInventory.link('Bytes', this.bytes.address);
            this.inventory = await DeltaTimeInventory.new(this.revv.address, graveyard, {from: deployer});
            this.repairCentre = await RepairCentre.new(this.inventory.address, graveyard, this.revv.address, 1, {
                from: deployer,
            });
            await this.inventory.addMinter(this.repairCentre.address, {from: deployer});
            await this.revv.approve(this.repairCentre.address, Three, {from: deployer});
            await this.repairCentre.addTokensToRepair(defectiveTokens, replacementTokens, {from: deployer});
            await this.inventory.batchMint(
                [owner, owner, owner],
                defectiveTokens,
                [ZeroBytes32, ZeroBytes32, ZeroBytes32],
                [1, 1, 1],
                true,
                {
                    from: deployer,
                }
            );
        });

        it('should revert if the transfer is coming from another NFT contract', async function () {
            const InventoryClone = DeltaTimeInventory.clone();
            const bytes = await Bytes.new({from: deployer});
            InventoryClone.network_id = 1337;
            await InventoryClone.link('Bytes', bytes.address);
            const inventory = await InventoryClone.new(this.revv.address, graveyard, {from: deployer});
            await inventory.batchMint(
                [owner, owner, owner],
                defectiveTokens,
                [ZeroBytes32, ZeroBytes32, ZeroBytes32],
                [1, 1, 1],
                true,
                {
                    from: deployer,
                }
            );

            await expectRevert(
                inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    owner,
                    this.repairCentre.address,
                    defectiveTokens[0],
                    1,
                    '0x0',
                    {
                        from: owner,
                    }
                ),
                'RepairCentre: wrong inventory'
            );
        });

        it('should revert if the token is not defective', async function () {
            const validToken = createTokenId({counter: 100}, false);
            await this.inventory.mintNonFungible(owner, validToken, ZeroBytes32, true, {from: deployer});

            await expectRevert(
                this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    owner,
                    this.repairCentre.address,
                    validToken,
                    1,
                    '0x0',
                    {
                        from: owner,
                    }
                ),
                'RepairCentre: token not defective'
            );
        });

        it('should replace the defective token', async function () {
            for (let i = 0; i < defectiveTokens.length; i++) {
                const defectiveToken = defectiveTokens[i];
                const replacementToken = replacementTokens[i];

                expect(await this.repairCentre.containsDefectiveToken([defectiveToken])).to.be.true;

                const receipt = await this.inventory.methods['safeTransferFrom(address,address,uint256,uint256,bytes)'](
                    owner,
                    this.repairCentre.address,
                    defectiveToken,
                    1,
                    '0x0',
                    {
                        from: owner,
                    }
                );

                await expectEvent.inTransaction(receipt.tx, this.inventory, 'TransferSingle', {
                    _operator: owner,
                    _from: owner,
                    _to: this.repairCentre.address,
                    _id: new BN(defectiveToken),
                    _value: One,
                });

                await expectEvent.inTransaction(receipt.tx, this.inventory, 'TransferSingle', {
                    _operator: this.repairCentre.address,
                    _from: this.repairCentre.address,
                    _to: graveyard,
                    _id: new BN(defectiveToken),
                    _value: One,
                });

                await expectEvent.inTransaction(receipt.tx, this.inventory, 'TransferSingle', {
                    _operator: this.repairCentre.address,
                    _from: ZeroAddress,
                    _to: owner,
                    _id: new BN(replacementToken),
                    _value: One,
                });

                // Retrieve and decode the log manually to avoid a bug in expectEvent
                const fullReceipt = await web3.eth.getTransactionReceipt(receipt.tx);
                const revvTransferLog = fullReceipt.logs.filter((log) => log.address == this.revv.address)[0];
                const revvTransferEventABI = this.revv.abi.filter((el) => el.name == 'Transfer')[0];
                const revvTransferEvent = web3.eth.abi.decodeLog(
                    revvTransferEventABI.inputs,
                    revvTransferLog.data,
                    revvTransferLog.topics.slice(1)
                );
                expect(revvTransferEvent._from).to.be.equal(this.repairCentre.address);
                expect(revvTransferEvent._to).to.be.equal(owner);
                expect(revvTransferEvent._value).to.be.equal('1');

                await expectEvent.inTransaction(receipt.tx, this.repairCentre, 'RepairedSingle', {
                    defectiveToken: new BN(defectiveToken),
                    replacementToken: new BN(replacementToken),
                });

                expect(await this.repairCentre.containsDefectiveToken([defectiveToken])).to.be.false;
            }
        });
    });

    describe('repair tokens with ERC1155 safeBatchTransferFrom', function () {
        beforeEach(async function () {
            this.revv = await REVV.new([deployer], ['10000000000'], {from: deployer});
            this.bytes = await Bytes.new({from: deployer});
            DeltaTimeInventory.network_id = 1337;
            await DeltaTimeInventory.link('Bytes', this.bytes.address);
            this.inventory = await DeltaTimeInventory.new(this.revv.address, graveyard, {from: deployer});
            this.repairCentre = await RepairCentre.new(this.inventory.address, graveyard, this.revv.address, 1, {
                from: deployer,
            });
            await this.inventory.addMinter(this.repairCentre.address, {from: deployer});
            await this.revv.approve(this.repairCentre.address, Three, {from: deployer});
            await this.repairCentre.addTokensToRepair(defectiveTokens, replacementTokens, {from: deployer});
            await this.inventory.batchMint(
                defectiveTokens.map(() => owner),
                defectiveTokens,
                defectiveTokens.map(() => ZeroBytes32),
                defectiveTokens.map(() => 1),
                true,
                {
                    from: deployer,
                }
            );
        });

        it('should revert if the transfer is coming from another NFT contract', async function () {
            const InventoryClone = DeltaTimeInventory.clone();
            const bytes = await Bytes.new({from: deployer});
            InventoryClone.network_id = 1337;
            await InventoryClone.link('Bytes', bytes.address);
            const inventory = await InventoryClone.new(this.revv.address, graveyard, {from: deployer});
            await inventory.batchMint(
                defectiveTokens.map(() => owner),
                defectiveTokens,
                defectiveTokens.map(() => ZeroBytes32),
                defectiveTokens.map(() => 1),
                true,
                {
                    from: deployer,
                }
            );

            await expectRevert(
                inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    owner,
                    this.repairCentre.address,
                    [defectiveTokens[0]],
                    [1],
                    '0x0',
                    {
                        from: owner,
                    }
                ),
                'RepairCentre: wrong inventory'
            );
        });

        it('should revert if one of the tokens is not defective', async function () {
            const validToken = createTokenId({counter: 100}, false);
            await this.inventory.mintNonFungible(owner, validToken, ZeroBytes32, true, {from: deployer});

            await expectRevert(
                this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    owner,
                    this.repairCentre.address,
                    [validToken],
                    [1],
                    '0x0',
                    {
                        from: owner,
                    }
                ),
                'RepairCentre: token not defective'
            );

            await expectRevert(
                this.inventory.methods['safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'](
                    owner,
                    this.repairCentre.address,
                    [defectiveTokens[0], validToken],
                    [1, 1],
                    '0x0',
                    {
                        from: owner,
                    }
                ),
                'RepairCentre: token not defective'
            );
        });

        it('should replace the defective tokens', async function () {
            expect(await this.repairCentre.containsDefectiveToken(defectiveTokens)).to.be.true;

            const receipt = await this.inventory.methods[
                'safeBatchTransferFrom(address,address,uint256[],uint256[],bytes)'
            ](
                owner,
                this.repairCentre.address,
                defectiveTokens,
                defectiveTokens.map(() => 1),
                EmptyByte,
                {
                    from: owner,
                }
            );

            await expectEvent.inTransaction(receipt.tx, this.inventory, 'TransferBatch', {
                _operator: owner,
                _from: owner,
                _to: this.repairCentre.address,
                _ids: defectiveTokens,
                _values: defectiveTokens.map(() => '1'),
            });

            await expectEvent.inTransaction(receipt.tx, this.inventory, 'TransferBatch', {
                _operator: this.repairCentre.address,
                _from: this.repairCentre.address,
                _to: graveyard,
                _ids: defectiveTokens,
                _values: defectiveTokens.map(() => '1'),
            });

            for (const replacementToken of replacementTokens) {
                await expectEvent.inTransaction(receipt.tx, this.inventory, 'TransferSingle', {
                    _operator: this.repairCentre.address,
                    _from: ZeroAddress,
                    _to: owner,
                    _id: new BN(replacementToken),
                    _value: One,
                });
            }

            // Retrieve and decode the log manually to avoid a bug in expectEvent
            const fullReceipt = await web3.eth.getTransactionReceipt(receipt.tx);
            const revvTransferLog = fullReceipt.logs.filter((log) => log.address == this.revv.address)[0];
            const revvTransferEventABI = this.revv.abi.filter((el) => el.name == 'Transfer')[0];
            const revvTransferEvent = web3.eth.abi.decodeLog(
                revvTransferEventABI.inputs,
                revvTransferLog.data,
                revvTransferLog.topics.slice(1)
            );
            expect(revvTransferEvent._from).to.be.equal(this.repairCentre.address);
            expect(revvTransferEvent._to).to.be.equal(owner);
            expect(revvTransferEvent._value).to.be.equal('3');

            await expectEvent.inTransaction(receipt.tx, this.repairCentre, 'RepairedBatch', {
                defectiveTokens,
                replacementTokens,
            });

            expect(await this.repairCentre.containsDefectiveToken(defectiveTokens)).to.be.false;
        });
    });
});
