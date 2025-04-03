-include .env

build:
	forge build

test:
	forge test --via-ir

deployTestnet:
	forge script script/DeployGems.s.sol:DeployGemsScript \
	--sig "runTestnet()" \
	-vvvv \
	--etherscan-api-key ${BASESCAN_API_KEY} \
# 	--verify \
# 	--broadcast

deployMainnet:
	forge script script/DeployGems.s.sol:DeployGemsScript \
	--sig "runTestnet()" \
	-vvvv \
	--etherscan-api-key ${BASESCAN_API_KEY} \
# 	--verify \
# 	--broadcast
