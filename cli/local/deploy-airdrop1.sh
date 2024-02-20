#!/bin/bash
source .env

forge script script/base/DeployAirdrop1.s.sol:Run --fork-url http://localhost:8545 --broadcast 
