# Site Forge Contracts

# Deployed Contract in Testnet

[Site Forge Testnet Deployed Contract](https://suiscan.xyz/testnet/object/0xcde8c1552311e8d5bc4d685afeb9129d3ff70f0c6099270a24dd84d3f9e5d35f/tx-blocks)

## Contracts

1. Site Forge Token  -- site_forge_token.move

       Used to buy credits which will be used for AI usage

2. Subscription NFT -- subscription_nft.move

       Required to use the SuiNS service

3. Site Deployment -- site_deployment.move

       Links a deployed CID to a wallet

4. Access Control -- access_control.move

       Access control for deployed site based on NFT ownership

5. SuiNS Registration -- suins_registration.move

       Register SuiNS if NFT owned



### Build Instructions.

Bbecause of SuiNS, during build uncomment the below line 

    site_forge = "0xcde8c1552311e8d5bc4d685afeb9129d3ff70f0c6099270a24dd84d3f9e5d35f"

During publish set

    site_forge = "0x0"
