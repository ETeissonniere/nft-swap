// SPDX-License-Identifier: MIT License

pragma solidity ^0.8.23;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {ERC721Holder} from "openzeppelin-contracts/contracts/token/ERC721/utils/ERC721Holder.sol";

contract NftSwap is ERC721Holder {
    IERC721 public nftFrom;
    uint256 public tokenIdFrom;
    bool public receivedNftFrom;
    address public fromDepositor;

    IERC721 public nftTo;
    uint256 public tokenIdTo;
    bool public receivedNftTo;
    address public toDepositor;

    uint256 public expiry;

    constructor(IERC721 _nftFrom, uint256 _tokenIdFrom, IERC721 _nftTo, uint256 _tokenIdTo, uint256 _expiry) {
        nftFrom = _nftFrom;
        tokenIdFrom = _tokenIdFrom;
        nftTo = _nftTo;
        tokenIdTo = _tokenIdTo;
        expiry = _expiry;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public override returns (bytes4) {
        _mustNotBeExpired();
        _mustBeCorrectNftContract();
        _mustHaveNft(IERC721(msg.sender), tokenId);

        if (msg.sender == address(nftFrom) && tokenId == tokenIdFrom) {
            receivedNftFrom = true;
            fromDepositor = from;
        } else if (msg.sender == address(nftTo) && tokenId == tokenIdTo) {
            receivedNftTo = true;
            toDepositor = from;
        } else {
            revert("unreachable");
        }

        return this.onERC721Received.selector;
    }

    function cancel() public {
        _mustBeExpired();
        _mustNotHaveReceivedAllNfts();

        if (receivedNftFrom) {
            nftFrom.safeTransferFrom(address(this), fromDepositor, tokenIdFrom);
        }

        if (receivedNftTo) {
            nftTo.safeTransferFrom(address(this), toDepositor, tokenIdTo);
        }
    }

    function finalize() public {
        _mustHaveReceivedAllNfts();

        nftFrom.safeTransferFrom(address(this), toDepositor, tokenIdFrom);
        nftTo.safeTransferFrom(address(this), fromDepositor, tokenIdTo);
    }

    function _mustNotBeExpired() internal view {
        if (block.number > expiry) {
            revert Expired();
        }
    }

    function _mustBeCorrectNftContract() internal view {
        if (msg.sender != address(nftFrom) && msg.sender != address(nftTo)) {
            revert ExpectedToBeFromOrToNft(msg.sender);
        }
    }

    function _mustHaveNft(IERC721 nft, uint256 tokenId) internal view {
        if (nft.ownerOf(tokenId) != address(this)) {
            revert ExpectedToHaveReceivedNft(nft, tokenId);
        }
    }

    function _mustBeExpired() internal view {
        if (block.number <= expiry) {
            revert NotExpired();
        }
    }

    function _mustNotHaveReceivedAllNfts() internal view {
        if (receivedNftFrom && receivedNftTo) {
            revert AlreadyReceivedNfts();
        }
    }

    function _mustHaveReceivedAllNfts() internal view {
        if (!receivedNftFrom) {
            revert DidNotReceiveNft(nftFrom, tokenIdFrom);
        } else if (!receivedNftTo) {
            revert DidNotReceiveNft(nftTo, tokenIdTo);
        }
    }

    error ExpectedToBeFromOrToNft(address nft);
    error ExpectedToHaveReceivedNft(IERC721 nft, uint256 tokenId);
    error Expired();
    error NotExpired();
    error AlreadyReceivedNfts();
    error DidNotReceiveNft(IERC721 nft, uint256 tokenId);
}
