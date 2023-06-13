// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "@forge-std/console.sol";

import {Test} from "@forge-std/Test.sol";
import {Proxy} from "@main/universal/Proxy.sol";
import {ProxyAdmin} from "@main/universal/ProxyAdmin.sol";

import {Deployer, getDeployer} from "forge-deploy/Deployer.sol";
import {DeployProxyAdminScript} from "@script/000_DeployProxyAdmin.s.sol";
import {DeployOptimismPortalProxyScript} from "@script/005_DeployOptimismPortalProxy.s.sol";

contract OptimismPortalProxy_Test is Test {
    Deployer deployerProcedue;

    ProxyAdmin admin;
    Proxy optimismPortal;

    function setUp() external {
        deployerProcedue = getDeployer();
        deployerProcedue.setAutoBroadcast(false);

        DeployProxyAdminScript proxyAdminDeployments = new DeployProxyAdminScript();
        DeployOptimismPortalProxyScript optimismPortalProxyDeployments = new DeployOptimismPortalProxyScript();

        deployerProcedue.activatePrank(vm.envAddress("DEPLOYER"));

        // Deploy the proxy admin
        admin = proxyAdminDeployments.deploy();
        // Deploy the L2OutputOracleProxy
        optimismPortal = optimismPortalProxyDeployments.deploy();

        deployerProcedue.deactivatePrank();
    }

    function test_owner_succeeds() external {
        address proxyAdmin = deployerProcedue.getAddress("ProxyAdmin");

        vm.prank(proxyAdmin);

        assertEq(optimismPortal.admin(), proxyAdmin);
    }
}
