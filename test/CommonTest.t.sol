// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/* Testing utilities */
import {Test, StdUtils} from "@forge-std/Test.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Types} from "@main/libraries/Types.sol";
import {Predeploys} from "@main/libraries/Predeploys.sol";

import {L2OutputOracle} from "@main/L1/L2OutputOracle.sol";
import {OptimismPortal} from "@main/L1/OptimismPortal.sol";
import {SystemConfig} from "@main/L1/SystemConfig.sol";
import {ResourceMetering} from "@main/L1/ResourceMetering.sol";
import {Constants} from "@main/libraries/Constants.sol";

import {L2ToL1MessagePasser} from "@main/L2/L2ToL1MessagePasser.sol";

import {Proxy} from "@main/universal/Proxy.sol";

contract CommonTest is Test {
    address alice = makeAddr("Alice");
    address bob = makeAddr("Alice");
    address multisig = makeAddr("Multisig");

    address immutable ZERO_ADDRESS = address(0);
    address immutable NON_ZERO_ADDRESS = address(1);
    uint256 immutable NON_ZERO_VALUE = 100;
    uint256 immutable ZERO_VALUE = 0;
    uint64 immutable NON_ZERO_GASLIMIT = 50000;
    bytes32 nonZeroHash = keccak256(abi.encode("NON_ZERO"));
    bytes NON_ZERO_DATA = hex"0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff0000";

    event TransactionDeposited(address indexed from, address indexed to, uint256 indexed version, bytes opaqueData);

    FFIInterface ffi;

    function setUp() public virtual {
        // Give alice and bob some ETH
        vm.deal(alice, 1 << 16);
        vm.deal(bob, 1 << 16);
        vm.deal(multisig, 1 << 16);

        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(multisig, "multisig");

        // Make sure we have a non-zero base fee
        vm.fee(1_000_000_000);

        ffi = new FFIInterface();
    }

    function emitTransactionDeposited(
        address _from,
        address _to,
        uint256 _mint,
        uint256 _value,
        uint64 _gasLimit,
        bool _isCreation,
        bytes memory _data
    ) internal {
        emit TransactionDeposited(_from, _to, 0, abi.encodePacked(_mint, _value, _gasLimit, _isCreation, _data));
    }
}

contract L2OutputOracle_Initializer is CommonTest {
    // Test target
    L2OutputOracle oracle;
    L2OutputOracle oracleImpl;

    L2ToL1MessagePasser messagePasser = L2ToL1MessagePasser(payable(Predeploys.L2_TO_L1_MESSAGE_PASSER));

    // Constructor arguments
    address internal proposer = 0x000000000000000000000000000000000000AbBa;
    address internal owner = 0x000000000000000000000000000000000000ACDC;
    uint256 internal submissionInterval = 1800;
    uint256 internal l2BlockTime = 2;
    uint256 internal startingBlockNumber = 200;
    uint256 internal startingTimestamp = 1000;
    address guardian;

    // Test data
    uint256 initL1Time;

    event OutputProposed(
        bytes32 indexed outputRoot, uint256 indexed l2OutputIndex, uint256 indexed l2BlockNumber, uint256 l1Timestamp
    );

    event OutputsDeleted(uint256 indexed prevNextOutputIndex, uint256 indexed newNextOutputIndex);

    // Advance the evm's time to meet the L2OutputOracle's requirements for proposeL2Output
    function warpToProposeTime(uint256 _nextBlockNumber) public {
        vm.warp(oracle.computeL2Timestamp(_nextBlockNumber) + 1);
    }

    function setUp() public virtual override {
        super.setUp();
        guardian = makeAddr("guardian");

        // By default the first block has timestamp and number zero, which will cause underflows in the
        // tests, so we'll move forward to these block values.
        initL1Time = startingTimestamp + 1;
        vm.warp(initL1Time);
        vm.roll(startingBlockNumber);
        // Deploy the L2OutputOracle and transfer owernship to the proposer
        oracleImpl = new L2OutputOracle({
            _submissionInterval: submissionInterval,
            _l2BlockTime: l2BlockTime,
            _startingBlockNumber: startingBlockNumber,
            _startingTimestamp: startingTimestamp,
            _proposer: proposer,
            _challenger: owner,
            _finalizationPeriodSeconds: 7 days
        });
        Proxy proxy = new Proxy(multisig);
        vm.prank(multisig);
        proxy.upgradeToAndCall(
            address(oracleImpl), abi.encodeCall(L2OutputOracle.initialize, (startingBlockNumber, startingTimestamp))
        );
        oracle = L2OutputOracle(address(proxy));
        vm.label(address(oracle), "L2OutputOracle");

        // Set the L2ToL1MessagePasser at the correct address
        vm.etch(Predeploys.L2_TO_L1_MESSAGE_PASSER, address(new L2ToL1MessagePasser()).code);

        vm.label(Predeploys.L2_TO_L1_MESSAGE_PASSER, "L2ToL1MessagePasser");
    }
}

