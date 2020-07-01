
pragma solidity = 0.5.16;

library Bytes {
    /**
     * @dev public function to convert bytes32 to string
     * @param _hash bytes32 hash to convert
     * @return string string convert from given bytes32
     */
    function hash2base32(bytes32 _hash) public pure returns(string memory _uintAsString) {
        bytes32 base32Alphabet = 0x6162636465666768696A6B6C6D6E6F707172737475767778797A323334353637;
        uint256 _i = uint256(_hash);
        uint256 k = 52;
        bytes memory bstr = new bytes(k);
        bstr[--k] = base32Alphabet[uint8((_i % 8) << 2)]; // uint8 s = uint8((256 - skip) % 5);  // (_i % (2**s)) << (5-s)
        _i /= 8;
        while (k > 0) {
            bstr[--k] = base32Alphabet[_i % 32];
            _i /= 32;
        }
        return string(bstr);
    }

    /**
     * @dev public function to convert uint256 to string
     * @param num uint256 integer to convert
     * @return string string convert from given uint256
     */
    function uint2str(uint256 num) public pure returns(string memory _uintAsString) {
        if (num == 0) {
            return "0";
        }

        uint256 j = num;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (num != 0) {
            bstr[k--] = bytes1(uint8(48 + (num % 10)));
            num /= 10;
        }

        return string(bstr);
    }

    function uint2hexstr(uint i) public pure returns(string memory) {
        uint length = 64;
        uint mask = 15;
        bytes memory bstr = new bytes(length);
        int k = int(length - 1);
        while (i != 0) {
            uint curr = (i & mask);
            bstr[uint(k--)] = curr > 9 ? byte(uint8(87 + curr)) : byte(uint8(48 + curr)); // 87 = 97 - 10
            i = i >> 4;
        }
        while (k >= 0) {
            bstr[uint(k--)] = byte(uint8(48));
        }
        return string(bstr);
    }
}