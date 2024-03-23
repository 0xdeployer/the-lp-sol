#!/bin/bash
source .env

forge script script/local/Floaties.s.sol:Run --fork-url http://localhost:8545 --broadcast 
