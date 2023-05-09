// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

// import {StdUtils} from "forge-std/StdUtils.sol";

// import {StdUtils} from "./StdUtils.sol";


import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DefaultDeployerFunction} from "forge-deploy/DefaultDeployerFunction.sol";
import {DeployerFunctions} from "generated/deployer/DeployerFunctions.g.sol";


import {ProxyAdmin} from "src/universal/ProxyAdmin.sol";


contract DeployProxyAdminScript is  DeployScript {
    using DeployerFunctions for Deployer;

    address owner;

    function deploy() external returns (ProxyAdmin) {

        string memory mnemonic = vm.envString("MNEMONIC") ;
        uint256 deployerPrivateKey = vm.deriveKey(mnemonic, "m/44'/60'/0'/0/", 1); //  address = 0x70997970C51812dc3A010C7d01b50e0d17dc79C8

        owner = vm.envOr("DEPLOYER", vm.addr(deployerPrivateKey));

        return ProxyAdmin(
			deployer.deploy_ProxyAdmin(
				"ProxyAdmin",
				address(owner)
			)
		);
    }
}
