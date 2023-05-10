// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DeployerFunctions} from "generated/deployer/DeployerFunctions.g.sol";

import {AddressManager} from "src/legacy/AddressManager.sol";

contract DeployAddressManagerScript is  DeployScript {
    using DeployerFunctions for Deployer;

    address owner;

    function deploy() external returns (AddressManager) {

        return AddressManager(
			deployer.deploy_AddressManager(
				"Lib_AddressManager"
			)
		);
    }
}