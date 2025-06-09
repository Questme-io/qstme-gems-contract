// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import {Script} from "lib/forge-std/src/Script.sol";
import {QstmeGems} from "../src/QstmeGems.sol";
import {ERC1967Proxy} from "@openzeppelin/5.3.0/proxy/ERC1967/ERC1967Proxy.sol";

contract GenerateSignatureScript is Script {
    event log_bytes(bytes payload);

    function helper_sign(uint256 _privateKey, bytes32 _digest) public returns (bytes memory signature) {
        address signer = vm.addr(_privateKey);

        vm.startPrank(signer);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(_privateKey, _digest);

        signature = abi.encodePacked(r, s, v);
        vm.stopPrank();
    }

    function run(bytes32 digest) public {
        uint256 operatorPK = vm.envUint("OPERATOR_KEY");

        emit log_bytes(helper_sign(operatorPK, digest));
    }
}
