// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {NftSwap} from "../src/NftSwap.sol";

contract NftSwapTest is Test {
    NftSwap public counter;

    function setUp() public {
        counter = new Counter();
        counter.setNumber(0);
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
