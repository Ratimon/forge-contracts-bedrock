// // SPDX-License-Identifier: MIT
// pragma solidity =0.8.15;

// import {DeployScript, Deployer} from "forge-deploy/DeployScript.sol";
// import {DeployerFunctions} from "@generated/deployer/DeployerFunctions.g.sol";

// import {ProxyAdmin} from "@main/universal/ProxyAdmin.sol";
// // import {Proxy} from "@main/universal/Proxy.sol";

// import {OptimismPortal} from "@main/L1/OptimismPortal.sol";


// contract DeployOptimismPortalProxyScript is DeployScript {
//     using DeployerFunctions for Deployer;

//     ProxyAdmin proxyAdmin;

//     function deploy() external returns (OptimismPortal) {
//         proxyAdmin = AddressManager(deployer.getAddress("ProxyAdmin"));

//         return ResolvedDelegateProxy(
//             deployer.deploy_O
//                 "Proxy__OVM_L1CrossDomainMessenger", addressManager, "OVM_L1CrossDomainMessenger"
//             )
//         );
//     }
// }
