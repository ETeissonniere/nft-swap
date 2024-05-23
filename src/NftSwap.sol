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

    constructor(IERC721 _nftFrom, uint256 _tokenIdFrom, IERC721 _nftTo, uint256 _tokenIdTo) {
        nftFrom = _nftFrom;
        tokenIdFrom = _tokenIdFrom;
        nftTo = _nftTo;
        tokenIdTo = _tokenIdTo;
    }

    function onERC721Received(address, address from, uint256 tokenId, bytes memory) public override returns (bytes4) {
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

    error ExpectedToBeFromOrToNft(address nft);
    error ExpectedToHaveReceivedNft(IERC721 nft, uint256 tokenId);
}
