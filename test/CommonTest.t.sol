// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

/* Testing utilities */
import { Test, StdUtils } from "@forge-std/Test.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { Types } from "@main/libraries/Types.sol";


contract CommonTest is Test {


    address alice = makeAddr('Alice');
    // address alice = address(128);
    address bob = makeAddr('Alice');
    // address bob = address(256);
    address multisig = makeAddr('Multisig');
    //  address multisig = address(512);

    address immutable ZERO_ADDRESS = address(0);
    address immutable NON_ZERO_ADDRESS = address(1);
    uint256 immutable NON_ZERO_VALUE = 100;
    uint256 immutable ZERO_VALUE = 0;
    uint64 immutable NON_ZERO_GASLIMIT = 50000;
    bytes32 nonZeroHash = keccak256(abi.encode("NON_ZERO"));
    bytes NON_ZERO_DATA = hex"0000111122223333444455556666777788889999aaaabbbbccccddddeeeeffff0000";

    event TransactionDeposited(
        address indexed from,
        address indexed to,
        uint256 indexed version,
        bytes opaqueData
    );

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
        emit TransactionDeposited(
            _from,
            _to,
            0,
            abi.encodePacked(_mint, _value, _gasLimit, _isCreation, _data)
        );
    }
    
}

contract FFIInterface is Test {
    function getProveWithdrawalTransactionInputs(Types.WithdrawalTransaction memory _tx)
        external
        returns (
            bytes32,
            bytes32,
            bytes32,
            bytes32,
            bytes[] memory
        )
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

    function encodeDepositTransaction(Types.UserDepositTransaction calldata txn)
        external
        returns (bytes memory)
    {
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
        returns (
            bytes32,
            bytes memory,
            bytes memory,
            bytes[] memory
        )
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