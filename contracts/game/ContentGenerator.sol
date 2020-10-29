// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

contract ContentGenerator {
    using SafeMath for uint256;
    using SafeCast for uint256;

    uint256 constant PERCENT_DIV = 10000;
    uint8 constant SEASON = 3; // 2020

    uint8 constant NF_FLAG = 128;
    uint8 constant PADDING_1 = 0;
    uint24 constant PADDING_2 = 0;

    uint256 internal _nonce;

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

    function generateCommonTokens() external view returns (uint256[] memory tokens) {
        uint256 crateTier = 3;
        tokens = new uint256[](5);
        uint256 mainSeed = generateSeed();

        uint256 commonTokenIndex = mainSeed % 5;

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            Metadata memory metadata;
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));

            metadata.tokenRarity = generateRarity(seed, crateTier, i == commonTokenIndex);
            (metadata.tokenType, metadata.tokenSubType) = generateType(seed, i);
            generateTeamData(seed, metadata);
            metadata.stats = generateRacingStats(metadata.tokenType, metadata.tokenRarity, seed);
            metadata.counter = counter_++; // todo safemath

            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    function generateLegendaryTokens() external view returns (uint256[] memory tokens) {
        uint256 crateTier = 0;
        tokens = new uint256[](5);
        uint256 mainSeed = generateSeed();

        uint256 legendaryTokenIndex = mainSeed % 5;

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            Metadata memory metadata;
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));

            metadata.tokenRarity = generateRarity(seed, crateTier, i == legendaryTokenIndex);
            (metadata.tokenType, metadata.tokenSubType) = generateType(seed, i);
            generateTeamData(seed, metadata);
            metadata.stats = generateRacingStats(metadata.tokenType, metadata.tokenRarity, seed);
            metadata.counter = counter_++; // todo safemath

            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    function makeTokenId(Metadata memory metadata) public view returns (uint256 tokenId) {
        tokenId = (uint256(NF_FLAG) << 248);
        tokenId |= (uint256(metadata.tokenType) << 240);
        tokenId |= (uint256(metadata.tokenSubType) << 232);
        tokenId |= (uint256(SEASON) << 224);
        tokenId |= (uint256(PADDING_2) << 200);
        tokenId |= (uint256(metadata.model) << 192);
        tokenId |= (uint256(metadata.team) << 184);
        tokenId |= (uint256(metadata.tokenRarity) << 176);
        // tokenId |= (uint256(0 << 168));
        tokenId |= (uint256(metadata.label) << 152);
        tokenId |= (uint256(metadata.driver) << 136);
        tokenId |= (uint256(metadata.stats.stat1) << 120);
        tokenId |= (uint256(metadata.stats.stat2) << 104);
        tokenId |= (uint256(metadata.stats.stat3) << 88);
        // tokenId |= (uint256(0 << 72));
        // tokenId |= (uint256(0 << 64));
        // tokenId |= (uint256(0 << 56));
        // tokenId |= (uint256(0 << 48));
        tokenId |= uint256(metadata.counter);
    }

    function generateSeed() public view returns (uint256) {
        // uint256 mainSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _nonce++)));
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));
    }


    function generateType(uint256 seed, uint256 index) public view returns (uint8 tokenType, uint8 tokenSubType) {
        if (index == 0) {
            tokenType = uint8(1 + ((seed >> 36) % 2)); // Types {1, 2} // 1 bit, reserve 4
            tokenSubType = 0;
        } else {
            uint256 seedling = (seed >> 40) % 100000; // 16 bits, reserve 32
            if (seedling < 5000) {
                // Tyres, 5.000%
                tokenType = 5;
                tokenSubType = uint8(1 + (seedling % 5)); // Subtype [1-5]
            } else {
                // Parts/Gears, 95.000%
                tokenType = uint8(3 + (seedling % 2)); // Type {3, 4}
                if (tokenType == 3) {
                    // Part
                    tokenSubType = uint8(1 + (seedling % 8)); // Subtype [1-8]
                } else {
                    // Gear
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
                uint256 seedling = (seed >> 4) % 100000; // > 16 bits, reserve 32
                if (seedling < 15000) {
                    // Legendary, 15%
                    tokenRarity = 1;
                } else if (seedling < 55000) {
                    // Epic, 40%
                    tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else {
                    // Rare, 35%
                    tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                }
            }
        } else if (crateTier == 1) { // Epic Crate
            // TODO
        } else if (crateTier == 2) { // Rare Crate
            // TODO
        } else if (crateTier == 3) { // Common Crate
            uint256 seedling = (seed >> 4) % 100000; // > 16 bits, reserve 32
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
        if (metadata.tokenType == 1 || metadata.tokenType == 2) {
            // Car & Driver
            if (metadata.tokenRarity < 4) {
                // Epic and above
                metadata.team = uint8(1 + (seed % 10));
                if (metadata.tokenType == 2) {
                    // Driver
                    if (metadata.team == 1) { // Alfa Romeo Racing: Kimi Räikkönen, Antonio Giovinazzi
                        metadata.driver = [7, 99][seed % 2];
                    } else if (metadata.team == 2) { // Scuderia Ferrari: Sebastian Vettel, Charles Leclerc
                        metadata.driver = [5, 16][seed % 2];
                    } else if (metadata.team == 3) { // Haas F1® Team: Romain Grosjean, Kevin Magnussen
                        metadata.driver = [8, 20][seed % 2];
                    } else if (metadata.team == 4) { // McLaren F1® Team: Lando Norris, Carlos Sainz
                        metadata.driver = [4, 55][seed % 2];
                    } else if (metadata.team == 5) { // Mercedes-AMG Petronas Motorsport: Lewis Hamilton, Valtteri Bottas
                        metadata.driver = [44, 77][seed % 2];
                    } else if (metadata.team == 6) { // SpScore Racing Point F1® Team: Sergio Pérez, Lance Stroll
                        metadata.driver = [11, 18][seed % 2];
                    } else if (metadata.team == 7) { // Aston Martin Red Bull Racing: Pierre Gasly, Max Verstappen
                        metadata.driver = [10, 33][seed % 2];
                    } else if (metadata.team == 8) { // Renault F1® Team: Daniel Ricciardo, Nico Hülkenberg
                        metadata.driver = [3, 27][seed % 2];
                    } else if (metadata.team == 9) { // Red Bull Toro Rosso Honda: Alexander Albon, Daniil Kvyat
                        metadata.driver = [23, 26][seed % 2];
                    } else if (metadata.team == 10) { // ROKiT Williams Racing: George Russell, Robert Kubica
                        metadata.driver = [63, 88][seed % 2];
                    }
                }
            } else {
                // Common and Rare
                metadata.model = uint8(1 + (seed % 10));
            }
        }
    }

    function generateRacingStats(
        uint256 tokenType,
        uint256 rarity,
        uint256 seed
    ) public view returns (RacingStats memory stats) {
        uint256 min;
        uint256 max;
        if (tokenType == 1 || tokenType == 2) {
            if (rarity == 1) {
                min = 650;
                max = 900;
            } else if (rarity == 2) {
                min = 650;
                max = 860;
            } else if (rarity == 3) {
                min = 650;
                max = 820;
            } else if (rarity == 4) {
                min = 500;
                max = 750;
            } else if (rarity == 5) {
                min = 400;
                max = 750;
            } else if (rarity == 6) {
                min = 300;
                max = 750;
            } else if (rarity == 7) {
                min = 200;
                max = 700;
            } else if (rarity == 8) {
                min = 150;
                max = 700;
            } else if (rarity == 9) {
                min = 100;
                max = 700;
            }
        } else if (tokenType == 3 || tokenType == 4) {
            if (rarity == 1) {
                min = 100;
                max = 150;
            } else if (rarity == 2) {
                min = 89;
                max = 141;
            } else if (rarity == 3) {
                min = 78;
                max = 132;
            } else if (rarity == 4) {
                min = 66;
                max = 122;
            } else if (rarity == 5) {
                min = 55;
                max = 113;
            } else if (rarity == 6) {
                min = 44;
                max = 104;
            } else if (rarity == 7) {
                min = 33;
                max = 95;
            } else if (rarity == 8) {
                min = 21;
                max = 85;
            } else if (rarity == 9) {
                min = 10;
                max = 76;
            }
        } else if (tokenType == 5) { 
            if (rarity == 1) {
                min = 200;
                max = 300;
            } else if (rarity == 2) {
                min = 178;
                max = 282;
            } else if (rarity == 3) {
                min = 155;
                max = 263;
            } else if (rarity == 4) {
                min = 133;
                max = 245;
            } else if (rarity == 5) {
                min = 110;
                max = 226;
            } else if (rarity == 6) {
                min = 88;
                max = 208;
            } else if (rarity == 7) {
                min = 65;
                max = 189;
            } else if (rarity == 8) {
                min = 43;
                max = 171;
            } else if (rarity == 9) {
                min = 20;
                max = 152;
            }
        } else {
            revert("Wrong token type");
        }
        uint256 delta = max - min;
        stats.stat1 = (min + ((seed >> 16) % delta)).toUint16();
        stats.stat2 = (min + ((seed >> 32) % delta)).toUint16();
        stats.stat3 = (min + ((seed >> 48) % delta)).toUint16();
    }
}
