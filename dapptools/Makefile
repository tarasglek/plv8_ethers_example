RPC_URL=https://mainnet.infura.io/v3/1b5fd3fd3d2c43e5b6f28070555e3280
BLOCK_NUMER=15217512
all    :; dapp build
clean  :; dapp clean; forge clean
dapp-test:
	ETH_RPC_URL=$(RPC_URL) dapp test -v 4  --rpc-block $(BLOCK_NUMER)
forge-test:
	forge test -vv -f $(RPC_URL) --fork-block-number $(BLOCK_NUMER)
deploy :; dapp create IOU
