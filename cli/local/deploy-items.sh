#!/bin/bash
source .env

forge script script/base/DeployItems.s.sol:Run --fork-url http://localhost:8545 --broadcast 
