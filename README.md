# Sample Hardhat Project

## Deploying OFTs
Deploy token with:
```
npx hardhat ignition deploy ignition/modules/OFT.ts --network <network_name_here>
```

Deploy to all desired networks. Will then need to set the necessary configs for each token with the following 4 scripts (in this order):

```
updateRemotesOFT.ts
setLibrariesLz.ts
setSendConfigLz.ts
setReceiveConfigLz.ts
```

The scripts will ofcourse need to be adjusted to account for the different networks and token addresses. Follow their user guide on this page for more info on deployment steps:
https://docs.layerzero.network/v2/developers/evm/oft/quickstart#deployment-workflow
The 4 scripts above should have all of the necessary steps described in the link, and is just a matter of accounting for the different networks

More info on how composing messages with OFTs can be found here (background info, no real steps to follow):
https://docs.layerzero.network/v2/developers/evm/oft/oft-patterns-extensions#composed-oft

## Deploying Omnipool
Deploy Omnipool to each desired chain with:
```
npx hardhat ignition deploy ignition/modules/Omnipool.ts --network <network_name_here>
```

Set remotes with:
```
updateRemotes.ts
```

The Omnipool contract _should_ be working, but I didn't get a chance to test after adding in ITS functionality. Debugging using tenderly might be needed. Also refer to the Omnipool deployment script above to see the tokens required in deployer's wallet for this to work

## Deploying ITS
Can be done through their UI: https://interchain.axelar.dev/
