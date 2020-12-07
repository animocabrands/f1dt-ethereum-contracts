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

    uint256 internal constant _CRATE_TIER_LEGENDARY = 0;
    uint256 internal constant _CRATE_TIER_EPIC = 1;
    uint256 internal constant _CRATE_TIER_RARE = 2;
    uint256 internal constant _CRATE_TIER_COMMON = 3;

    uint16 internal constant _RACING_STATS_T1_RARITY_1_MIN = 800;
    uint16 internal constant _RACING_STATS_T1_RARITY_1_MAX = 900;
    uint16 internal constant _RACING_STATS_T1_RARITY_2_MIN = 750;
    uint16 internal constant _RACING_STATS_T1_RARITY_2_MAX = 810;
    uint16 internal constant _RACING_STATS_T1_RARITY_3_MIN = 700;
    uint16 internal constant _RACING_STATS_T1_RARITY_3_MAX = 780;
    uint16 internal constant _RACING_STATS_T1_RARITY_4_MIN = 650;
    uint16 internal constant _RACING_STATS_T1_RARITY_4_MAX = 710;
    uint16 internal constant _RACING_STATS_T1_RARITY_5_MIN = 600;
    uint16 internal constant _RACING_STATS_T1_RARITY_5_MAX = 680;
    uint16 internal constant _RACING_STATS_T1_RARITY_6_MIN = 560;
    uint16 internal constant _RACING_STATS_T1_RARITY_6_MAX = 620;
    uint16 internal constant _RACING_STATS_T1_RARITY_7_MIN = 520;
    uint16 internal constant _RACING_STATS_T1_RARITY_7_MAX = 565;
    uint16 internal constant _RACING_STATS_T1_RARITY_8_MIN = 500;
    uint16 internal constant _RACING_STATS_T1_RARITY_8_MAX = 530;
    uint16 internal constant _RACING_STATS_T1_RARITY_9_MIN = 450;
    uint16 internal constant _RACING_STATS_T1_RARITY_9_MAX = 510;

    uint16 internal constant _RACING_STATS_T2_RARITY_1_MIN = 500;
    uint16 internal constant _RACING_STATS_T2_RARITY_1_MAX = 600;
    uint16 internal constant _RACING_STATS_T2_RARITY_2_MIN = 440;
    uint16 internal constant _RACING_STATS_T2_RARITY_2_MAX = 520;
    uint16 internal constant _RACING_STATS_T2_RARITY_3_MIN = 390;
    uint16 internal constant _RACING_STATS_T2_RARITY_3_MAX = 450;
    uint16 internal constant _RACING_STATS_T2_RARITY_4_MIN = 340;
    uint16 internal constant _RACING_STATS_T2_RARITY_4_MAX = 395;
    uint16 internal constant _RACING_STATS_T2_RARITY_5_MIN = 320;
    uint16 internal constant _RACING_STATS_T2_RARITY_5_MAX = 345;
    uint16 internal constant _RACING_STATS_T2_RARITY_6_MIN = 300;
    uint16 internal constant _RACING_STATS_T2_RARITY_6_MAX = 325;
    uint16 internal constant _RACING_STATS_T2_RARITY_7_MIN = 270;
    uint16 internal constant _RACING_STATS_T2_RARITY_7_MAX = 310;
    uint16 internal constant _RACING_STATS_T2_RARITY_8_MIN = 250;
    uint16 internal constant _RACING_STATS_T2_RARITY_8_MAX = 280;
    uint16 internal constant _RACING_STATS_T2_RARITY_9_MIN = 200;
    uint16 internal constant _RACING_STATS_T2_RARITY_9_MAX = 255;

    uint16 internal constant _RACING_STATS_T3_RARITY_1_MIN = 500;
    uint16 internal constant _RACING_STATS_T3_RARITY_1_MAX = 600;
    uint16 internal constant _RACING_STATS_T3_RARITY_2_MIN = 440;
    uint16 internal constant _RACING_STATS_T3_RARITY_2_MAX = 520;
    uint16 internal constant _RACING_STATS_T3_RARITY_3_MIN = 390;
    uint16 internal constant _RACING_STATS_T3_RARITY_3_MAX = 450;
    uint16 internal constant _RACING_STATS_T3_RARITY_4_MIN = 340;
    uint16 internal constant _RACING_STATS_T3_RARITY_4_MAX = 395;
    uint16 internal constant _RACING_STATS_T3_RARITY_5_MIN = 320;
    uint16 internal constant _RACING_STATS_T3_RARITY_5_MAX = 345;
    uint16 internal constant _RACING_STATS_T3_RARITY_6_MIN = 300;
    uint16 internal constant _RACING_STATS_T3_RARITY_6_MAX = 325;
    uint16 internal constant _RACING_STATS_T3_RARITY_7_MIN = 270;
    uint16 internal constant _RACING_STATS_T3_RARITY_7_MAX = 310;
    uint16 internal constant _RACING_STATS_T3_RARITY_8_MIN = 250;
    uint16 internal constant _RACING_STATS_T3_RARITY_8_MAX = 280;
    uint16 internal constant _RACING_STATS_T3_RARITY_9_MIN = 200;
    uint16 internal constant _RACING_STATS_T3_RARITY_9_MAX = 255;

    uint8 internal constant _SEASON_ID_2020 = 3;

    uint8 internal constant _TYPE_ID_CAR = 1;
    uint8 internal constant _TYPE_ID_DRIVER = 2;
    uint8 internal constant _TYPE_ID_PART = 3;
    uint8 internal constant _TYPE_ID_GEAR = 4;
    uint8 internal constant _TYPE_ID_TYRES = 5;

    uint8 internal constant _TEAM_ID_ALFA_ROMEO_RACING = 1;
    uint8 internal constant _TEAM_ID_SCUDERIA_FERRARI = 2;
    uint8 internal constant _TEAM_ID_HAAS_F1_TEAM = 3;
    uint8 internal constant _TEAM_ID_MCLAREN_F1_TEAM = 4;
    uint8 internal constant _TEAM_ID_MERCEDES_AMG_PETRONAS_MOTORSPORT = 5;
    uint8 internal constant _TEAM_ID_SPSCORE_RACING_POINT_F1_TEAM = 6;
    uint8 internal constant _TEAM_ID_ASTON_MARTIN_RED_BULL_RACING = 7;
    uint8 internal constant _TEAM_ID_RENAULT_F1_TEAM = 8;
    uint8 internal constant _TEAM_ID_RED_BULL_TORO_ROSSO_HONDA = 9;
    uint8 internal constant _TEAM_ID_ROKIT_WILLIAMS_RACING = 10;

    uint16 internal constant _DRIVER_ID_KIMI_RAIKKONEN = 7;
    uint16 internal constant _DRIVER_ID_ANTONIO_GIOVINAZZI = 99;
    uint16 internal constant _DRIVER_ID_SEBASTIAN_VETTEL = 5;
    uint16 internal constant _DRIVER_ID_CHARLES_LECLERC = 16;
    uint16 internal constant _DRIVER_ID_ROMAIN_GROSJEAN = 8;
    uint16 internal constant _DRIVER_ID_KEVIN_MAGNUSSEN = 20;
    uint16 internal constant _DRIVER_ID_LANDO_NORRIS = 4;
    uint16 internal constant _DRIVER_ID_CARLOS_SAINZ = 55;
    uint16 internal constant _DRIVER_ID_LEWIS_HAMILTON = 44;
    uint16 internal constant _DRIVER_ID_VALTTERI_BOTTAS = 77;
    uint16 internal constant _DRIVER_ID_SERGIO_PEREZ = 11;
    uint16 internal constant _DRIVER_ID_LANCE_STROLL = 18;
    uint16 internal constant _DRIVER_ID_PIERRE_GASLY = 10;
    uint16 internal constant _DRIVER_ID_MAX_VERSTAPPEN = 33;
    uint16 internal constant _DRIVER_ID_DANIEL_RICCIARDO = 3;
    uint16 internal constant _DRIVER_ID_NICO_HULKENBERG = 27;
    uint16 internal constant _DRIVER_ID_ALEXANDER_ALBON = 23;
    uint16 internal constant _DRIVER_ID_DANIIL_KVYAT = 26;
    uint16 internal constant _DRIVER_ID_GEORGE_RUSSEL = 63;
    uint16 internal constant _DRIVER_ID_ROBERT_KUBICA = 88;


    constructor(uint256 startCounter) public {
        counter = startCounter.toUint32();
    }

    function generateSeed() public view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender)));
    }

    // Uses seed bits [0;4[
    function _generateTokens_oneGuaranteedDrop(uint256 mainSeed, uint256 crateTier)
        internal
        view
        returns (uint256[] memory tokens)
    {
        tokens = new uint256[](5);

        uint256 guaranteedDropIndex = mainSeed % 5;

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));
            Metadata memory metadata = generateMetadata(seed, crateTier, counter_, i, i == guaranteedDropIndex);
            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    // Uses seed bits [0;4[
    function _generateTokens_twoGuaranteedDrops(uint256 mainSeed, uint256 crateTier)
        internal
        view
        returns (uint256[] memory tokens)
    {
        tokens = new uint256[](5);

        uint256 guaranteedDropIndex1 = mainSeed % 5;
        uint256 guaranteedDropIndex2 = (1 + guaranteedDropIndex1 + ((mainSeed >> 4) % 4)) % 5;

        require(guaranteedDropIndex1 != guaranteedDropIndex2, "index error"); // for test

        uint48 counter_ = counter;
        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter_)));
            Metadata memory metadata = generateMetadata(
                seed,
                crateTier,
                counter_,
                i,
                i == guaranteedDropIndex1 || i == guaranteedDropIndex2
            );
            tokens[i] = makeTokenId(metadata);
        }
        // counter = counter_;
    }

    function generateCommonTokens() external view returns (uint256[] memory tokens) {
        tokens = _generateTokens_oneGuaranteedDrop(generateSeed(), _CRATE_TIER_COMMON);
    }

    function generateRareTokens() external view returns (uint256[] memory tokens) {
        tokens = _generateTokens_twoGuaranteedDrops(generateSeed(), _CRATE_TIER_RARE);
    }

    function generateEpicTokens() external view returns (uint256[] memory tokens) {
        tokens = _generateTokens_oneGuaranteedDrop(generateSeed(), _CRATE_TIER_EPIC);
    }

    function generateLegendaryTokens() external view returns (uint256[] memory tokens) {
        tokens = _generateTokens_oneGuaranteedDrop(generateSeed(), _CRATE_TIER_LEGENDARY);
    }

    function generateMetadata(
        uint256 seed,
        uint256 crateTier,
        uint48 baseCounter,
        uint256 index,
        bool isGuaranteedTier
    ) public pure returns (Metadata memory metadata) {
        (metadata.tokenType, metadata.tokenSubType) = generateType(seed >> 4, index); // Uses seed bits [4;36[
        metadata.tokenRarity = generateRarity(seed >> 36, crateTier, isGuaranteedTier); // Uses seed bits [36;68[
        generateTeamData(seed >> 68, metadata); // Uses seed bits [68;76[
        metadata.stats = generateRacingStats(seed >> 128, metadata.tokenType, metadata.tokenRarity); // Uses seed bits [128;170[
        metadata.counter = baseCounter + uint48(index); // todo safemath?
    }

    function generateType(uint256 seed, uint256 index) public pure returns (uint8 tokenType, uint8 tokenSubType) {
        if (index == 0) {
            tokenType = uint8(1 + (seed % 2)); // Types {1, 2}
            tokenSubType = 0;
        } else {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
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

    function generateRarity(
        uint256 seed,
        uint256 crateTier,
        bool guaranteedItem
    ) public pure returns (uint8 tokenRarity) {
        if (crateTier == _CRATE_TIER_LEGENDARY) {
            if (guaranteedItem) {
                tokenRarity = 1;
            } else {
                uint256 seedling = seed % 100000; // > 16 bits, reserve 32
                if (seedling < 15000) {
                    // Legendary, 15%
                    tokenRarity = 1;
                } else if (seedling < 55000) {
                    // Epic, 40%
                    tokenRarity = uint8(3 - (seedling % 2)); // Rarity [2-3]
                } else {
                    // Rare, 45%
                    tokenRarity = uint8(6 - (seedling % 3)); // Rarity [4-6]
                }
            }
        } else if (crateTier == _CRATE_TIER_EPIC) {
            // TODO
        } else if (crateTier == _CRATE_TIER_RARE) {
            // TODO
        } else if (crateTier == _CRATE_TIER_COMMON) {
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

    function generateTeamData(uint256 seed, Metadata memory metadata) public pure {
        if (metadata.tokenType == _TYPE_ID_CAR || metadata.tokenType == _TYPE_ID_DRIVER) {
            if (metadata.tokenRarity < 4) {
                // Epic and above
                uint8 team = uint8(1 + (seed % 10));
                metadata.team = team;
                if (metadata.tokenType == _TYPE_ID_DRIVER) {
                    uint256 index = (seed >> 8) % 2;

                    if (team == _TEAM_ID_ALFA_ROMEO_RACING) {
                        metadata.driver = [_DRIVER_ID_KIMI_RAIKKONEN, _DRIVER_ID_ANTONIO_GIOVINAZZI][index];
                    } else if (team == _TEAM_ID_SCUDERIA_FERRARI) {
                        metadata.driver = [_DRIVER_ID_SEBASTIAN_VETTEL, _DRIVER_ID_CHARLES_LECLERC][index];
                    } else if (team == _TEAM_ID_HAAS_F1_TEAM) {
                        metadata.driver = [_DRIVER_ID_ROMAIN_GROSJEAN, _DRIVER_ID_KEVIN_MAGNUSSEN][index];
                    } else if (team == _TEAM_ID_MCLAREN_F1_TEAM) {
                        metadata.driver = [_DRIVER_ID_LANDO_NORRIS, _DRIVER_ID_CARLOS_SAINZ][index];
                    } else if (team == _TEAM_ID_MERCEDES_AMG_PETRONAS_MOTORSPORT) {
                        metadata.driver = [_DRIVER_ID_LEWIS_HAMILTON, _DRIVER_ID_VALTTERI_BOTTAS][index];
                    } else if (team == _TEAM_ID_SPSCORE_RACING_POINT_F1_TEAM) {
                        metadata.driver = [_DRIVER_ID_SERGIO_PEREZ, _DRIVER_ID_LANCE_STROLL][index];
                    } else if (team == _TEAM_ID_ASTON_MARTIN_RED_BULL_RACING) {
                        metadata.driver = [_DRIVER_ID_PIERRE_GASLY, _DRIVER_ID_MAX_VERSTAPPEN][index];
                    } else if (team == _TEAM_ID_RENAULT_F1_TEAM) {
                        metadata.driver = [_DRIVER_ID_DANIEL_RICCIARDO, _DRIVER_ID_NICO_HULKENBERG][index];
                    } else if (team == _TEAM_ID_RED_BULL_TORO_ROSSO_HONDA) {
                        metadata.driver = [_DRIVER_ID_ALEXANDER_ALBON, _DRIVER_ID_DANIIL_KVYAT][index];
                    } else if (team == _TEAM_ID_ROKIT_WILLIAMS_RACING) {
                        metadata.driver = [_DRIVER_ID_GEORGE_RUSSEL, _DRIVER_ID_ROBERT_KUBICA][index];
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
    ) public pure returns (RacingStats memory stats) {
        uint256 min;
        uint256 max;
        if (tokenType == _TYPE_ID_CAR || tokenType == _TYPE_ID_DRIVER) { // T1
            if (tokenRarity == 1) {
                min = _RACING_STATS_T1_RARITY_1_MIN;
                max = _RACING_STATS_T1_RARITY_1_MAX;
            } else if (tokenRarity == 2) {
                min = _RACING_STATS_T1_RARITY_2_MIN;
                max = _RACING_STATS_T1_RARITY_2_MAX;
            } else if (tokenRarity == 3) {
                min = _RACING_STATS_T1_RARITY_3_MIN;
                max = _RACING_STATS_T1_RARITY_3_MAX;
            } else if (tokenRarity == 4) {
                min = _RACING_STATS_T1_RARITY_4_MIN;
                max = _RACING_STATS_T1_RARITY_4_MAX;
            } else if (tokenRarity == 5) {
                min = _RACING_STATS_T1_RARITY_5_MIN;
                max = _RACING_STATS_T1_RARITY_5_MAX;
            } else if (tokenRarity == 6) {
                min = _RACING_STATS_T1_RARITY_6_MIN;
                max = _RACING_STATS_T1_RARITY_6_MAX;
            } else if (tokenRarity == 7) {
                min = _RACING_STATS_T1_RARITY_7_MIN;
                max = _RACING_STATS_T1_RARITY_7_MAX;
            } else if (tokenRarity == 8) {
                min = _RACING_STATS_T1_RARITY_8_MIN;
                max = _RACING_STATS_T1_RARITY_8_MAX;
            } else if (tokenRarity == 9) {
                min = _RACING_STATS_T1_RARITY_9_MIN;
                max = _RACING_STATS_T1_RARITY_9_MAX;
            } else {
                revert("Wrong token rarity");
            }
        } else if (tokenType == _TYPE_ID_GEAR || tokenType == _TYPE_ID_PART) { // T2
            if (tokenRarity == 1) {
                min = _RACING_STATS_T2_RARITY_1_MIN;
                max = _RACING_STATS_T2_RARITY_1_MAX;
            } else if (tokenRarity == 2) {
                min = _RACING_STATS_T2_RARITY_2_MIN;
                max = _RACING_STATS_T2_RARITY_2_MAX;
            } else if (tokenRarity == 3) {
                min = _RACING_STATS_T2_RARITY_3_MIN;
                max = _RACING_STATS_T2_RARITY_3_MAX;
            } else if (tokenRarity == 4) {
                min = _RACING_STATS_T2_RARITY_4_MIN;
                max = _RACING_STATS_T2_RARITY_4_MAX;
            } else if (tokenRarity == 5) {
                min = _RACING_STATS_T2_RARITY_5_MIN;
                max = _RACING_STATS_T2_RARITY_5_MAX;
            } else if (tokenRarity == 6) {
                min = _RACING_STATS_T2_RARITY_6_MIN;
                max = _RACING_STATS_T2_RARITY_6_MAX;
            } else if (tokenRarity == 7) {
                min = _RACING_STATS_T2_RARITY_7_MIN;
                max = _RACING_STATS_T2_RARITY_7_MAX;
            } else if (tokenRarity == 8) {
                min = _RACING_STATS_T2_RARITY_8_MIN;
                max = _RACING_STATS_T2_RARITY_8_MAX;
            } else if (tokenRarity == 9) {
                min = _RACING_STATS_T2_RARITY_9_MIN;
                max = _RACING_STATS_T2_RARITY_9_MAX;
            } else {
                revert("Wrong token rarity");
            }
        } else if (tokenType == _TYPE_ID_TYRES) { // T3
            if (tokenRarity == 1) {
                min = _RACING_STATS_T3_RARITY_1_MIN;
                max = _RACING_STATS_T3_RARITY_1_MAX;
            } else if (tokenRarity == 2) {
                min = _RACING_STATS_T3_RARITY_2_MIN;
                max = _RACING_STATS_T3_RARITY_2_MAX;
            } else if (tokenRarity == 3) {
                min = _RACING_STATS_T3_RARITY_3_MIN;
                max = _RACING_STATS_T3_RARITY_3_MAX;
            } else if (tokenRarity == 4) {
                min = _RACING_STATS_T3_RARITY_4_MIN;
                max = _RACING_STATS_T3_RARITY_4_MAX;
            } else if (tokenRarity == 5) {
                min = _RACING_STATS_T3_RARITY_5_MIN;
                max = _RACING_STATS_T3_RARITY_5_MAX;
            } else if (tokenRarity == 6) {
                min = _RACING_STATS_T3_RARITY_6_MIN;
                max = _RACING_STATS_T3_RARITY_6_MAX;
            } else if (tokenRarity == 7) {
                min = _RACING_STATS_T3_RARITY_7_MIN;
                max = _RACING_STATS_T3_RARITY_7_MAX;
            } else if (tokenRarity == 8) {
                min = _RACING_STATS_T3_RARITY_8_MIN;
                max = _RACING_STATS_T3_RARITY_8_MAX;
            } else if (tokenRarity == 9) {
                min = _RACING_STATS_T3_RARITY_9_MIN;
                max = _RACING_STATS_T3_RARITY_9_MAX;
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

    function makeTokenId(Metadata memory metadata) public pure returns (uint256 tokenId) {
        tokenId = 1 << 255; // NF flag
        tokenId |= (uint256(metadata.tokenType) << 240);
        tokenId |= (uint256(metadata.tokenSubType) << 232);
        tokenId |= (uint256(_SEASON_ID_2020) << 224);
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
