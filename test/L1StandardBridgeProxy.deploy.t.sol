// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

// import {console} from "@forge-std/console.sol";

import {Test} from "@forge-std/Test.sol";

import {L1ChugSplashProxy} from "@main/legacy/L1ChugSplashProxy.sol";

import {Deployer, getDeployer} from "forge-deploy/Deployer.sol";
import {DeployL1StandardBridgeProxyScript} from "@script/002_DeployL1StandardBridgeProxy.s.sol";

contract L1StandardBridgeProxy_Test is Test {
    Deployer deployerProcedue;

    L1ChugSplashProxy l1StandardBridge;

    function setUp() external {
        deployerProcedue = getDeployer();
        deployerProcedue.setAutoBroadcast(false);

        DeployL1StandardBridgeProxyScript l1StandardBridgeProxyDeployments = new DeployL1StandardBridgeProxyScript();

        deployerProcedue.activatePrank(vm.envAddress("DEPLOYER"));

        // Deploy the L2OutputOracleProxy
        l1StandardBridge = l1StandardBridgeProxyDeployments.deploy();

        deployerProcedue.deactivatePrank();
    }

    function test_owner_succeeds() external {
        address owner = vm.envAddress("DEPLOYER");

        vm.prank(owner);

        assertEq(l1StandardBridge.getOwner(), owner);
    }
}
