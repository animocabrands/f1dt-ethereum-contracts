// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

library Crates2020MetadataLib {

    struct Metadata {
        uint256 tokenType;
        uint256 tokenSubType;
        uint256 model;
        uint256 team;
        uint256 tokenRarity;
        uint256 label;
        uint256 driver;
        uint256 stat1;
        uint256 stat2;
        uint256 stat3;
        uint256 counter;
    }

    uint256 internal constant _CRATE_TIER_LEGENDARY = 0;
    uint256 internal constant _CRATE_TIER_EPIC = 1;
    uint256 internal constant _CRATE_TIER_RARE = 2;
    uint256 internal constant _CRATE_TIER_COMMON = 3;

    uint256 internal constant _RACING_STATS_T1_RARITY_1_MIN = 800;
    uint256 internal constant _RACING_STATS_T1_RARITY_1_MAX = 900;
    uint256 internal constant _RACING_STATS_T1_RARITY_2_MIN = 750;
    uint256 internal constant _RACING_STATS_T1_RARITY_2_MAX = 810;
    uint256 internal constant _RACING_STATS_T1_RARITY_3_MIN = 700;
    uint256 internal constant _RACING_STATS_T1_RARITY_3_MAX = 780;
    uint256 internal constant _RACING_STATS_T1_RARITY_4_MIN = 650;
    uint256 internal constant _RACING_STATS_T1_RARITY_4_MAX = 710;
    uint256 internal constant _RACING_STATS_T1_RARITY_5_MIN = 600;
    uint256 internal constant _RACING_STATS_T1_RARITY_5_MAX = 680;
    uint256 internal constant _RACING_STATS_T1_RARITY_6_MIN = 560;
    uint256 internal constant _RACING_STATS_T1_RARITY_6_MAX = 620;
    uint256 internal constant _RACING_STATS_T1_RARITY_7_MIN = 520;
    uint256 internal constant _RACING_STATS_T1_RARITY_7_MAX = 565;
    uint256 internal constant _RACING_STATS_T1_RARITY_8_MIN = 500;
    uint256 internal constant _RACING_STATS_T1_RARITY_8_MAX = 530;
    uint256 internal constant _RACING_STATS_T1_RARITY_9_MIN = 450;
    uint256 internal constant _RACING_STATS_T1_RARITY_9_MAX = 510;

    uint256 internal constant _RACING_STATS_T2_RARITY_1_MIN = 500;
    uint256 internal constant _RACING_STATS_T2_RARITY_1_MAX = 600;
    uint256 internal constant _RACING_STATS_T2_RARITY_2_MIN = 440;
    uint256 internal constant _RACING_STATS_T2_RARITY_2_MAX = 520;
    uint256 internal constant _RACING_STATS_T2_RARITY_3_MIN = 390;
    uint256 internal constant _RACING_STATS_T2_RARITY_3_MAX = 450;
    uint256 internal constant _RACING_STATS_T2_RARITY_4_MIN = 340;
    uint256 internal constant _RACING_STATS_T2_RARITY_4_MAX = 395;
    uint256 internal constant _RACING_STATS_T2_RARITY_5_MIN = 320;
    uint256 internal constant _RACING_STATS_T2_RARITY_5_MAX = 345;
    uint256 internal constant _RACING_STATS_T2_RARITY_6_MIN = 300;
    uint256 internal constant _RACING_STATS_T2_RARITY_6_MAX = 325;
    uint256 internal constant _RACING_STATS_T2_RARITY_7_MIN = 270;
    uint256 internal constant _RACING_STATS_T2_RARITY_7_MAX = 310;
    uint256 internal constant _RACING_STATS_T2_RARITY_8_MIN = 250;
    uint256 internal constant _RACING_STATS_T2_RARITY_8_MAX = 280;
    uint256 internal constant _RACING_STATS_T2_RARITY_9_MIN = 200;
    uint256 internal constant _RACING_STATS_T2_RARITY_9_MAX = 255;

    uint256 internal constant _RACING_STATS_T3_RARITY_1_MIN = 500;
    uint256 internal constant _RACING_STATS_T3_RARITY_1_MAX = 600;
    uint256 internal constant _RACING_STATS_T3_RARITY_2_MIN = 440;
    uint256 internal constant _RACING_STATS_T3_RARITY_2_MAX = 520;
    uint256 internal constant _RACING_STATS_T3_RARITY_3_MIN = 390;
    uint256 internal constant _RACING_STATS_T3_RARITY_3_MAX = 450;
    uint256 internal constant _RACING_STATS_T3_RARITY_4_MIN = 340;
    uint256 internal constant _RACING_STATS_T3_RARITY_4_MAX = 395;
    uint256 internal constant _RACING_STATS_T3_RARITY_5_MIN = 320;
    uint256 internal constant _RACING_STATS_T3_RARITY_5_MAX = 345;
    uint256 internal constant _RACING_STATS_T3_RARITY_6_MIN = 300;
    uint256 internal constant _RACING_STATS_T3_RARITY_6_MAX = 325;
    uint256 internal constant _RACING_STATS_T3_RARITY_7_MIN = 270;
    uint256 internal constant _RACING_STATS_T3_RARITY_7_MAX = 310;
    uint256 internal constant _RACING_STATS_T3_RARITY_8_MIN = 250;
    uint256 internal constant _RACING_STATS_T3_RARITY_8_MAX = 280;
    uint256 internal constant _RACING_STATS_T3_RARITY_9_MIN = 200;
    uint256 internal constant _RACING_STATS_T3_RARITY_9_MAX = 255;

    uint256 internal constant _SEASON_ID_2020 = 3;

    uint256 internal constant _TYPE_ID_CAR = 1;
    uint256 internal constant _TYPE_ID_DRIVER = 2;
    uint256 internal constant _TYPE_ID_PART = 3;
    uint256 internal constant _TYPE_ID_GEAR = 4;
    uint256 internal constant _TYPE_ID_TYRES = 5;

    uint256 internal constant _TEAM_ID_ALFA_ROMEO_RACING = 1;
    uint256 internal constant _TEAM_ID_SCUDERIA_FERRARI = 2;
    uint256 internal constant _TEAM_ID_HAAS_F1_TEAM = 3;
    uint256 internal constant _TEAM_ID_MCLAREN_F1_TEAM = 4;
    uint256 internal constant _TEAM_ID_MERCEDES_AMG_PETRONAS_MOTORSPORT = 5;
    uint256 internal constant _TEAM_ID_SPSCORE_RACING_POINT_F1_TEAM = 6;
    uint256 internal constant _TEAM_ID_ASTON_MARTIN_RED_BULL_RACING = 7;
    uint256 internal constant _TEAM_ID_RENAULT_F1_TEAM = 8;
    uint256 internal constant _TEAM_ID_RED_BULL_TORO_ROSSO_HONDA = 9;
    uint256 internal constant _TEAM_ID_ROKIT_WILLIAMS_RACING = 10;

    uint256 internal constant _DRIVER_ID_KIMI_RAIKKONEN = 7;
    uint256 internal constant _DRIVER_ID_ANTONIO_GIOVINAZZI = 99;
    uint256 internal constant _DRIVER_ID_SEBASTIAN_VETTEL = 5;
    uint256 internal constant _DRIVER_ID_CHARLES_LECLERC = 16;
    uint256 internal constant _DRIVER_ID_ROMAIN_GROSJEAN = 8;
    uint256 internal constant _DRIVER_ID_KEVIN_MAGNUSSEN = 20;
    uint256 internal constant _DRIVER_ID_LANDO_NORRIS = 4;
    uint256 internal constant _DRIVER_ID_CARLOS_SAINZ = 55;
    uint256 internal constant _DRIVER_ID_LEWIS_HAMILTON = 44;
    uint256 internal constant _DRIVER_ID_VALTTERI_BOTTAS = 77;
    uint256 internal constant _DRIVER_ID_SERGIO_PEREZ = 11;
    uint256 internal constant _DRIVER_ID_LANCE_STROLL = 18;
    uint256 internal constant _DRIVER_ID_PIERRE_GASLY = 10;
    uint256 internal constant _DRIVER_ID_MAX_VERSTAPPEN = 33;
    uint256 internal constant _DRIVER_ID_DANIEL_RICCIARDO = 3;
    uint256 internal constant _DRIVER_ID_NICO_HULKENBERG = 27;
    uint256 internal constant _DRIVER_ID_ALEXANDER_ALBON = 23;
    uint256 internal constant _DRIVER_ID_DANIIL_KVYAT = 26;
    uint256 internal constant _DRIVER_ID_GEORGE_RUSSEL = 63;
    uint256 internal constant _DRIVER_ID_ROBERT_KUBICA = 88;

    // Uses mainSeed bits [0;4[
    function generateCrate_oneGuaranteedDrop(
        uint256 mainSeed,
        uint256 crateTier,
        uint256 counter
    ) internal pure returns (uint256[] memory tokens) {
        tokens = new uint256[](5);

        uint256 guaranteedDropIndex = mainSeed % 5;

        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter)));
            tokens[i] = _makeTokenId(_generateMetadata(seed, crateTier, counter, i, i == guaranteedDropIndex));
        }
    }

    // Uses mainSeed bits [0;4[
    function generateCrate_twoGuaranteedDrops(
        uint256 mainSeed,
        uint256 crateTier,
        uint256 counter
    ) internal pure returns (uint256[] memory tokens) {
        tokens = new uint256[](5);

        uint256 guaranteedDropIndex1 = mainSeed % 5;
        uint256 guaranteedDropIndex2 = (1 + guaranteedDropIndex1 + ((mainSeed >> 4) % 4)) % 5;

        require(guaranteedDropIndex1 != guaranteedDropIndex2, "index error"); // for test

        for (uint256 i = 0; i < 5; ++i) {
            uint256 seed = uint256(keccak256(abi.encodePacked(mainSeed, counter)));
            tokens[i] = _makeTokenId(
                _generateMetadata(seed, crateTier, counter, i, i == guaranteedDropIndex1 || i == guaranteedDropIndex2)
            );
        }
    }

    function _generateMetadata(
        uint256 seed,
        uint256 crateTier,
        uint256 counter,
        uint256 index,
        bool isGuaranteedDrop
    ) private pure returns (Metadata memory metadata) {
        (metadata.tokenType, metadata.tokenSubType) = _generateType(seed >> 4, index); // Uses seed bits [4;36[
        metadata.tokenRarity = _generateRarity(seed >> 36, crateTier, isGuaranteedDrop); // Uses seed bits [36;68[
        _generateTeamData(seed >> 68, metadata); // Uses seed bits [68;76[
        (metadata.stat1, metadata.stat2, metadata.stat3) = _generateRacingStats(
            seed >> 128,
            metadata.tokenType,
            metadata.tokenRarity
        ); // Uses seed bits [128;170[
        metadata.counter = counter + index; // todo safemath?
    }

    function _generateType(uint256 seed, uint256 index)
        private
        pure
        returns (uint256 tokenType, uint256 tokenSubType)
    {
        if (index == 0) {
            tokenType = 1 + (seed % 2); // Types {1, 2} = {Car, Driver}
            tokenSubType = 0;
        } else {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (seedling < 5000) {
                // Tyres, 5.000%
                tokenType = _TYPE_ID_TYRES;
                tokenSubType = 1 + (seedling % 5); // Subtype [1-5]
            } else {
                // Parts/Gears, 95.000%
                tokenType = 3 + (seedling % 2); // Type {3, 4}
                if (tokenType == _TYPE_ID_PART) {
                    // Part
                    tokenSubType = 1 + (seedling % 8); // Subtype [1-8]
                } else {
                    // Gear
                    tokenSubType = 1 + (seedling % 4); // Subtype [1-4]
                }
            }
        }
    }

    function _generateRarity(
        uint256 seed,
        uint256 crateTier,
        bool isGuaranteedDrop
    ) private pure returns (uint256 tokenRarity) {
        if (crateTier == _CRATE_TIER_LEGENDARY) {
            if (isGuaranteedDrop) {
                tokenRarity = 1;
            } else {
                uint256 seedling = seed % 100000; // > 16 bits, reserve 32
                if (seedling < 15000) {
                    // Legendary, 15%
                    tokenRarity = 1;
                } else if (seedling < 55000) {
                    // Epic, 40%
                    tokenRarity = 3 - (seedling % 2); // Rarity [2-3]
                } else {
                    // Rare, 45%
                    tokenRarity = 6 - (seedling % 3); // Rarity [4-6]
                }
            }
        } else if (crateTier == _CRATE_TIER_EPIC) {
            // TODO
        } else if (crateTier == _CRATE_TIER_RARE) {
            // TODO
        } else if (crateTier == _CRATE_TIER_COMMON) {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (isGuaranteedDrop) {
                if (seedling == 0) {
                    // Legendary, 0.001%
                    tokenRarity = 1;
                } else if (seedling < 200) {
                    // Epic, 0.199%
                    tokenRarity = 3 - (seedling % 2); // Rarity [2-3]
                } else {
                    // Rare, 99.800%
                    tokenRarity = 6 - (seedling % 3); // Rarity [4-6]
                }
            } else {
                if (seedling == 0) {
                    // Legendary, 0.001%
                    tokenRarity = 1;
                } else if (seedling < 200) {
                    // Epic, 0.199%
                    tokenRarity = 3 - (seedling % 2); // Rarity [2-3]
                } else if (seedling < 5001) {
                    // Rare, normal 4.800%
                    tokenRarity = 6 - (seedling % 3); // Rarity [4-6]
                } else {
                    // Common, 95.000%
                    tokenRarity = 9 - (seedling % 3); // Rarity [7-9]
                }
            }
        } else {
            // revert();
        }
    }

    function _generateTeamData(uint256 seed, Metadata memory metadata) private pure {
        if (metadata.tokenType == _TYPE_ID_CAR || metadata.tokenType == _TYPE_ID_DRIVER) {
            if (metadata.tokenRarity < 4) {
                // Epic and above
                uint256 team = uint256(1 + (seed % 10));
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
                metadata.model = 1 + (seed % 10);
            }
        }
    }

    function _generateRacingStats(
        uint256 seed,
        uint256 tokenType,
        uint256 tokenRarity
    )
        private
        pure
        returns (
            uint256 stat1,
            uint256 stat2,
            uint256 stat3
        )
    {
        uint256 min;
        uint256 max;
        if (tokenType == _TYPE_ID_CAR || tokenType == _TYPE_ID_DRIVER) {
            // T1
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
        } else if (tokenType == _TYPE_ID_GEAR || tokenType == _TYPE_ID_PART) {
            // T2
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
        } else if (tokenType == _TYPE_ID_TYRES) {
            // T3
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
        stat1 = min + (seed % delta);
        stat2 = min + ((seed >> 16) % delta);
        stat3 = min + ((seed >> 32) % delta);
    }

    function _makeTokenId(Metadata memory metadata) private pure returns (uint256 tokenId) {
        tokenId = 1 << 255; // NF flag
        tokenId |= (metadata.tokenType << 240);
        tokenId |= (metadata.tokenSubType << 232);
        tokenId |= (_SEASON_ID_2020 << 224);
        tokenId |= (metadata.model << 192);
        tokenId |= (metadata.team << 184);
        tokenId |= (metadata.tokenRarity << 176);
        tokenId |= (metadata.label << 152);
        tokenId |= (metadata.driver << 136);
        tokenId |= (metadata.stat1 << 120);
        tokenId |= (metadata.stat2 << 104);
        tokenId |= (metadata.stat3 << 88);
        tokenId |= metadata.counter;
    }
}
