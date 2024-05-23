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
        swap = new NftSwap(nft, 0, nft, 1);

        nft.mint(alice, 0);
        nft.mint(bob, 1);
    }

    function test_canReceiveNfts() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.prank(bob);
        nft.safeTransferFrom(bob, address(swap), 1);

        assertEq(nft.ownerOf(0), address(swap));
        assertEq(nft.ownerOf(1), address(swap));
    }

    function test_cannotReceiveUnexpectedNftContract() public {
        QuickNft anotherNft = new QuickNft();
        anotherNft.mint(alice, 0);

        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NftSwap.ExpectedToBeFromOrToNft.selector, address(anotherNft)));
        anotherNft.safeTransferFrom(alice, address(swap), 0);
    }

    function test_doesNotActuallyTrustBadNftContract() public {
        vm.prank(address(nft));
        vm.expectRevert(abi.encodeWithSelector(NftSwap.ExpectedToHaveReceivedNft.selector, address(nft), 0));
        swap.onERC721Received(address(0), address(nft), 0, "");
    }
}
