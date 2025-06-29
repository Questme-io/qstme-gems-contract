-include .env

build:
	forge build

test:
	forge test --via-ir

deployTestnet:
	forge script script/DeployGems.s.sol:DeployGemsScript \
	$(chain) \
	$(testnet) \
	--sig "deployTestnet(string,bool)" \
	-vvvv \
	--etherscan-api-key ${BASESCAN_API_KEY} \
# 	--verify \
# 	--broadcast

deployMainnet:
	forge script script/DeployGems.s.sol:DeployGemsScript \
	$(chain) \
	--sig "deployMainnet(string)" \
	-vvvv \
	--etherscan-api-key ${BASESCAN_API_KEY} \
# 	--verify \
# 	--broadcast

upgradeContract:
	forge script script/DeployGems.s.sol:DeployGemsScript \
	$(chain) \
	--sig "upgradeContract()" \
	-vvvv \
	--etherscan-api-key ${BASESCAN_API_KEY} \
# 	--verify \
# 	--broadcast

signDigest:
	forge script script/GenerateSignature.s.sol:GenerateSignatureScript \
	$(digest) \
	--sig "run(bytes32)" \
	-vv \
