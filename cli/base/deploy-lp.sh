#!/bin/bash
source .env

forge script script/base/DeployTheLP.s.sol:Run --rpc-url $BASE_RPC --broadcast --verify -vvvv --chain-id 8453 --etherscan-api-key "AKWGHG3MA4NQKCK4W2KPSUKYUJ4FNJIME6"
