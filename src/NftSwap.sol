// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.23;

contract NftSwap {
    uint256 public number;

    function setNumber(uint256 newNumber) public {
        number = newNumber;
    }

    function increment() public {
        number++;
    }
}
