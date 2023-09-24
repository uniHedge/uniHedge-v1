// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import { Script } from "forge-std/Script.sol";

abstract contract BaseScript is Script {
    /// @dev The address of the deployer.
    address internal deployer;

    /// @dev The mnemonic used to derive the deployer's address.
    string internal mnemonic;

    constructor() {
        mnemonic = vm.envString("MNEMONIC");
        (deployer,) = deriveRememberKey({ mnemonic: mnemonic, index: 0 });
    }

    modifier broadcaster() {
        vm.startBroadcast(deployer);
        _;
        vm.stopBroadcast();
    }
}