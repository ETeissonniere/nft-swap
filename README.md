# NftSwap: a simply way to swap two NFTs for each other in a fully trustless manner
Anybody may initiate a swap by:
1. Deploying the contract with the desired source and destination nfts
2. Depositing the NFTs in the contract
3. Calling `finalize()` to complete the swap

If the proper NFTs were not deposited into the contract, anyone may call `cancel()` once a certain `expiry` measured in blocks is reached.