// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DeployerFunctions} from "@generated/deployer/DeployerFunctions.g.sol";
import { Proxy } from "@main/universal/Proxy.sol";

contract DeployL2OutputOracleProxyScript is DeployScript {
    using DeployerFunctions for Deployer;
    address proxyAdmin;

        function deploy() external returns (Proxy) {

        proxyAdmin = deployer.getAddress('ProxyAdmin');

        return Proxy(
			deployer.deploy_Proxy(
				"L2OutputOracleProxy",
				proxyAdmin
			)
		);
    }

}