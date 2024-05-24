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
        swap = new NftSwap(nft, 0, nft, 1, 1000);

        nft.mint(alice, 0);
        nft.mint(bob, 1);
    }

    function test_canReceiveNfts() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.prank(bob);
        nft.safeTransferFrom(bob, address(swap), 1);

        assertEq(nft.ownerOf(0), address(swap));
        assertEq(swap.receivedNftFrom(), true);
        assertEq(swap.fromDepositor(), alice);

        assertEq(nft.ownerOf(1), address(swap));
        assertEq(swap.receivedNftTo(), true);
        assertEq(swap.toDepositor(), bob);
    }

    function test_cancelIfExpiredAndOnlyFromReceived() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.roll(swap.expiry() + 1);

        swap.cancel();

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_cancelIfExpiredAndOnlyToReceived() public {
        vm.prank(bob);
        nft.safeTransferFrom(bob, address(swap), 1);

        vm.roll(swap.expiry() + 1);

        swap.cancel();

        assertEq(nft.ownerOf(0), alice);
        assertEq(nft.ownerOf(1), bob);
    }

    function test_cannotCancelEarly() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.expectRevert(abi.encodeWithSelector(NftSwap.NotExpired.selector));
        swap.cancel();
    }

    function test_cannotCancelIfDealFulfilled() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.prank(bob);
        nft.safeTransferFrom(bob, address(swap), 1);

        vm.roll(swap.expiry() + 1);

        vm.expectRevert(abi.encodeWithSelector(NftSwap.AlreadyReceivedNfts.selector));
        swap.cancel();
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

    function test_cannotDepositWhenExpired() public {
        vm.roll(swap.expiry() + 1);
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSelector(NftSwap.Expired.selector));
        nft.safeTransferFrom(alice, address(swap), 0);
    }

    function test_finalize() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.prank(bob);
        nft.safeTransferFrom(bob, address(swap), 1);

        swap.finalize();

        assertEq(nft.ownerOf(0), bob);
        assertEq(nft.ownerOf(1), alice);
    }

    function test_cannotFinalizeIfMissingToToken() public {
        vm.prank(alice);
        nft.safeTransferFrom(alice, address(swap), 0);

        vm.expectRevert(abi.encodeWithSelector(NftSwap.DidNotReceiveNft.selector, address(nft), 1));
        swap.finalize();
    }

    function test_cannotFinalizeIfMissingFromToken() public {
        vm.prank(bob);
        nft.safeTransferFrom(bob, address(swap), 1);

        vm.expectRevert(abi.encodeWithSelector(NftSwap.DidNotReceiveNft.selector, address(nft), 0));
        swap.finalize();
    }

    function test_depositERC721() public {
        vm.startPrank(alice);
        nft.approve(address(swap), 0);
        swap.depositERC721(address(nft), 0);
        vm.stopPrank();

        assertEq(nft.ownerOf(0), address(swap));
        assertEq(swap.receivedNftFrom(), true);
        assertEq(swap.fromDepositor(), alice);
    }
}
