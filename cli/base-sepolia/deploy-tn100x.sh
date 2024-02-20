#!/bin/bash
source .env

forge script script/base/DeployTN100x.s.sol:Run --rpc-url $SEPOLIA_RPC --broadcast --verify -vvvv --chain-id 84532 --etherscan-api-key "PLACEHOLDER_STRING"
