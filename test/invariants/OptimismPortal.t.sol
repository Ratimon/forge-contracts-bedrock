// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import {StdUtils} from "@forge-std/StdUtils.sol";
import {Vm} from "@forge-std/Vm.sol";
// import {console } from "@forge-std/console.sol";


// import {SystemConfig} from "@main/L1/SystemConfig.sol";
import {OptimismPortal} from "@main/L1/OptimismPortal.sol";
import {L2OutputOracle} from "@main/L1/L2OutputOracle.sol";
import {AddressAliasHelper} from "@main/vendor/AddressAliasHelper.sol";
import {SystemConfig} from "@main/L1/SystemConfig.sol";
import {ResourceMetering} from "@main/L1/ResourceMetering.sol";
import {Constants} from "@main/libraries/Constants.sol";

import {Portal_Initializer} from "@test/CommonTest.t.sol";
import {Types} from "@main/libraries/Types.sol";

contract OptimismPortal_Depositor is StdUtils, ResourceMetering {
    Vm internal vm;
    OptimismPortal internal portal;
    bool public failedToComplete;

    constructor(Vm _vm, OptimismPortal _portal) {
        vm = _vm;
        portal = _portal;
        initialize();
    }


    function initialize() internal initializer {
        __ResourceMetering_init();
    }

    function resourceConfig() public pure returns (ResourceMetering.ResourceConfig memory) {
        return _resourceConfig();
    }

    function _resourceConfig() internal pure override returns (ResourceMetering.ResourceConfig memory) {
        ResourceMetering.ResourceConfig memory rcfg = Constants.DEFAULT_RESOURCE_CONFIG();
        return rcfg;
    }

    // A test intended to identify any unexpected halting conditions
    function depositTransactionCompletes(
        address _to,
        // uint256 _mint,
        uint256 _value,
        uint64 _gasLimit,
        bool _isCreation,
        bytes memory _data
    ) public payable {
        // failedToComplete = true;
        // require(!_isCreation || _to == address(0), "OptimismPortal_Depositor: invalid test case.");
        // portal.depositTransaction{value: _mint}(_to, _value, _gasLimit, _isCreation, _data);
        // failedToComplete = false;

        
        // function _resourceConfig() internal view override returns (ResourceMetering.ResourceConfig memory) {
        //     return SYSTEM_CONFIG.resourceConfig();
        // }
    

        // failedToComplete = true;

        vm.assume(_isCreation == false || _to == address(0));
        require(!_isCreation || _to == address(0), "OptimismPortal_Depositor: invalid test case.");

        uint256 preDepositvalue = bound(_value, 0, type(uint128).max);
        // Give the depositor some ether
        vm.deal(address(this), preDepositvalue);
        // cache the contract's eth balance
        uint256 preDepositBalance = address(this).balance;

        uint256 value = bound(preDepositvalue, 0, preDepositBalance);

        // _resourceConfig
        // struct ResourceParams {
        //     uint128 prevBaseFee;
        //     uint64 prevBoughtGas;
        //     uint64 prevBlockNum;
        // }
    

        // ResourceMetering.ResourceConfig memory rcfg = resourceConfig();
        // ResourceMetering.ResourceParams memory rcfg =  ResourceMetering(address(portal)).params;
    //    (,uint64 cachedPrevBoughtGas, uint64 cachedPrevBlockNum) =  ResourceMetering(address(portal)).params();
       (,uint64 cachedPrevBoughtGas,) =  ResourceMetering(address(portal)).params();


        // uint256 targetResourceLimit = uint256(rcfg.maxResourceLimit);

        // uint256 blockDiff = block.number - rcfg.prevBlockNum;
        // uint256 blockDiff = block.number - cachedPrevBlockNum;

        // uint64 prevBoughtGas;


        // if (blockDiff > 0) {
        //     // prevBoughtGas =  rcfg.prevBoughtGas;
        //     prevBoughtGas =  cachedPrevBoughtGas;

        //     // params.prevBoughtGas = 0;
        //     // params.prevBlockNum = uint64(block.number);
        // }

        // prevBoughtGas = 0;

        // console.log('cachedPrevBoughtGas', cachedPrevBoughtGas);
        // console.log('cachedPrevBlockNum', cachedPrevBlockNum);
        // console.log('block.number', block.number);

        ResourceMetering.ResourceConfig memory rcfg = resourceConfig();
        uint256 maxResourceLimit = uint64(rcfg.maxResourceLimit);


        uint64 gasLimit = uint64(bound(_gasLimit, portal.minimumGasLimit(uint64(_data.length)), maxResourceLimit - cachedPrevBoughtGas));
        // require(_gasLimit >= minimumGasLimit(uint64(_data.length)), "OptimismPortal: gas limit too small");

        // require(
        //     int256(uint256(params.prevBoughtGas)) <= int256(uint256(config.maxResourceLimit)),
        //     "ResourceMetering: cannot buy more gas than available gas limit"
        // );


        vm.assume(_data.length <= 120_000);



        // int256(uint256(config.maxResourceLimit))



        try portal.depositTransaction{ value: value }(_to, value, gasLimit, _isCreation, _data) {
            // Do nothing; Call succeeded
            // failedToComplete = false;
        } catch {
            failedToComplete = true;
        }

    }


}

