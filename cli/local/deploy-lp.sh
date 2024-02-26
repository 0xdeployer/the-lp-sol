#!/bin/bash
source .env

forge script script/base/DeployTheLP.s.sol:Run --fork-url http://localhost:8545 --broadcast 
