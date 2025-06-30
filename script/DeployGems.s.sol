// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script} from "lib/forge-std/src/Script.sol";
import {QstmeGems} from "../src/QstmeGems.sol";
import {SafeSingletonDeployer} from "./helpers/SafeSingletonDeployer.sol";
import {ERC1967Proxy} from "@openzeppelin/5.3.0/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployGemsScript is Script {
    address public constant operator = 0x91430EC444FD8249e152aDf82a73f985b031276E;
    address public constant admin = 0x885CefFc2f5428C3A2C5895204335ED6dcf466a1;
    QstmeGems public constant proxy = QstmeGems(0xa69a396c45Bd525f8516a43242580c4E88BbA401);
    uint256 public constant mintFee = 50_000_000_000_000;
    string public constant baseUri = "https://ipfs.io/ipfs/";
    bytes32 public constant SALT = keccak256("QstmeGems");

    function deployTestnet(string memory chain, bool isTestnet) public {
        require(isTestnet, "Not marked as testnet");
        vm.createSelectFork(chain);

        require(address(proxy).code.length == 0, "Already deployed");

        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");
        uint256 operatorPK = vm.envUint("OPERATOR_KEY");

        address gems = _deployGems(deployerPK);

        vm.broadcast(operatorPK);
        QstmeGems(address(gems)).initialize(mintFee, baseUri, operator, operator, operator);
    }

    function deployMainnet(string memory chain) public {
        vm.createSelectFork(chain);

        require(address(proxy).code.length == 0, "Already deployed");

        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");
        uint256 operatorPK = vm.envUint("OPERATOR_KEY");

        address gems = _deployGems(deployerPK);

        vm.broadcast(operatorPK);
        QstmeGems(address(gems)).initialize(mintFee, baseUri, admin, operator, operator);
    }

    function upgradeContract(string memory chain) public {
        vm.createSelectFork("base");

        require(address(proxy).code.length != 0, "Not deployed");

        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");
        uint256 operatorPK = vm.envUint("OPERATOR_KEY");

        vm.broadcast(deployerPK);
        QstmeGems implementation = new QstmeGems();

        vm.broadcast(operatorPK);
        proxy.upgradeToAndCall(address(implementation), "");
    }

    function _deployGems(uint256 deployerPK) internal returns(address) {
        bytes memory gemsCreationCode = type(QstmeGems).creationCode;

        address qstmeGems = SafeSingletonDeployer.broadcastDeploy({
            deployerPrivateKey: deployerPK,
            creationCode: gemsCreationCode,
            args: "",
            salt: SALT
        });

        address proxy = SafeSingletonDeployer.broadcastDeploy({
            deployerPrivateKey: deployerPK,
            creationCode: type(ERC1967Proxy).creationCode,
            args: abi.encode(address(qstmeGems), ""),
            salt: SALT
        });

        return proxy;
    }
}
