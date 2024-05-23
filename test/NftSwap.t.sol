// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.23;

import {Test, console} from "forge-std/Test.sol";
import {NftSwap} from "../src/NftSwap.sol";

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract QuickNft is ERC721 {
    constructor() ERC721("QuickNft", "QNF") {}

    function mint(address to, uint256 tokenId) public {
        _safeMint(to, tokenId);
    }
}

contract NftSwapTest is Test {
    QuickNft nft;
    NftSwap swap;

    address alice = vm.addr(1);
    address bob = vm.addr(2);

    function setUp() public {
        nft = new QuickNft();
        swap = new NftSwap();

        nft.mint(alice, 0);
        nft.mint(bob, 1);
    }

    function test_canReceiveNft() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        assertEq(nft.ownerOf(0), address(swap));
    }
}
