// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DeployerFunctions} from "generated/deployer/DeployerFunctions.g.sol";

import { L1ChugSplashProxy } from "src/legacy/L1ChugSplashProxy.sol";

contract DeployL1StandardBridgeProxyScript is DeployScript {
    using DeployerFunctions for Deployer;

    address owner;

    function deploy() external returns (L1ChugSplashProxy) {

        string memory mnemonic = vm.envString("MNEMONIC") ;
        uint256 ownerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8
        owner = vm.envOr("DEPLOYER", vm.addr(ownerPrivateKey));

        return L1ChugSplashProxy(
			deployer.deploy_L1ChugSplashProxy(
				"Proxy__OVM_L1StandardBridge",
                address(owner)
			)
		);
    }
}
