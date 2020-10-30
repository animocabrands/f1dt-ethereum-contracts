// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

contract ContentGenerator {
    using SafeMath for uint256;
    using SafeCast for uint256;

    struct Metadata {
        uint8 tokenType;
        uint8 tokenSubType;
        uint8 model;
        uint8 team;
        uint8 tokenRarity;
        uint16 label;
        uint16 driver;
        RacingStats stats;
        uint48 counter;
    }

    struct RacingStats {
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
    }

    uint48 counter;

    constructor(uint256 startCounter) public {
        counter = startCounter.toUint32();
    }

    function generateSeed() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));
    }

    // Uses seed bits [0;4[
    function generateCommonTokens() external view returns (uint256[] memory tokens) {
        uint256 crateTier = 3;
        tokens = new uint256[](5);
        uint256 mainSeed = generateSeed();

        uint256 commonTokenIndex = mainSeed % 5;

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));
            Metadata memory metadata = generateMetadata(seed, crateTier, counter_, i, i == commonTokenIndex);
            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    // Uses seed bits [0;4[
    function generateRareTokens() external view returns (uint256[] memory tokens) {
        uint256 crateTier = 2;
        tokens = new uint256[](5);
        uint256 mainSeed = generateSeed();

        uint256 rareTokenIndex1 = mainSeed % 5;
        uint256 rareTokenIndex2 = (1 + rareTokenIndex1 + ((mainSeed >> 4) % 4)) % 5;

        require(rareTokenIndex1 != rareTokenIndex2, "index error"); // for test

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));
            Metadata memory metadata = generateMetadata(seed, crateTier, counter_, i, i == rareTokenIndex1 || i == rareTokenIndex2);
            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    // Uses seed bits [0;4[
    function generateEpicTokens() external view returns (uint256[] memory tokens) {
        uint256 crateTier = 1;
        tokens = new uint256[](5);
        uint256 mainSeed = generateSeed();

        uint256 epicTokenIndex = mainSeed % 5;

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));
            Metadata memory metadata = generateMetadata(seed, crateTier, counter_, i, i == epicTokenIndex);
            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    // Uses seed bits [0;4[
    function generateLegendaryTokens() external view returns (uint256[] memory tokens) {
        uint256 crateTier = 0;
        tokens = new uint256[](5);
        uint256 mainSeed = generateSeed();

        uint256 legendaryTokenIndex = mainSeed % 5;

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));
            Metadata memory metadata = generateMetadata(seed, crateTier, counter_, i, i == legendaryTokenIndex);
            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    function generateMetadata(uint256 seed, uint256 crateTier, uint48 baseCounter, uint256 index, bool isGuaranteedTier) public view returns (Metadata memory metadata) {
        (metadata.tokenType, metadata.tokenSubType) = generateType(seed >> 4, index); // Uses seed bits [4;36[
        metadata.tokenRarity = generateRarity(seed >> 36, crateTier, isGuaranteedTier); // Uses seed bits [36;68[
        generateTeamData(seed >> 68, metadata); // Uses seed bits [68;76[
        metadata.stats = generateRacingStats(seed >> 128, metadata.tokenType, metadata.tokenRarity); // Uses seed bits [128;170[
        metadata.counter = baseCounter + uint48(index); // todo safemath?
    }

    function generateType(uint256 seed, uint256 index) public view returns (uint8 tokenType, uint8 tokenSubType) {
        if (index == 0) {
            tokenType = uint8(1 + (seed % 2)); // Types {1, 2}
            tokenSubType = 0;
        } else {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (seedling < 5000) { // Tyres, 5.000%
                tokenType = 5;
                tokenSubType = uint8(1 + (seedling % 5)); // Subtype [1-5]
            } else { // Parts/Gears, 95.000%
                tokenType = uint8(3 + (seedling % 2)); // Type {3, 4}
                if (tokenType == 3) { // Part
                    tokenSubType = uint8(1 + (seedling % 8)); // Subtype [1-8]
                } else { // Gear
                    tokenSubType = uint8(1 + (seedling % 4)); // Subtype [1-4]
                }
            }
        }
    }

    function generateRarity(uint256 seed, uint256 crateTier, bool guaranteedItem) public view returns (uint8 tokenRarity) {
        if (crateTier == 0) { // Legendary Crate
            if (guaranteedItem) {
                tokenRarity = 1;
            } else {
                uint256 seedling = seed % 100000; // > 16 bits, reserve 32
                if (seedling < 15000) { // Legendary, 15%
                    tokenRarity = 1;
                } else if (seedling < 55000) { // Epic, 40%
                    tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else { // Rare, 45%
                    tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                }
            }
        } else if (crateTier == 1) { // Epic Crate
            // TODO
        } else if (crateTier == 2) { // Rare Crate
            // TODO
        } else if (crateTier == 3) { // Common Crate
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (guaranteedItem) {
                if (seedling == 0) {
                    // Legendary, 0.001%
                    tokenRarity = 1;
                } else if (seedling < 200) {
                    // Epic, 0.199%
                    tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else {
                    // Rare, 99.800%
                    tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                }
            } else {
                if (seedling == 0) {
                    // Legendary, 0.001%
                    tokenRarity = 1;
                } else if (seedling < 200) {
                    // Epic, 0.199%
                    tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else if (seedling < 5001) {
                    // Rare, normal 4.800%
                    tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                } else {
                    // Common, 95.000%
                    tokenRarity = uint8(9 - (seedling % 3)); // Rarity [7-9]
                }
            }
        } else {
            // revert();
        }
    }

    function generateTeamData(uint256 seed, Metadata memory metadata) public view {
        if (metadata.tokenType == 1 || metadata.tokenType == 2) { // Car & Driver
            if (metadata.tokenRarity < 4) { // Epic and above
                metadata.team = uint8(1 + (seed % 10));
                if (metadata.tokenType == 2) { // Driver
                    uint256 index = (seed >> 8) % 2;

                    if (metadata.team == 1) { // Alfa Romeo Racing: Kimi Räikkönen, Antonio Giovinazzi
                        metadata.driver = [7, 99][index];
                    } else if (metadata.team == 2) { // Scuderia Ferrari: Sebastian Vettel, Charles Leclerc
                        metadata.driver = [5, 16][index];
                    } else if (metadata.team == 3) { // Haas F1® Team: Romain Grosjean, Kevin Magnussen
                        metadata.driver = [8, 20][index];
                    } else if (metadata.team == 4) { // McLaren F1® Team: Lando Norris, Carlos Sainz
                        metadata.driver = [4, 55][index];
                    } else if (metadata.team == 5) { // Mercedes-AMG Petronas Motorsport: Lewis Hamilton, Valtteri Bottas
                        metadata.driver = [44, 77][index];
                    } else if (metadata.team == 6) { // SpScore Racing Point F1® Team: Sergio Pérez, Lance Stroll
                        metadata.driver = [11, 18][index];
                    } else if (metadata.team == 7) { // Aston Martin Red Bull Racing: Pierre Gasly, Max Verstappen
                        metadata.driver = [10, 33][index];
                    } else if (metadata.team == 8) { // Renault F1® Team: Daniel Ricciardo, Nico Hülkenberg
                        metadata.driver = [3, 27][index];
                    } else if (metadata.team == 9) { // Red Bull Toro Rosso Honda: Alexander Albon, Daniil Kvyat
                        metadata.driver = [23, 26][index];
                    } else if (metadata.team == 10) { // ROKiT Williams Racing: George Russell, Robert Kubica
                        metadata.driver = [63, 88][index];
                    }
                }
            } else {
                // Common and Rare
                metadata.model = uint8(1 + (seed % 10));
            }
        }
    }

    function generateRacingStats(
        uint256 seed,
        uint256 tokenType,
        uint256 tokenRarity
    ) public view returns (RacingStats memory stats) {
        uint256 min;
        uint256 max;
        if (tokenType == 1 || tokenType == 2) {
            if (tokenRarity == 1) {
                min = 650;
                max = 900;
            } else if (tokenRarity == 2) {
                min = 650;
                max = 860;
            } else if (tokenRarity == 3) {
                min = 650;
                max = 820;
            } else if (tokenRarity == 4) {
                min = 500;
                max = 750;
            } else if (tokenRarity == 5) {
                min = 400;
                max = 750;
            } else if (tokenRarity == 6) {
                min = 300;
                max = 750;
            } else if (tokenRarity == 7) {
                min = 200;
                max = 700;
            } else if (tokenRarity == 8) {
                min = 150;
                max = 700;
            } else if (tokenRarity == 9) {
                min = 100;
                max = 700;
            } else {
                revert("Wrong token rarity");
            }
        } else if (tokenType == 3 || tokenType == 4) {
            if (tokenRarity == 1) {
                min = 100;
                max = 150;
            } else if (tokenRarity == 2) {
                min = 89;
                max = 141;
            } else if (tokenRarity == 3) {
                min = 78;
                max = 132;
            } else if (tokenRarity == 4) {
                min = 66;
                max = 122;
            } else if (tokenRarity == 5) {
                min = 55;
                max = 113;
            } else if (tokenRarity == 6) {
                min = 44;
                max = 104;
            } else if (tokenRarity == 7) {
                min = 33;
                max = 95;
            } else if (tokenRarity == 8) {
                min = 21;
                max = 85;
            } else if (tokenRarity == 9) {
                min = 10;
                max = 76;
            } else {
                revert("Wrong token rarity");
            }
        } else if (tokenType == 5) { 
            if (tokenRarity == 1) {
                min = 200;
                max = 300;
            } else if (tokenRarity == 2) {
                min = 178;
                max = 282;
            } else if (tokenRarity == 3) {
                min = 155;
                max = 263;
            } else if (tokenRarity == 4) {
                min = 133;
                max = 245;
            } else if (tokenRarity == 5) {
                min = 110;
                max = 226;
            } else if (tokenRarity == 6) {
                min = 88;
                max = 208;
            } else if (tokenRarity == 7) {
                min = 65;
                max = 189;
            } else if (tokenRarity == 8) {
                min = 43;
                max = 171;
            } else if (tokenRarity == 9) {
                min = 20;
                max = 152;
            } else {
                revert("Wrong token rarity");
            }
        } else {
            revert("Wrong token type");
        }
        uint256 delta = max - min;
        stats.stat1 = (min + (seed % delta)).toUint16();
        stats.stat2 = (min + ((seed >> 16) % delta)).toUint16();
        stats.stat3 = (min + ((seed >> 32) % delta)).toUint16();
    }

    function makeTokenId(Metadata memory metadata) public view returns (uint256 tokenId) {
        tokenId = 1 << 255; // NF flag
        tokenId |= (uint256(metadata.tokenType) << 240);
        tokenId |= (uint256(metadata.tokenSubType) << 232);
        tokenId |= (3 << 224); // Season 2020
        tokenId |= (uint256(metadata.model) << 192);
        tokenId |= (uint256(metadata.team) << 184);
        tokenId |= (uint256(metadata.tokenRarity) << 176);
        tokenId |= (uint256(metadata.label) << 152);
        tokenId |= (uint256(metadata.driver) << 136);
        tokenId |= (uint256(metadata.stats.stat1) << 120);
        tokenId |= (uint256(metadata.stats.stat2) << 104);
        tokenId |= (uint256(metadata.stats.stat3) << 88);
        tokenId |= uint256(metadata.counter);
    }
}
