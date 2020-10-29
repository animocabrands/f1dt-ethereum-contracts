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

    struct StatsRange {
        uint128 minValue;
        uint128 maxValue;
    }

    struct TypesDropRates {
        uint256 car;
        uint256 driver;
        uint256 component;
        uint256 tyres;
    }

    struct RacingStats {
        uint16 stat1;
        uint16 stat2;
        uint16 stat3;
    }

    TypesDropRates[5] typesDropRates;

    uint48 counter;

    // Stats ranges by item type and rarity
    mapping(uint256 => StatsRange) t1Ranges; // Cars and Drivers
    mapping(uint256 => StatsRange) t2Ranges; // Components
    mapping(uint256 => StatsRange) t3Ranges; // Tyres

    mapping(uint256 => uint16[2]) teamDrivers;

    uint256[] commonDropRates = [
        0, // [0] Apex (0%)
        10, // [1] Legendary (0.001%)
        10, // [2] Epic (0.0995%)
        10, // [3] Epic (0.0995%)
        10, // [4] Rare (1.6%)
        10, // [5] Rare (1.6%)
        10, // [6] Rare (1.6%)
        10, // [7] Common (0%)
        10, // [8] Common (0%)
        10 // [9] Common (0%)
    ];

    constructor(uint256 startCounter) public {
        counter = startCounter.toUint32();

        t1Ranges[1] = StatsRange(uint128(650), uint128(900)); // Rarity 1 Legendary
        t1Ranges[2] = StatsRange(uint128(650), uint128(860)); // Rarity 2 Epic
        t1Ranges[3] = StatsRange(uint128(650), uint128(820)); // Rarity 3 Epic
        t1Ranges[4] = StatsRange(uint128(500), uint128(750)); // Rarity 4 Rare
        t1Ranges[5] = StatsRange(uint128(400), uint128(750)); // Rarity 5 Rare
        t1Ranges[6] = StatsRange(uint128(300), uint128(750)); // Rarity 6 Rare
        t1Ranges[7] = StatsRange(uint128(200), uint128(700)); // Rarity 7 Common
        t1Ranges[8] = StatsRange(uint128(150), uint128(700)); // Rarity 8 Common
        t1Ranges[9] = StatsRange(uint128(100), uint128(700)); // Rarity 9 Common

        t2Ranges[1] = StatsRange(uint128(100), uint128(150)); // Rarity 1 Legendary
        t2Ranges[2] = StatsRange(uint128(89), uint128(141)); //  Rarity 2 Epic
        t2Ranges[3] = StatsRange(uint128(78), uint128(132)); //  Rarity 3 Epic
        t2Ranges[4] = StatsRange(uint128(66), uint128(122)); //  Rarity 4 Rare
        t2Ranges[5] = StatsRange(uint128(55), uint128(113)); //  Rarity 5 Rare
        t2Ranges[6] = StatsRange(uint128(44), uint128(104)); //  Rarity 6 Rare
        t2Ranges[7] = StatsRange(uint128(33), uint128(95)); //   Rarity 7 Common
        t2Ranges[8] = StatsRange(uint128(21), uint128(85)); //   Rarity 8 Common
        t2Ranges[9] = StatsRange(uint128(10), uint128(76)); //   Rarity 9 Common

        t3Ranges[1] = StatsRange(uint128(200), uint128(300)); // Rarity 1 Legendary
        t3Ranges[2] = StatsRange(uint128(178), uint128(282)); //  Rarity 2 Epic
        t3Ranges[3] = StatsRange(uint128(155), uint128(263)); //  Rarity 3 Epic
        t3Ranges[4] = StatsRange(uint128(133), uint128(245)); //  Rarity 4 Rare
        t3Ranges[5] = StatsRange(uint128(110), uint128(226)); //  Rarity 5 Rare
        t3Ranges[6] = StatsRange(uint128(88), uint128(208)); //  Rarity 6 Rare
        t3Ranges[7] = StatsRange(uint128(65), uint128(189)); //   Rarity 7 Common
        t3Ranges[8] = StatsRange(uint128(43), uint128(171)); //   Rarity 8 Common
        t3Ranges[9] = StatsRange(uint128(20), uint128(152)); //   Rarity 9 Common

        teamDrivers[1] = [7, 99]; // Alfa Romeo Racing: Kimi Räikkönen, Antonio Giovinazzi
        teamDrivers[2] = [5, 16]; // Scuderia Ferrari: Sebastian Vettel, Charles Leclerc
        teamDrivers[3] = [8, 20]; // Haas F1® Team: Romain Grosjean, Kevin Magnussen
        teamDrivers[4] = [4, 55]; // McLaren F1® Team: Lando Norris, Carlos Sainz
        teamDrivers[5] = [44, 77]; // Mercedes-AMG Petronas Motorsport: Lewis Hamilton, Valtteri Bottas
        teamDrivers[6] = [11, 18]; // SpScore Racing Point F1® Team: Sergio Pérez, Lance Stroll
        teamDrivers[7] = [10, 33]; // Aston Martin Red Bull Racing: Pierre Gasly, Max Verstappen
        teamDrivers[8] = [3, 27]; // Renault F1® Team: Daniel Ricciardo, Nico Hülkenberg
        teamDrivers[9] = [23, 26]; // Red Bull Toro Rosso Honda: Alexander Albon, Daniil Kvyat
        teamDrivers[10] = [63, 88]; // ROKiT Williams Racing: George Russell, Robert Kubica

        typesDropRates[0] = TypesDropRates({car: 0, driver: 0, component: 0, tyres: 0});
        typesDropRates[1] = TypesDropRates({car: 0, driver: 0, component: 0, tyres: 0});
        typesDropRates[2] = TypesDropRates({car: 0, driver: 0, component: 0, tyres: 0});
        typesDropRates[3] = TypesDropRates({car: 0, driver: 0, component: 0, tyres: 0});
        typesDropRates[4] = TypesDropRates({car: 0, driver: 0, component: 0, tyres: 0});
    }

    function generateCommonTokens() external view returns (uint256[] memory tokens) {
        tokens = new uint256[](5);
        // uint256 mainSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _nonce++)));
        uint256 mainSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));

        uint48 counter_ = counter;

        uint256 rareTokenIndex = mainSeed % 5;

        bytes memory toHash = new bytes(32);
        for (uint256 i = 0; i < 5; ++i) {
            Metadata memory metadata;
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed >> (i * 50))));

            // RARITY
            if (i == rareTokenIndex) {
                metadata.tokenRarity = uint8(6 - (seed % 3)); // 2 bits, reserve 4
            } else {
                uint256 seedling = (seed >> 4) % 100000; // > 16 bits, reserve 32
                if (seedling == 0) {
                    // Legendary, 0.001%
                    metadata.tokenRarity = 1;
                } else if (seedling < 200) {
                    // Epic, 0.199%
                    metadata.tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else if (seedling < 5001) {
                    // Rare, 4.800%
                    metadata.tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                } else {
                    // Common, 95.000%
                    metadata.tokenRarity = uint8(9 - (seedling % 3)); // Rarity [7-9]
                }
            }

            // TYPES
            if (i == 0) {
                metadata.tokenType = uint8(1 + ((seed >> 36) % 2)); // Types {1, 2} // 1 bit, reserve 4
                metadata.tokenSubType = 0;
            } else {
                uint256 seedling = (seed >> 40) % 100000; // 16 bits, reserve 32
                if (seedling < 5001) {
                    // TODO
                    metadata.tokenType = 5;
                    metadata.tokenSubType = uint8(1 + (seedling % 5)); // Subtype [1-5]
                } else {
                    metadata.tokenType = uint8(3 + (seedling % 2)); // Type {3, 4}
                    if (metadata.tokenType == 3) {
                        // Part
                        metadata.tokenSubType = uint8(1 + (seedling % 8)); // Subtype [1-8]
                    } else {
                        // Gear
                        metadata.tokenSubType = uint8(1 + (seedling % 4)); // Subtype [1-4]
                    }
                }
            }

            // TEAM / MODEL
            if (metadata.tokenType == 1 || metadata.tokenType == 2) { // Car & Driver
                if (metadata.tokenRarity < 4) { // Epic and above
                    metadata.team = uint8(1 + (seed % 10));
                    if (metadata.tokenType == 2) { // Driver
                        metadata.driver = teamDrivers[metadata.team][seed % 2];
                    }
                } else { // Common and Rare
                    metadata.model = uint8(1 + (seed % 10));
                }
            }

            // metadata.track = 0;
            // metadata.label = 0;

            metadata.stats = generateRacingStats(metadata.tokenType, metadata.tokenRarity, seed);
            metadata.counter = counter_ + uint48(i); // todo safemath

            tokens[i] = makeTokenId(metadata);
        }

        // counter = counter_ + 5;
    }


    function generateLegendaryTokens() external view returns (uint256[] memory tokens) {
        tokens = new uint256[](5);
        // uint256 mainSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, _nonce++)));
        uint256 mainSeed = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));

        uint48 counter_ = counter;

        uint256 legendaryTokenIndex = mainSeed % 5;

        bytes memory toHash = new bytes(32);
        for (uint256 i = 0; i < 5; ++i) {
            Metadata memory metadata;
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed >> (i * 50))));

            // RARITY
            if (i == legendaryTokenIndex) {
                metadata.tokenRarity = 1;
            } else {
                uint256 seedling = (seed >> 4) % 100000; // > 16 bits, reserve 32
                if (seedling < 15000) { // Legendary, 15%
                    metadata.tokenRarity = 1;
                } else if (seedling < 55000) { // Epic, 40%
                    metadata.tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else { // Rare, 35%
                    metadata.tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                }
            }

            // TYPES
            if (i == 0) {
                metadata.tokenType = uint8(1 + ((seed >> 36) % 2)); // Types {1, 2} // 1 bit, reserve 4
                metadata.tokenSubType = 0;
            } else {
                uint256 seedling = (seed >> 40) % 100000; // 16 bits, reserve 32
                if (seedling < 5000) { // Tyres, 5.000%
                    metadata.tokenType = 5;
                    metadata.tokenSubType = uint8(1 + (seedling % 5)); // Subtype [1-5]
                } else { // Parts/Gears, 95.000%
                    metadata.tokenType = uint8(3 + (seedling % 2)); // Type {3, 4}
                    if (metadata.tokenType == 3) {
                        // Part
                        metadata.tokenSubType = uint8(1 + (seedling % 8)); // Subtype [1-8]
                    } else {
                        // Gear
                        metadata.tokenSubType = uint8(1 + (seedling % 4)); // Subtype [1-4]
                    }
                }
            }

            // TEAM / MODEL
            if (metadata.tokenType == 1 || metadata.tokenType == 2) { // Car & Driver
                if (metadata.tokenRarity < 4) { // Epic and above
                    metadata.team = uint8(1 + (seed % 10));
                    if (metadata.tokenType == 2) { // Driver
                        metadata.driver = teamDrivers[metadata.team][seed % 2];
                    }
                } else { // Common and Rare
                    metadata.model = uint8(1 + (seed % 10));
                }
            }

            metadata.stats = generateRacingStats(metadata.tokenType, metadata.tokenRarity, seed);
            metadata.counter = counter_ + uint48(i); // todo safemath

            tokens[i] = makeTokenId(metadata);
        }

        // counter = counter_ + 5;
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

    function generateRacingStats(
        uint256 tokenType,
        uint256 rarity,
        uint256 seed
    ) public view returns (RacingStats memory stats) {
        StatsRange memory range;
        if (tokenType == 1 || tokenType == 2) {
            range = t1Ranges[rarity];
        } else if (tokenType == 3 || tokenType == 4) {
            range = t2Ranges[rarity];
        } else if (tokenType == 5) {
            range = t3Ranges[rarity];
        } else {
            revert("Wrong token type");
        }
        uint256 delta = range.maxValue - range.minValue;
        stats.stat1 = (range.minValue + ((seed >> 16) % delta)).toUint16();
        stats.stat2 = (range.minValue + ((seed >> 32) % delta)).toUint16();
        stats.stat3 = (range.minValue + ((seed >> 48) % delta)).toUint16();
    }

    function test() external view returns (uint256[] memory seeds) {
        seeds = new uint256[](5);
        uint256 mainSeed = uint256(blockhash(block.number - 1));

        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = mainSeed >> (i * 50);
            bytes memory toHash = new bytes(32);
            assembly {
                mstore(add(toHash, 32), seed)
            }
            seeds[i] = uint256(keccak256(toHash));
        }
    }
}