contract Portal_Initializer is L2OutputOracle_Initializer {
    // Test target
    OptimismPortal internal opImpl;
    OptimismPortal internal op;
    SystemConfig systemConfig;

    event WithdrawalFinalized(bytes32 indexed withdrawalHash, bool success);
    event WithdrawalProven(bytes32 indexed withdrawalHash, address indexed from, address indexed to);

    function setUp() public virtual override {
        super.setUp();

        ResourceMetering.ResourceConfig memory config = Constants.DEFAULT_RESOURCE_CONFIG();

        systemConfig = new SystemConfig({
            _owner: address(1),
            _overhead: 0,
            _scalar: 10000,
            _batcherHash: bytes32(0),
            _gasLimit: 30_000_000,
            _unsafeBlockSigner: address(0),
            _config: config
        });

        opImpl = new OptimismPortal({
            _l2Oracle: oracle,
            _guardian: guardian,
            _paused: true,
            _config: systemConfig
        });

        Proxy proxy = new Proxy(multisig);
        vm.prank(multisig);
        proxy.upgradeToAndCall(address(opImpl), abi.encodeWithSelector(OptimismPortal.initialize.selector, false));
        op = OptimismPortal(payable(address(proxy)));
        vm.label(address(op), "OptimismPortal");
    }
}

