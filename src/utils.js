const { hexToUtf8, utf8ToHex, padRight } = require('web3-utils');

function stringToBytes32(value) {
    return padRight(utf8ToHex(value.slice(0, 32)), 64);
}

function bytes32ToString(value) {
    return hexToUtf8(value);
}

module.exports = {
    stringToBytes32,
    bytes32ToString
}
