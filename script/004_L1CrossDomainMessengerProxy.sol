// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DeployerFunctions} from "@generated/deployer/DeployerFunctions.g.sol";

import {AddressManager} from "@main/legacy/AddressManager.sol";
import { ResolvedDelegateProxy } from "@main/legacy/ResolvedDelegateProxy.sol";

contract DeployL1CrossDomainMessengerProxyScript is DeployScript {
    using DeployerFunctions for Deployer;
    AddressManager addressManager;

    function deploy() external returns (ResolvedDelegateProxy) {

        addressManager = AddressManager(deployer.getAddress('Lib_AddressManager'));
        
        return ResolvedDelegateProxy(
			deployer.deploy_ResolvedDelegateProxy(
				"Proxy__OVM_L1CrossDomainMessenger",
				addressManager,
                'OVM_L1CrossDomainMessenger'
			)
		);
    }

}