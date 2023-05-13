// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DeployerFunctions} from "@generated/deployer/DeployerFunctions.g.sol";

import {AddressManager} from "@main/legacy/AddressManager.sol";

contract DeployAddressManagerScript is  DeployScript {
    using DeployerFunctions for Deployer;

    function deploy() external returns (AddressManager) {

        return AddressManager(
			deployer.deploy_AddressManager(
				"Lib_AddressManager"
			)
		);
    }
}
