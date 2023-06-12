// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {console} from "@forge-std/console.sol";

import {Test} from "@forge-std/Test.sol";
import {Proxy} from "@main/universal/Proxy.sol";
import {ProxyAdmin} from "@main/universal/ProxyAdmin.sol";

import {Deployer, getDeployer} from "forge-deploy/Deployer.sol";
import {DeployProxyAdminScript} from "@script/000_DeployProxyAdmin.s.sol";
import {DeployL2OutputOracleProxyScript} from "@script/003_L2OutputOracleProxy.s.sol";

contract L2OutputOracleProxy_Test is Test {
    Deployer deployerProcedue;

    ProxyAdmin admin;
    Proxy l2OutputOracle;

    function setUp() external {
        deployerProcedue = getDeployer();
        deployerProcedue.setAutoBroadcast(false);

        DeployProxyAdminScript proxyAdminDeployments = new DeployProxyAdminScript();
        DeployL2OutputOracleProxyScript l2OutputOracleProxyDeployments = new DeployL2OutputOracleProxyScript();

        deployerProcedue.activatePrank(vm.envAddress("DEPLOYER"));

        // Deploy the proxy admin
        admin = proxyAdminDeployments.deploy();
        // Deploy the L2OutputOracleProxy
        l2OutputOracle = l2OutputOracleProxyDeployments.deploy();

        deployerProcedue.deactivatePrank();
    }

    function test_owner_succeeds() external {
        address proxyAdmin = deployerProcedue.getAddress("ProxyAdmin");

        vm.prank(proxyAdmin);

        assertEq(l2OutputOracle.admin(), proxyAdmin);
    }
}
