// SPDX-License-Identifier: MIT

pragma solidity 0.6.8;

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

    uint256 constant CRATE_TIER_LEGENDARY = 0;
    uint256 constant CRATE_TIER_EPIC = 1;
    uint256 constant CRATE_TIER_RARE = 2;
    uint256 constant CRATE_TIER_COMMON = 3;

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
    // uint256 internal constant _DRIVER_ID_NICO_HULKENBERG = 27;
    uint256 internal constant _DRIVER_ID_ALEXANDER_ALBON = 23;
    uint256 internal constant _DRIVER_ID_DANIIL_KVYAT = 26;
    uint256 internal constant _DRIVER_ID_GEORGE_RUSSEL = 63;
    // uint256 internal constant _DRIVER_ID_ROBERT_KUBICA = 88;
    uint256 internal constant _DRIVER_ID_ESTEBAN_OCON = 31;
    uint256 internal constant _DRIVER_ID_NICHOLAS_LATIFI = 6;


    //============================================================================================/
    //================================ Racing Stats Min/Max  =====================================/
    //============================================================================================/

    uint256 internal constant _RACING_STATS_T1_RARITY_1_MIN = 800;
    uint256 internal constant _RACING_STATS_T1_RARITY_1_MAX = 900;
    uint256 internal constant _RACING_STATS_T1_RARITY_2_MIN = 710;
    uint256 internal constant _RACING_STATS_T1_RARITY_2_MAX = 810;
    uint256 internal constant _RACING_STATS_T1_RARITY_3_MIN = 680;
    uint256 internal constant _RACING_STATS_T1_RARITY_3_MAX = 780;
    uint256 internal constant _RACING_STATS_T1_RARITY_4_MIN = 610;
    uint256 internal constant _RACING_STATS_T1_RARITY_4_MAX = 710;
    uint256 internal constant _RACING_STATS_T1_RARITY_5_MIN = 570;
    uint256 internal constant _RACING_STATS_T1_RARITY_5_MAX = 680;
    uint256 internal constant _RACING_STATS_T1_RARITY_6_MIN = 540;
    uint256 internal constant _RACING_STATS_T1_RARITY_6_MAX = 650;
    uint256 internal constant _RACING_STATS_T1_RARITY_7_MIN = 500;
    uint256 internal constant _RACING_STATS_T1_RARITY_7_MAX = 580;
    uint256 internal constant _RACING_STATS_T1_RARITY_8_MIN = 480;
    uint256 internal constant _RACING_STATS_T1_RARITY_8_MAX = 550;
    uint256 internal constant _RACING_STATS_T1_RARITY_9_MIN = 450;
    uint256 internal constant _RACING_STATS_T1_RARITY_9_MAX = 540;

    uint256 internal constant _RACING_STATS_T2_RARITY_1_MIN = 500;
    uint256 internal constant _RACING_STATS_T2_RARITY_1_MAX = 600;
    uint256 internal constant _RACING_STATS_T2_RARITY_2_MIN = 420;
    uint256 internal constant _RACING_STATS_T2_RARITY_2_MAX = 520;
    uint256 internal constant _RACING_STATS_T2_RARITY_3_MIN = 380;
    uint256 internal constant _RACING_STATS_T2_RARITY_3_MAX = 480;
    uint256 internal constant _RACING_STATS_T2_RARITY_4_MIN = 340;
    uint256 internal constant _RACING_STATS_T2_RARITY_4_MAX = 440;
    uint256 internal constant _RACING_STATS_T2_RARITY_5_MIN = 330;
    uint256 internal constant _RACING_STATS_T2_RARITY_5_MAX = 430;
    uint256 internal constant _RACING_STATS_T2_RARITY_6_MIN = 290;
    uint256 internal constant _RACING_STATS_T2_RARITY_6_MAX = 390;
    uint256 internal constant _RACING_STATS_T2_RARITY_7_MIN = 250;
    uint256 internal constant _RACING_STATS_T2_RARITY_7_MAX = 350;
    uint256 internal constant _RACING_STATS_T2_RARITY_8_MIN = 240;
    uint256 internal constant _RACING_STATS_T2_RARITY_8_MAX = 340;
    uint256 internal constant _RACING_STATS_T2_RARITY_9_MIN = 200;
    uint256 internal constant _RACING_STATS_T2_RARITY_9_MAX = 300;

    uint256 internal constant _RACING_STATS_T3_RARITY_1_MIN = 500;
    uint256 internal constant _RACING_STATS_T3_RARITY_1_MAX = 600;
    uint256 internal constant _RACING_STATS_T3_RARITY_2_MIN = 420;
    uint256 internal constant _RACING_STATS_T3_RARITY_2_MAX = 520;
    uint256 internal constant _RACING_STATS_T3_RARITY_3_MIN = 380;
    uint256 internal constant _RACING_STATS_T3_RARITY_3_MAX = 480;
    uint256 internal constant _RACING_STATS_T3_RARITY_4_MIN = 340;
    uint256 internal constant _RACING_STATS_T3_RARITY_4_MAX = 440;
    uint256 internal constant _RACING_STATS_T3_RARITY_5_MIN = 330;
    uint256 internal constant _RACING_STATS_T3_RARITY_5_MAX = 430;
    uint256 internal constant _RACING_STATS_T3_RARITY_6_MIN = 290;
    uint256 internal constant _RACING_STATS_T3_RARITY_6_MAX = 390;
    uint256 internal constant _RACING_STATS_T3_RARITY_7_MIN = 250;
    uint256 internal constant _RACING_STATS_T3_RARITY_7_MAX = 350;
    uint256 internal constant _RACING_STATS_T3_RARITY_8_MIN = 240;
    uint256 internal constant _RACING_STATS_T3_RARITY_8_MAX = 340;
    uint256 internal constant _RACING_STATS_T3_RARITY_9_MIN = 200;
    uint256 internal constant _RACING_STATS_T3_RARITY_9_MAX = 300;

    //============================================================================================/
    //================================== Types Drop Rates  =======================================/
    //============================================================================================/

    uint256 internal constant _TYPE_DROP_RATE_THRESH_COMPONENT = 82500;

    //============================================================================================/
    //================================== Rarity Drop Rates  ======================================/
    //============================================================================================/

    uint256 internal constant _COMMON_CRATE_DROP_RATE_THRESH_COMMON = 98.899 * 1000;
    uint256 internal constant _COMMON_CRATE_DROP_RATE_THRESH_RARE = 1 * 1000 + _COMMON_CRATE_DROP_RATE_THRESH_COMMON;
    uint256 internal constant _COMMON_CRATE_DROP_RATE_THRESH_EPIC = 0.1 * 1000 + _COMMON_CRATE_DROP_RATE_THRESH_RARE;

    uint256 internal constant _RARE_CRATE_DROP_RATE_THRESH_COMMON = 96.490 * 1000;
    uint256 internal constant _RARE_CRATE_DROP_RATE_THRESH_RARE = 2.5 * 1000 + _RARE_CRATE_DROP_RATE_THRESH_COMMON;
    uint256 internal constant _RARE_CRATE_DROP_RATE_THRESH_EPIC = 1 * 1000 + _RARE_CRATE_DROP_RATE_THRESH_RARE;

    uint256 internal constant _EPIC_CRATE_DROP_RATE_THRESH_COMMON = 92.4 * 1000;
    uint256 internal constant _EPIC_CRATE_DROP_RATE_THRESH_RARE = 5 * 1000 + _EPIC_CRATE_DROP_RATE_THRESH_COMMON;
    uint256 internal constant _EPIC_CRATE_DROP_RATE_THRESH_EPIC = 2.5 * 1000 + _EPIC_CRATE_DROP_RATE_THRESH_RARE;

    uint256 internal constant _LEGENDARY_CRATE_DROP_RATE_THRESH_COMMON = 84 * 1000;
    uint256 internal constant _LEGENDARY_CRATE_DROP_RATE_THRESH_RARE = 10 * 1000 + _LEGENDARY_CRATE_DROP_RATE_THRESH_COMMON;
    uint256 internal constant _LEGENDARY_CRATE_DROP_RATE_THRESH_EPIC = 5 * 1000 + _LEGENDARY_CRATE_DROP_RATE_THRESH_RARE;

    // Uses crateSeed bits [0;10[
    function generateCrate(uint256 crateSeed, uint256 crateTier, uint256 counter) internal pure returns (uint256[] memory tokens) {
        tokens = new uint256[](5);
        if (crateTier == CRATE_TIER_COMMON) {
            uint256 guaranteedRareDropIndex = crateSeed % 5;

            for (uint256 i = 0; i != 5; ++i) {
                uint256 tokenSeed = uint256(keccak256(abi.encodePacked(crateSeed, i)));
                tokens[i] = _makeTokenId(
                    _generateMetadata(
                        tokenSeed,
                        crateTier,
                        counter,
                        i,
                        i == guaranteedRareDropIndex? CRATE_TIER_RARE: CRATE_TIER_COMMON
                    )
                );
            }
        } else if (crateTier == CRATE_TIER_RARE) {
            (
                uint256 guaranteedRareDropIndex1,
                uint256 guaranteedRareDropIndex2,
                uint256 guaranteedRareDropIndex3
            ) = _generateThreeTokenIndices(crateSeed);

            for (uint256 i = 0; i != 5; ++i) {
                uint256 tokenSeed = uint256(keccak256(abi.encodePacked(crateSeed, i)));
                tokens[i] = _makeTokenId(
                    _generateMetadata(
                        tokenSeed,
                        crateTier,
                        counter,
                        i,
                        (
                            i == guaranteedRareDropIndex1 ||
                            i == guaranteedRareDropIndex2 ||
                            i == guaranteedRareDropIndex3
                        ) ? CRATE_TIER_RARE: CRATE_TIER_COMMON
                    )
                );
            }
        } else if (crateTier == CRATE_TIER_EPIC) {
            (
                uint256 guaranteedRareDropIndex,
                uint256 guaranteedEpicDropIndex
            ) = _generateTwoTokenIndices(crateSeed);

            for (uint256 i = 0; i != 5; ++i) {
                uint256 tokenSeed = uint256(keccak256(abi.encodePacked(crateSeed, i)));
                uint256 minRarityTier = CRATE_TIER_COMMON;
                if (i == guaranteedRareDropIndex) {
                    minRarityTier = CRATE_TIER_RARE;
                } else if (i == guaranteedEpicDropIndex) {
                    minRarityTier = CRATE_TIER_EPIC;
                }
                tokens[i] = _makeTokenId(
                    _generateMetadata(
                        tokenSeed,
                        crateTier,
                        counter,
                        i,
                        minRarityTier
                    )
                );
            }
        } else if (crateTier == CRATE_TIER_LEGENDARY) {
            (
                uint256 guaranteedRareDropIndex,
                uint256 guaranteedLegendaryDropIndex
            ) = _generateTwoTokenIndices(crateSeed);

            for (uint256 i = 0; i != 5; ++i) {
                uint256 tokenSeed = uint256(keccak256(abi.encodePacked(crateSeed, i)));
                uint256 minRarityTier = CRATE_TIER_COMMON;
                if (i == guaranteedRareDropIndex) {
                    minRarityTier = CRATE_TIER_RARE;
                } else if (i == guaranteedLegendaryDropIndex) {
                    minRarityTier = CRATE_TIER_LEGENDARY;
                }
                tokens[i] = _makeTokenId(
                    _generateMetadata(
                        tokenSeed,
                        crateTier,
                        counter,
                        i,
                        minRarityTier
                    )
                );
            }
        } else {
            revert("Crates2020RNG: wrong crate tier");
        }
    }

    /**
     * Select one index, then another
    */ 
    function _generateTwoTokenIndices(uint256 crateSeed) internal pure returns (uint256, uint256) {
        uint256 firstIndex = crateSeed % 5;
        return(
            firstIndex,
            (firstIndex + 1 + ((crateSeed >> 4) % 4)) % 5
        );
    }

    /**
     * To generate 3 random indices in a 5-size array, there are 10 possibilities:
     * value  ->  positions  ->  indices
     *   0        O O X X X     (2, 3, 4)
     *   1        O X O X X     (1, 3, 4)
     *   2        O X X O X     (1, 2, 4)
     *   3        O X X X O     (1, 2, 3)
     *   4        X O O X X     (0, 3, 4)
     *   5        X O X O X     (0, 2, 4)
     *   6        X O X X O     (0, 2, 3)
     *   7        X X O O X     (0, 1, 4)
     *   8        X X O X O     (0, 1, 3)
     *   9        X X X O O     (0, 1, 2)
     */
    function _generateThreeTokenIndices(uint256 crateSeed) internal pure returns (uint256, uint256, uint256) {
        uint256 value = crateSeed % 10;
        if (value == 0) return (2, 3, 4);
        if (value == 1) return (1, 3, 4);
        if (value == 2) return (1, 2, 4);
        if (value == 3) return (1, 2, 3);
        if (value == 4) return (0, 3, 4);
        if (value == 5) return (0, 2, 4);
        if (value == 6) return (0, 2, 3);
        if (value == 7) return (0, 1, 4);
        if (value == 8) return (0, 1, 3);
        if (value == 9) return (0, 1, 2);
    }

    function _generateMetadata(
        uint256 tokenSeed,
        uint256 crateTier,
        uint256 counter,
        uint256 index,
        uint256 minRarityTier
    ) private pure returns (Metadata memory metadata) {
        (uint256 tokenType, uint256 tokenSubType) = _generateType(tokenSeed >> 4, index); // Uses tokenSeed bits [4;41[
        metadata.tokenType = tokenType;
        if (tokenSubType != 0) {
            metadata.tokenSubType = tokenSubType;
        }

        uint256 tokenRarity = _generateRarity(tokenSeed >> 41, crateTier, minRarityTier); // Uses tokenSeed bits [41;73[
        metadata.tokenRarity = tokenRarity;

        if (tokenType == _TYPE_ID_CAR || tokenType == _TYPE_ID_DRIVER) {
            if (tokenRarity > 3) {
                metadata.model = _generateModel(tokenSeed >> 73); // Uses tokenSeed bits [73;81[
            } else {
                uint256 team = _generateTeam(tokenSeed >> 73); // Uses tokenSeed bits [73;81[
                metadata.team = team;
                if (tokenType == _TYPE_ID_DRIVER) {
                    metadata.driver = _generateDriver(tokenSeed >> 81, team); // Uses tokenSeed bits [81;82[;
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
            tokenType = 1 + (seed % 2); // Types {1, 2} = {Car, Driver}, using 1 bit
            tokenSubType = 0;
        } else {
            uint256 seedling = seed % 100000; // using > 16 bits, reserve 32
            if (seedling < _TYPE_DROP_RATE_THRESH_COMPONENT) {
                uint256 componentTypeSeed = (seed >> 32) % 3; // Type {3, 4} = {Gear, Part}, using 2 bits
                if (componentTypeSeed == 1) { // 1 chance out of 3
                    tokenType = _TYPE_ID_GEAR;
                    tokenSubType = 1 + ((seed >> 34) % 4); // Subtype [1-4], using 2 bits
                } else { // 2 chances out of 3
                    tokenType = _TYPE_ID_PART;
                    tokenSubType = 1 + ((seed >> 34) % 8); // Subtype [1-8], using 3 bits
                }
            } else {
                tokenType = _TYPE_ID_TYRES;
                tokenSubType = 1 + ((seed >> 32) % 5); // Subtype [1-5], using 3 bits
            }
        }
    }

    function _generateRarity(
        uint256 seed,
        uint256 crateTier,
        uint256 minRarityTier
    ) private pure returns (uint256 tokenRarity) {
        uint256 seedling = seed % 100000; // > 16 bits, reserve 32

        if (crateTier == CRATE_TIER_COMMON) {
            if (minRarityTier == CRATE_TIER_COMMON && seedling < _COMMON_CRATE_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (seedling < _COMMON_CRATE_DROP_RATE_THRESH_RARE) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _COMMON_CRATE_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        if (crateTier == CRATE_TIER_RARE) {
            if (minRarityTier == CRATE_TIER_COMMON && seedling < _RARE_CRATE_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (seedling < _RARE_CRATE_DROP_RATE_THRESH_RARE) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _RARE_CRATE_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        if (crateTier == CRATE_TIER_EPIC) {
            if (minRarityTier == CRATE_TIER_COMMON && seedling < _EPIC_CRATE_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (
                (minRarityTier == CRATE_TIER_COMMON || minRarityTier == CRATE_TIER_RARE)
                && seedling < _EPIC_CRATE_DROP_RATE_THRESH_RARE
            ) {
                return 4 + (seedling % 3); // Rarity [4-6]
            }
            if (seedling < _EPIC_CRATE_DROP_RATE_THRESH_EPIC) {
                return 2 + (seedling % 2); // Rarity [2-3]
            }
            return 1;
        }

        if (crateTier == CRATE_TIER_LEGENDARY) {
            if (minRarityTier == CRATE_TIER_COMMON && seedling < _LEGENDARY_CRATE_DROP_RATE_THRESH_COMMON) {
                return 7 + (seedling % 3); // Rarity [7-9]
            }
            if (minRarityTier == CRATE_TIER_COMMON || minRarityTier == CRATE_TIER_RARE) {
                if (seedling < _LEGENDARY_CRATE_DROP_RATE_THRESH_RARE) {
                    return 4 + (seedling % 3); // Rarity [4-6]
                }
                if (seedling < _LEGENDARY_CRATE_DROP_RATE_THRESH_EPIC) {
                    return 2 + (seedling % 2); // Rarity [2-3]
                }
            }
            return 1;
        }
    }

    function _generateModel(uint256 seed) private pure returns (uint256 model) {
        model = 1 + (seed % 10);
    }

    function _generateTeam(uint256 seed) private pure returns (uint256 team) {
        team = 1 + (seed % 10);
    }

    function _generateDriver(uint256 seed, uint256 team) private pure returns (uint256 driver) {
        uint256 index = (seed) % 2;

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
                _DRIVER_ID_ALEXANDER_ALBON,
                _DRIVER_ID_MAX_VERSTAPPEN
            ][index];
        } else if (team == _TEAM_ID_RENAULT_F1_TEAM) {
            driver = [
                _DRIVER_ID_DANIEL_RICCIARDO,
                _DRIVER_ID_ESTEBAN_OCON
            ][index];
        } else if (team == _TEAM_ID_RED_BULL_TORO_ROSSO_HONDA) {
            driver = [
                _DRIVER_ID_PIERRE_GASLY,
                _DRIVER_ID_DANIIL_KVYAT
            ][index];
        } else if (team == _TEAM_ID_ROKIT_WILLIAMS_RACING) {
            driver = [
                _DRIVER_ID_GEORGE_RUSSEL,
                _DRIVER_ID_NICHOLAS_LATIFI
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
