// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script} from "lib/forge-std/src/Script.sol";
import {QstmeGems} from "../src/QstmeGems.sol";
import {ERC1967Proxy} from "@openzeppelin/5.3.0/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployGemsScript is Script {
    address public constant operator = 0x91430EC444FD8249e152aDf82a73f985b031276E;
    address public constant admin = 0x885CefFc2f5428C3A2C5895204335ED6dcf466a1;
    QstmeGems public constant proxy = QstmeGems(0x6c4A57b52b585d67A5dC8ae1B16E6901DECD39Bc);
    uint256 public constant mintFee = 50_000_000_000_000;
    string public constant baseUri = "https://ipfs.io/ipfs/bafybeifavt7m2xrorr6lmxb3gnolfmootyyp6sczpqkjatoiv2z2357ufa/";

    function runTestnet() public {
        vm.createSelectFork("baseSepolia");
        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");

        vm.broadcast(deployerPK);
        QstmeGems implementation = new QstmeGems();

        vm.broadcast(deployerPK);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");

        vm.broadcast(deployerPK);
        QstmeGems(address(proxy)).initialize(mintFee, baseUri, operator, operator, operator);
    }

    function runMainnet() public {
        require(address(proxy)==address(0), "Already deployed");
        vm.createSelectFork("base");
        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");

        vm.broadcast(deployerPK);
        QstmeGems implementation = new QstmeGems();

        vm.broadcast(deployerPK);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");

        vm.broadcast(deployerPK);
        QstmeGems(address(proxy)).initialize(mintFee, baseUri, admin, operator, operator);
    }

    function updateMainnet() public {
        vm.createSelectFork("base");
        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");
        uint256 operatorPK = vm.envUint("OPERATOR_KEY");

        vm.broadcast(deployerPK);
        QstmeGems implementation = new QstmeGems();

        vm.broadcast(operatorPK);
        proxy.upgradeToAndCall(address(implementation), "");

    }
}
