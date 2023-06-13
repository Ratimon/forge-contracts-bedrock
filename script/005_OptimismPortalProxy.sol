// SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
import {DeployerFunctions} from "@generated/deployer/DeployerFunctions.g.sol";

import {ProxyAdmin} from "@main/universal/ProxyAdmin.sol";
import {Proxy} from "@main/universal/Proxy.sol";

contract DeployOptimismPortalProxyScript is DeployScript {
    using DeployerFunctions for Deployer;

    ProxyAdmin proxyAdmin;

    function deploy() external returns (Proxy) {
        proxyAdmin = ProxyAdmin(deployer.getAddress("ProxyAdmin"));

        return Proxy(
            deployer.deploy_Proxy(
                "OptimismPortalProxy", address(proxyAdmin)
            )
        );
    }
}