contract FFIInterface is Test {
    function getProveWithdrawalTransactionInputs(Types.WithdrawalTransaction memory _tx)
        external
        returns (bytes32, bytes32, bytes32, bytes32, bytes[] memory)
    {
        string[] memory cmds = new string[](8);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "getProveWithdrawalTransactionInputs";
        cmds[2] = vm.toString(_tx.nonce);
        cmds[3] = vm.toString(_tx.sender);
        cmds[4] = vm.toString(_tx.target);
        cmds[5] = vm.toString(_tx.value);
        cmds[6] = vm.toString(_tx.gasLimit);
        cmds[7] = vm.toString(_tx.data);

        bytes memory result = vm.ffi(cmds);
        (
            bytes32 stateRoot,
            bytes32 storageRoot,
            bytes32 outputRoot,
            bytes32 withdrawalHash,
            bytes[] memory withdrawalProof
        ) = abi.decode(result, (bytes32, bytes32, bytes32, bytes32, bytes[]));

        return (stateRoot, storageRoot, outputRoot, withdrawalHash, withdrawalProof);
    }

    function hashCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) external returns (bytes32) {
        string[] memory cmds = new string[](8);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "hashCrossDomainMessage";
        cmds[2] = vm.toString(_nonce);
        cmds[3] = vm.toString(_sender);
        cmds[4] = vm.toString(_target);
        cmds[5] = vm.toString(_value);
        cmds[6] = vm.toString(_gasLimit);
        cmds[7] = vm.toString(_data);

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (bytes32));
    }

    function hashWithdrawal(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) external returns (bytes32) {
        string[] memory cmds = new string[](8);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "hashWithdrawal";
        cmds[2] = vm.toString(_nonce);
        cmds[3] = vm.toString(_sender);
        cmds[4] = vm.toString(_target);
        cmds[5] = vm.toString(_value);
        cmds[6] = vm.toString(_gasLimit);
        cmds[7] = vm.toString(_data);

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (bytes32));
    }

    function hashOutputRootProof(
        bytes32 _version,
        bytes32 _stateRoot,
        bytes32 _messagePasserStorageRoot,
        bytes32 _latestBlockhash
    ) external returns (bytes32) {
        string[] memory cmds = new string[](6);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "hashOutputRootProof";
        cmds[2] = Strings.toHexString(uint256(_version));
        cmds[3] = Strings.toHexString(uint256(_stateRoot));
        cmds[4] = Strings.toHexString(uint256(_messagePasserStorageRoot));
        cmds[5] = Strings.toHexString(uint256(_latestBlockhash));

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (bytes32));
    }

    function hashDepositTransaction(
        address _from,
        address _to,
        uint256 _mint,
        uint256 _value,
        uint64 _gas,
        bytes memory _data,
        uint64 _logIndex
    ) external returns (bytes32) {
        string[] memory cmds = new string[](10);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "hashDepositTransaction";
        cmds[2] = "0x0000000000000000000000000000000000000000000000000000000000000000";
        cmds[3] = vm.toString(_logIndex);
        cmds[4] = vm.toString(_from);
        cmds[5] = vm.toString(_to);
        cmds[6] = vm.toString(_mint);
        cmds[7] = vm.toString(_value);
        cmds[8] = vm.toString(_gas);
        cmds[9] = vm.toString(_data);

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (bytes32));
    }

    function encodeDepositTransaction(Types.UserDepositTransaction calldata txn) external returns (bytes memory) {
        string[] memory cmds = new string[](11);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "encodeDepositTransaction";
        cmds[2] = vm.toString(txn.from);
        cmds[3] = vm.toString(txn.to);
        cmds[4] = vm.toString(txn.value);
        cmds[5] = vm.toString(txn.mint);
        cmds[6] = vm.toString(txn.gasLimit);
        cmds[7] = vm.toString(txn.isCreation);
        cmds[8] = vm.toString(txn.data);
        cmds[9] = vm.toString(txn.l1BlockHash);
        cmds[10] = vm.toString(txn.logIndex);

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (bytes));
    }

    function encodeCrossDomainMessage(
        uint256 _nonce,
        address _sender,
        address _target,
        uint256 _value,
        uint256 _gasLimit,
        bytes memory _data
    ) external returns (bytes memory) {
        string[] memory cmds = new string[](8);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "encodeCrossDomainMessage";
        cmds[2] = vm.toString(_nonce);
        cmds[3] = vm.toString(_sender);
        cmds[4] = vm.toString(_target);
        cmds[5] = vm.toString(_value);
        cmds[6] = vm.toString(_gasLimit);
        cmds[7] = vm.toString(_data);

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (bytes));
    }

    function decodeVersionedNonce(uint256 nonce) external returns (uint256, uint256) {
        string[] memory cmds = new string[](3);
        cmds[0] = "test/differential-testing/differential-testing";
        cmds[1] = "decodeVersionedNonce";
        cmds[2] = vm.toString(nonce);

        bytes memory result = vm.ffi(cmds);
        return abi.decode(result, (uint256, uint256));
    }

    function getMerkleTrieFuzzCase(string memory variant)
        external
        returns (bytes32, bytes memory, bytes memory, bytes[] memory)
    {
        string[] memory cmds = new string[](5);
        cmds[0] = "test/test-case-generator/fuzz";
        cmds[1] = "-m";
        cmds[2] = "trie";
        cmds[3] = "-v";
        cmds[4] = variant;

        return abi.decode(vm.ffi(cmds), (bytes32, bytes, bytes, bytes[]));
    }
}