contract OptimismPortal_Invariant_Harness is Portal_Initializer {
    // Reusable default values for a test withdrawal
    Types.WithdrawalTransaction _defaultTx;

    uint256 _proposedOutputIndex;
    uint256 _proposedBlockNumber;
    bytes32 _stateRoot;
    bytes32 _storageRoot;
    bytes32 _outputRoot;
    bytes32 _withdrawalHash;
    bytes[] _withdrawalProof;
    Types.OutputRootProof internal _outputRootProof;

    function setUp() public virtual override {
        super.setUp();

        _defaultTx = Types.WithdrawalTransaction({
            nonce: 0,
            sender: alice,
            target: bob,
            value: 100,
            gasLimit: 100_000,
            data: hex""
        });
        // Get withdrawal proof data we can use for testing.
        (_stateRoot, _storageRoot, _outputRoot, _withdrawalHash, _withdrawalProof) =
            ffi.getProveWithdrawalTransactionInputs(_defaultTx);

        // Setup a dummy output root proof for reuse.
        _outputRootProof = Types.OutputRootProof({
            version: bytes32(uint256(0)),
            stateRoot: _stateRoot,
            messagePasserStorageRoot: _storageRoot,
            latestBlockhash: bytes32(uint256(0))
        });
        _proposedBlockNumber = oracle.nextBlockNumber();
        _proposedOutputIndex = oracle.nextOutputIndex();

        // Configure the oracle to return the output root we've prepared.
        vm.warp(oracle.computeL2Timestamp(_proposedBlockNumber) + 1);
        vm.prank(oracle.PROPOSER());
        oracle.proposeL2Output(_outputRoot, _proposedBlockNumber, 0, 0);

        // Warp beyond the finalization period for the block we've proposed.
        vm.warp(oracle.getL2Output(_proposedOutputIndex).timestamp + oracle.FINALIZATION_PERIOD_SECONDS() + 1);
        // Fund the portal so that we can withdraw ETH.
        vm.deal(address(op), 0xFFFFFFFF);
    }
}

contract OptimismPortal_Deposit_Invariant is Portal_Initializer {
    OptimismPortal_Depositor internal actor;

    function setUp() public override {
        super.setUp();
        // Create a deposit actor.
        actor = new OptimismPortal_Depositor(vm,op);

        targetContract(address(actor));

        bytes4[] memory selectors = new bytes4[](1);
        selectors[0] = actor.depositTransactionCompletes.selector;
        FuzzSelector memory selector = FuzzSelector({addr: address(actor), selectors: selectors});
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

contract OptimismPortal_CannotTimeTravel is OptimismPortal_Invariant_Harness {
    function setUp() public override {
        super.setUp();

        // Prove the withdrawal transaction
        op.proveWithdrawalTransaction(_defaultTx, _proposedOutputIndex, _outputRootProof, _withdrawalProof);

        // Set the target contract to the portal proxy
        targetContract(address(op));
        // Exclude the proxy multisig from the senders so that the proxy cannot be upgraded
        excludeSender(address(multisig));
    }

    /**
     * @custom:invariant `finalizeWithdrawalTransaction` should revert if the finalization
     * period has not elapsed.
     *
     * A withdrawal that has been proven should not be able to be finalized until after
     * the finalization period has elapsed.
     */
    function invariant_cannotFinalizeBeforePeriodHasPassed() external {
        vm.expectRevert("OptimismPortal: proven withdrawal finalization period has not elapsed");
        op.finalizeWithdrawalTransaction(_defaultTx);
    }
}

contract OptimismPortal_CannotFinalizeTwice is OptimismPortal_Invariant_Harness {
    function setUp() public override {
        super.setUp();

        // Prove the withdrawal transaction
        op.proveWithdrawalTransaction(_defaultTx, _proposedOutputIndex, _outputRootProof, _withdrawalProof);

        // Warp past the finalization period.
        vm.warp(block.timestamp + oracle.FINALIZATION_PERIOD_SECONDS() + 1);

        // Finalize the withdrawal transaction.
        op.finalizeWithdrawalTransaction(_defaultTx);

        // Set the target contract to the portal proxy
        targetContract(address(op));
        // Exclude the proxy multisig from the senders so that the proxy cannot be upgraded
        excludeSender(address(multisig));
    }

    /**
     * @custom:invariant `finalizeWithdrawalTransaction` should revert if the withdrawal
     * has already been finalized.
     *
     * Ensures that there is no chain of calls that can be made that allows a withdrawal
     * to be finalized twice.
     */
    function invariant_cannotFinalizeTwice() external {
        vm.expectRevert("OptimismPortal: withdrawal has already been finalized");
        op.finalizeWithdrawalTransaction(_defaultTx);
    }
}

contract OptimismPortal_CanAlwaysFinalizeAfterWindow is OptimismPortal_Invariant_Harness {
    function setUp() public override {
        super.setUp();

        // Prove the withdrawal transaction
        op.proveWithdrawalTransaction(_defaultTx, _proposedOutputIndex, _outputRootProof, _withdrawalProof);

        // Warp past the finalization period.
        vm.warp(block.timestamp + oracle.FINALIZATION_PERIOD_SECONDS() + 1);

        // Set the target contract to the portal proxy
        targetContract(address(op));
        // Exclude the proxy multisig from the senders so that the proxy cannot be upgraded
        excludeSender(address(multisig));
    }

    /**
     * @custom:invariant A withdrawal should **always** be able to be finalized
     * `FINALIZATION_PERIOD_SECONDS` after it was successfully proven.
     *
     * This invariant asserts that there is no chain of calls that can be made that
     * will prevent a withdrawal from being finalized exactly `FINALIZATION_PERIOD_SECONDS`
     * after it was successfully proven.
     */
    function invariant_canAlwaysFinalize() external {
        uint256 bobBalanceBefore = address(bob).balance;

        op.finalizeWithdrawalTransaction(_defaultTx);

        assertEq(address(bob).balance, bobBalanceBefore + _defaultTx.value);
    }
}
