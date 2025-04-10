// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script} from "lib/forge-std/src/Script.sol";
import {QstmeGems} from "../src/QstmeGems.sol";
import {ERC1967Proxy} from "@openzeppelin/5.3.0/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployGemsScript is Script {
    address public constant operator = 0x381c031bAA5995D0Cc52386508050Ac947780815;
    address public constant admin = 0x0d0D5Ff3cFeF8B7B2b1cAC6B6C27Fd0846c09361;
    uint256 public constant mintFee = 1e6;
    string public constant baseUri = "";

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
        vm.createSelectFork("base");
        uint256 deployerPK = vm.envUint("DEPLOYER_KEY");

        vm.broadcast(deployerPK);
        QstmeGems implementation = new QstmeGems();

        vm.broadcast(deployerPK);
        ERC1967Proxy proxy = new ERC1967Proxy(address(implementation), "");

        vm.broadcast(deployerPK);
        QstmeGems(address(proxy)).initialize(mintFee, baseUri, admin, operator, operator);
    }
}
