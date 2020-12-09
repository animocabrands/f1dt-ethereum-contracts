// SPDX-License-Identifier: MIT

pragma experimental ABIEncoderV2;
pragma solidity 0.6.8;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/SafeCast.sol";

library Crates2020RNGLib {

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

    uint256 internal constant _CRATE_TIER_COMMON = 3;
    uint256 internal constant _CRATE_TIER_RARE = 2;
    uint256 internal constant _CRATE_TIER_EPIC = 1;
    uint256 internal constant _CRATE_TIER_LEGENDARY = 0;

    //============================================================================================/
    //================================== Metadata Mappings  ======================================/
    //============================================================================================/

    uint256 internal constant _NF_FLAG = 1 << 255;

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

    //============================================================================================/
    //================================ Racing Stats Min/Max  =====================================/
    //============================================================================================/

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

    //============================================================================================/
    //================================== Types Drop Rates  =======================================/
    //============================================================================================/

    uint256 internal constant _TYPE_DROP_RATE_THRESH_COMPONENT = 95 * 1000; // 95%
    // uint256 internal constant _TYPE_DROP_RATE_THRESH_TYRES = 5 * 1000 + _TYPE_DROP_RATE_THRESH_COMPONENT; // 95%


    //============================================================================================/
    //================================== Rarity Drop Rates  ======================================/
    //============================================================================================/


    uint256 internal constant _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_COMMON = 95 * 1000; // 95%
    uint256 internal constant _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_RARE = 4.8 * 1000 + _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_COMMON; // 19%
    uint256 internal constant _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_EPIC = 0.199 * 1000 + _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_RARE; // 0.199%
    // uint256 internal constant _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_LEGENDARY = 0.001 * 1000 + _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_EPIC; // 0.001%

    // uint256 internal constant _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_COMMON = 0 * 1000; // 0%
    uint256 internal constant _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE = 99.8 * 1000; // 99.8%
    uint256 internal constant _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC = 0.199 * 1000 + _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE; // 0.199%
    // uint256 internal constant _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_LEGENDARY = 0.001 * 1000 + _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC; // 0.001%

    uint256 internal constant _RARE_CRATE_NORMAL_DROP_RATE_THRESH_COMMON = 80 * 1000; // 80%
    uint256 internal constant _RARE_CRATE_NORMAL_DROP_RATE_THRESH_RARE = 19 * 1000 + _RARE_CRATE_NORMAL_DROP_RATE_THRESH_COMMON; // 19%
    uint256 internal constant _RARE_CRATE_NORMAL_DROP_RATE_THRESH_EPIC = 0.9 * 1000 + _RARE_CRATE_NORMAL_DROP_RATE_THRESH_RARE; // 0.9%
    // uint256 internal constant _RARE_CRATE_NORMAL_DROP_RATE_THRESH_LEGENDARY = 0.1 * 1000 + _RARE_CRATE_NORMAL_DROP_RATE_THRESH_EPIC; // 0.1%

    // uint256 internal constant _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_COMMON = 0 * 1000; // 0%
    uint256 internal constant _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE = 99 * 1000; // 99%
    uint256 internal constant _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC = 0.9 * 1000 + _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE; // 0.9%
    // uint256 internal constant _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_LEGENDARY = 0.1 * 1000 + _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC; // 0.1%

    uint256 internal constant _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_COMMON = 75 * 1000; // 75%
    uint256 internal constant _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_RARE = 22 * 1000 + _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_COMMON; // 22%
    uint256 internal constant _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_EPIC = 2 * 1000 + _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_RARE; // 2%
    // uint256 internal constant _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_LEGENDARY = 1 * 1000 + _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_EPIC; // 1%

    // uint256 internal constant _EPIC_CRATE_GUARANTEED_DROP_RATE_THRESH_COMMON = 0 * 1000; // 0%
    // uint256 internal constant _EPIC_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE = 0 * 1000; // 0%
    uint256 internal constant _EPIC_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC = 99 * 1000; // 99%
    // uint256 internal constant _EPIC_CRATE_GUARANTEED_DROP_RATE_THRESH_LEGENDARY = 1 * 1000 + _EPIC_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC; // 1%

    uint256 internal constant _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_COMMON = 60 * 1000; // 60%
    uint256 internal constant _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_RARE = 33 * 1000 + _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_COMMON; // 33%
    uint256 internal constant _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_EPIC = 5 * 1000 + _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_RARE; // 5%
    // uint256 internal constant _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_LEGENDARY = 2 * 1000 + _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_EPIC; // 2%

    // uint256 internal constant _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_COMMON = 0 * 1000; // 0%
    // uint256 internal constant _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE = _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_COMMON + 0 * 1000; // 0%
    // uint256 internal constant _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC = _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE + 0 * 1000; // 0%
    // uint256 internal constant _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_LEGENDARY = _LEGENDARY_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC + 100 * 1000; // 100%


    function generateCrate(uint256 crateSeed, uint256 crateTier, uint256 counter) internal pure returns (uint256[] memory tokens) {
        require(crateTier < 4, "Crates2020: wrong crate tier");
        if (crateTier == Crates2020RNGLib._CRATE_TIER_RARE) {
            tokens = _generateCrate_twoGuaranteedDrops(crateSeed, crateTier, counter);
        } else {
            tokens = _generateCrate_oneGuaranteedDrop(crateSeed, crateTier, counter);
        }
    }

    // Uses mainSeed bits [0;4[
    function _generateCrate_oneGuaranteedDrop(
        uint256 crateSeed,
        uint256 crateTier,
        uint256 counter
    ) private pure returns (uint256[] memory tokens) {
        tokens = new uint256[](5);

        uint256 guaranteedDropIndex = crateSeed % 5;

        for (uint256 i = 0; i < 5; ++i) {
            uint256 tokenSeed = uint256(keccak256(abi.encodePacked(crateSeed, counter)));
            tokens[i] = _makeTokenId(_generateMetadata(tokenSeed, crateTier, counter, i, i == guaranteedDropIndex));
        }
    }

    // Uses mainSeed bits [0;4[
    function _generateCrate_twoGuaranteedDrops(
        uint256 crateSeed,
        uint256 crateTier,
        uint256 counter
    ) private pure returns (uint256[] memory tokens) {
        tokens = new uint256[](5);

        uint256 guaranteedDropIndex1 = crateSeed % 5;
        uint256 guaranteedDropIndex2 = (1 + guaranteedDropIndex1 + ((crateSeed >> 4) % 4)) % 5;

        require(guaranteedDropIndex1 != guaranteedDropIndex2, "index error"); // for test

        for (uint256 i = 0; i < 5; ++i) {
            uint256 tokenSeed = uint256(keccak256(abi.encodePacked(crateSeed, counter)));
            tokens[i] = _makeTokenId(
                _generateMetadata(tokenSeed, crateTier, counter, i, i == guaranteedDropIndex1 || i == guaranteedDropIndex2)
            );
        }
    }

    function _generateMetadata(
        uint256 tokenSeed,
        uint256 crateTier,
        uint256 counter,
        uint256 index,
        bool isGuaranteedDrop
    ) private pure returns (Metadata memory metadata) {
        (uint256 tokenType, uint256 tokenSubType) = _generateType(tokenSeed >> 4, index); // Uses tokenSeed bits [4;36[
        metadata.tokenType = tokenType;
        if (tokenSubType != 0) {
            metadata.tokenSubType = tokenSubType;
        }

        uint256 tokenRarity = _generateRarity(tokenSeed >> 36, crateTier, isGuaranteedDrop); // Uses tokenSeed bits [36;68[
        metadata.tokenRarity = tokenRarity;

        if (tokenType == _TYPE_ID_CAR || tokenType == _TYPE_ID_DRIVER) {
            if (tokenRarity > 3) {
                metadata.model = _generateModel(tokenSeed >> 68); // Uses tokenSeed bits [68;76[
            } else {
                uint256 team = _generateTeam(tokenSeed >> 68); // Uses tokenSeed bits [68;76[
                metadata.team = team;
                if (tokenType == _TYPE_ID_DRIVER) {
                    metadata.driver = _generateDriver(tokenSeed >> 76, team); // Uses tokenSeed bits [76;77[;
                }
            }
        }

        (metadata.stat1, metadata.stat2, metadata.stat3) = _generateRacingStats(
            tokenSeed >> 128,
            tokenType,
            tokenRarity
        ); // Uses tokenSeed bits [128;170[
        metadata.counter = counter + index;
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
            if (seedling < _TYPE_DROP_RATE_THRESH_COMPONENT) {
                tokenType = 3 + (seedling % 2); // Type {3, 4} = {Gear, Part}
                if (tokenType == _TYPE_ID_PART) {
                    tokenSubType = 1 + (seedling % 8); // Subtype [1-8]
                } else {
                    tokenSubType = 1 + (seedling % 4); // Subtype [1-4]
                }
            } else {
                tokenType = _TYPE_ID_TYRES;
                tokenSubType = 1 + (seedling % 5); // Subtype [1-5]
            }
        }
    }

    function _generateRarity(
        uint256 seed,
        uint256 crateTier,
        bool isGuaranteedDrop
    ) private pure returns (uint256 tokenRarity) {

        if (crateTier == _CRATE_TIER_COMMON) {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (isGuaranteedDrop) {
                if (seedling < _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE) {
                    return 4 + (seedling % 3); // Rarity [4-6]
                }
                if (seedling < _COMMON_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC) {
                    return 2 + (seedling % 2); // Rarity [2-3]
                }
                return 1;
            }
            if (seedling < _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (seedling < _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_RARE) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _COMMON_CRATE_NORMAL_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        if (crateTier == _CRATE_TIER_RARE) {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (isGuaranteedDrop) {
                if (seedling < _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_RARE) {
                    return 4 + (seedling % 3); // Rarity [4-6]
                }
                if (seedling < _RARE_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC) {
                    return 2 + (seedling % 2); // Rarity [2-3]
                }
                return 1;
            }
            if (seedling < _RARE_CRATE_NORMAL_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (seedling < _RARE_CRATE_NORMAL_DROP_RATE_THRESH_RARE) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _RARE_CRATE_NORMAL_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        if (crateTier == _CRATE_TIER_EPIC) {
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (isGuaranteedDrop) {
                if (seedling < _EPIC_CRATE_GUARANTEED_DROP_RATE_THRESH_EPIC) {
                    return 2 + (seedling % 2); // Rarity [2-3]
                }
                return 1;
            }
            if (seedling < _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (seedling < _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_RARE) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _EPIC_CRATE_NORMAL_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        if (crateTier == _CRATE_TIER_LEGENDARY) {
            if (isGuaranteedDrop) {
                return 1;
            }
            uint256 seedling = seed % 100000; // > 16 bits, reserve 32
            if (seedling < _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (seedling < _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_RARE) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _LEGENDARY_CRATE_NORMAL_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        revert("incorrect crate tier");
    }

    function _generateModel(uint256 seed) private pure returns (uint256 model) {
        model = 1 + (seed % 10);
    }

    function _generateTeam(uint256 seed) private pure returns (uint256 team) {
        team = 1 + (seed % 10);
    }

    function _generateDriver(uint256 seed, uint256 team) private pure returns (uint256 driver) {
        uint256 index = (seed >> 8) % 2;

        if (team == _TEAM_ID_ALFA_ROMEO_RACING) {
            driver = [
                _DRIVER_ID_KIMI_RAIKKONEN,
                _DRIVER_ID_ANTONIO_GIOVINAZZI
            ][index];
        } else if (team == _TEAM_ID_SCUDERIA_FERRARI) {
            driver = [
                _DRIVER_ID_SEBASTIAN_VETTEL,
                _DRIVER_ID_CHARLES_LECLERC
            ][index];
        } else if (team == _TEAM_ID_HAAS_F1_TEAM) {
            driver = [
                _DRIVER_ID_ROMAIN_GROSJEAN,
                _DRIVER_ID_KEVIN_MAGNUSSEN
            ][index];
        } else if (team == _TEAM_ID_MCLAREN_F1_TEAM) {
            driver = [
                _DRIVER_ID_LANDO_NORRIS,
                _DRIVER_ID_CARLOS_SAINZ
            ][index];
        } else if (team == _TEAM_ID_MERCEDES_AMG_PETRONAS_MOTORSPORT) {
            driver = [
                _DRIVER_ID_LEWIS_HAMILTON,
                _DRIVER_ID_VALTTERI_BOTTAS
            ][index];
        } else if (team == _TEAM_ID_SPSCORE_RACING_POINT_F1_TEAM) {
            driver = [
                _DRIVER_ID_SERGIO_PEREZ,
                _DRIVER_ID_LANCE_STROLL
            ][index];
        } else if (team == _TEAM_ID_ASTON_MARTIN_RED_BULL_RACING) {
            driver = [
                _DRIVER_ID_PIERRE_GASLY,
                _DRIVER_ID_MAX_VERSTAPPEN
            ][index];
        } else if (team == _TEAM_ID_RENAULT_F1_TEAM) {
            driver = [
                _DRIVER_ID_DANIEL_RICCIARDO,
                _DRIVER_ID_NICO_HULKENBERG
            ][index];
        } else if (team == _TEAM_ID_RED_BULL_TORO_ROSSO_HONDA) {
            driver = [
                _DRIVER_ID_ALEXANDER_ALBON,
                _DRIVER_ID_DANIIL_KVYAT
            ][index];
        } else if (team == _TEAM_ID_ROKIT_WILLIAMS_RACING) {
            driver = [
                _DRIVER_ID_GEORGE_RUSSEL,
                _DRIVER_ID_ROBERT_KUBICA
            ][index];
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
            if (tokenRarity == 1) {
                (min, max) = (_RACING_STATS_T1_RARITY_1_MIN, _RACING_STATS_T1_RARITY_1_MAX);
            } else if (tokenRarity == 2) {
                (min, max) = (_RACING_STATS_T1_RARITY_2_MIN, _RACING_STATS_T1_RARITY_2_MAX);
            } else if (tokenRarity == 3) {
                (min, max) = (_RACING_STATS_T1_RARITY_3_MIN, _RACING_STATS_T1_RARITY_3_MAX);
            } else if (tokenRarity == 4) {
                (min, max) = (_RACING_STATS_T1_RARITY_4_MIN, _RACING_STATS_T1_RARITY_4_MAX);
            } else if (tokenRarity == 5) {
                (min, max) = (_RACING_STATS_T1_RARITY_5_MIN, _RACING_STATS_T1_RARITY_5_MAX);
            } else if (tokenRarity == 6) {
                (min, max) = (_RACING_STATS_T1_RARITY_6_MIN, _RACING_STATS_T1_RARITY_6_MAX);
            } else if (tokenRarity == 7) {
                (min, max) = (_RACING_STATS_T1_RARITY_7_MIN, _RACING_STATS_T1_RARITY_7_MAX);
            } else if (tokenRarity == 8) {
                (min, max) = (_RACING_STATS_T1_RARITY_8_MIN, _RACING_STATS_T1_RARITY_8_MAX);
            } else if (tokenRarity == 9) {
                (min, max) = (_RACING_STATS_T1_RARITY_9_MIN, _RACING_STATS_T1_RARITY_9_MAX);
            } else {
                revert("Wrong token rarity");
            }
        } else if (tokenType == _TYPE_ID_GEAR || tokenType == _TYPE_ID_PART) {
            if (tokenRarity == 1) {
                (min, max) = (_RACING_STATS_T2_RARITY_1_MIN, _RACING_STATS_T2_RARITY_1_MAX);
            } else if (tokenRarity == 2) {
                (min, max) = (_RACING_STATS_T2_RARITY_2_MIN, _RACING_STATS_T2_RARITY_2_MAX);
            } else if (tokenRarity == 3) {
                (min, max) = (_RACING_STATS_T2_RARITY_3_MIN, _RACING_STATS_T2_RARITY_3_MAX);
            } else if (tokenRarity == 4) {
                (min, max) = (_RACING_STATS_T2_RARITY_4_MIN, _RACING_STATS_T2_RARITY_4_MAX);
            } else if (tokenRarity == 5) {
                (min, max) = (_RACING_STATS_T2_RARITY_5_MIN, _RACING_STATS_T2_RARITY_5_MAX);
            } else if (tokenRarity == 6) {
                (min, max) = (_RACING_STATS_T2_RARITY_6_MIN, _RACING_STATS_T2_RARITY_6_MAX);
            } else if (tokenRarity == 7) {
                (min, max) = (_RACING_STATS_T2_RARITY_7_MIN, _RACING_STATS_T2_RARITY_7_MAX);
            } else if (tokenRarity == 8) {
                (min, max) = (_RACING_STATS_T2_RARITY_8_MIN, _RACING_STATS_T2_RARITY_8_MAX);
            } else if (tokenRarity == 9) {
                (min, max) = (_RACING_STATS_T2_RARITY_9_MIN, _RACING_STATS_T2_RARITY_9_MAX);
            } else {
                revert("Wrong token rarity");
            }
        } else if (tokenType == _TYPE_ID_TYRES) {
            if (tokenRarity == 1) {
                (min, max) = (_RACING_STATS_T3_RARITY_1_MIN, _RACING_STATS_T3_RARITY_1_MAX);
            } else if (tokenRarity == 2) {
                (min, max) = (_RACING_STATS_T3_RARITY_2_MIN, _RACING_STATS_T3_RARITY_2_MAX);
            } else if (tokenRarity == 3) {
                (min, max) = (_RACING_STATS_T3_RARITY_3_MIN, _RACING_STATS_T3_RARITY_3_MAX);
            } else if (tokenRarity == 4) {
                (min, max) = (_RACING_STATS_T3_RARITY_4_MIN, _RACING_STATS_T3_RARITY_4_MAX);
            } else if (tokenRarity == 5) {
                (min, max) = (_RACING_STATS_T3_RARITY_5_MIN, _RACING_STATS_T3_RARITY_5_MAX);
            } else if (tokenRarity == 6) {
                (min, max) = (_RACING_STATS_T3_RARITY_6_MIN, _RACING_STATS_T3_RARITY_6_MAX);
            } else if (tokenRarity == 7) {
                (min, max) = (_RACING_STATS_T3_RARITY_7_MIN, _RACING_STATS_T3_RARITY_7_MAX);
            } else if (tokenRarity == 8) {
                (min, max) = (_RACING_STATS_T3_RARITY_8_MIN, _RACING_STATS_T3_RARITY_8_MAX);
            } else if (tokenRarity == 9) {
                (min, max) = (_RACING_STATS_T3_RARITY_9_MIN, _RACING_STATS_T3_RARITY_9_MAX);
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
        tokenId = _NF_FLAG;
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
