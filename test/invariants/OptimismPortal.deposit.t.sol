// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {Test} from "@forge-std/Test.sol";
import {StdInvariant} from "@forge-std/StdInvariant.sol";

import { OptimismPortal } from "@main/L1/OptimismPortal.sol";
import { L2OutputOracle } from "@main/L1/L2OutputOracle.sol";
import { AddressAliasHelper } from "@main/vendor/AddressAliasHelper.sol";
import { SystemConfig } from "@main/L1/SystemConfig.sol";
import { ResourceMetering } from "@main/L1/ResourceMetering.sol";
import { Constants } from "@main/libraries/Constants.sol";

contract OptimismPortal_Depositor {
    OptimismPortal internal portal;
    bool public failedToComplete;

    constructor(OptimismPortal _portal) {
        portal = _portal;
    }

    // A test intended to identify any unexpected halting conditions
    function depositTransactionCompletes(
        address _to,
        uint256 _mint,
        uint256 _value,
        uint64 _gasLimit,
        bool _isCreation,
        bytes memory _data
    ) public payable {
        failedToComplete = true;
        require(!_isCreation || _to == address(0), "OptimismPortal_Depositor: invalid test case.");
        portal.depositTransaction{ value: _mint }(_to, _value, _gasLimit, _isCreation, _data);
        failedToComplete = false;
    }

}

contract OptimismPortal_Deposit_Invariant is StdInvariant, Test {
    OptimismPortal_Depositor internal actor;

    function setUp() public {

        ResourceMetering.ResourceConfig memory rcfg = Constants.DEFAULT_RESOURCE_CONFIG();
        SystemConfig systemConfig = new SystemConfig({
            _owner: address(1),
            _overhead: 0,
            _scalar: 10000,
            _batcherHash: bytes32(0),
            _gasLimit: 30_000_000,
            _unsafeBlockSigner: address(0),
            _config: rcfg
        });

        OptimismPortal portal = new OptimismPortal({
            _l2Oracle: L2OutputOracle(address(0)),
            _guardian: address(0),
            _paused: false,
            _config: systemConfig
        });

        // Create a deposit actor.
        actor = new OptimismPortal_Depositor(portal);

        targetContract(address(actor));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = actor.depositTransactionCompletes.selector;
        FuzzSelector memory selector = FuzzSelector({ addr: address(actor), selectors: selectors });
        targetSelector(selector);
    }

    /**
     * @custom:invariant Deposits of any value should always succeed unless
     * `_to` = `address(0)` or `_isCreation` = `true`.
     *
     * All deposits, barring creation transactions and transactions sent to `address(0)`,
     * should always succeed.
     */
    function invariant_deposit_completes() external {
        assertEq(actor.failedToComplete(), false);
    }
}
    
