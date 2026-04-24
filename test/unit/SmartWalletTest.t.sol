// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {SmartWallet} from "src/SmartWallet.sol";
import {DeploySmartWallet} from "script/DeploySmartWallet.s.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {SendPackedUserOp, PackedUserOperation, IEntryPoint} from "script/SendPackedUserOp.s.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "lib/account-abstraction/contracts/core/Helpers.sol";
import {MessageHashUtils} from "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

contract SmartWalletTest is Test {
    /* Library usage */
    using MessageHashUtils for bytes32;

    /* Instantiate contracts */
    HelperConfig helperConfig;
    SmartWallet smartWallet;
    ERC20Mock usdc;
    SendPackedUserOp sendPackedUserOp;

    /* State variables */
    uint256 private constant AMOUNT = 1e18;
    address user = makeAddr("user");

    /* Set up function */
    function setUp() external {
        DeploySmartWallet deployer = new DeploySmartWallet();
        (helperConfig, smartWallet) = deployer.run();
        usdc = new ERC20Mock();
        sendPackedUserOp = new SendPackedUserOp();
    }

    /* Testing functions */
    function testOwnerCanExecute() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);

        vm.prank(smartWallet.owner());
        smartWallet.execute(dest, value, functionData);

        assertEq(usdc.balanceOf(address(smartWallet)), AMOUNT);
    }

    function testNonOwnerCannotExecute() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);

        vm.prank(user);
        vm.expectRevert(SmartWallet.SmartWallet__NotFromEntryPointOrOwner.selector);

        smartWallet.execute(dest, value, functionData);
    }

    function testEntryPointCanExecuteViaHandleOps() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        bytes memory executeData = abi.encodeWithSelector(SmartWallet.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateUserOperation(executeData, helperConfig.getConfig(), address(smartWallet));

        vm.deal(address(smartWallet), 1e18);

        PackedUserOperation[] memory ops = new PackedUserOperation[](1);
        ops[0] = packedUserOp;

        //vm.prank(user);
        IEntryPoint(helperConfig.getConfig().entryPoint).handleOps(ops, payable(user));

        assertEq(usdc.balanceOf(address(smartWallet)), AMOUNT);
    }

    function testWalletCanReceive() public {
        vm.deal(address(smartWallet), 1 ether);
        assertEq(address(smartWallet).balance, 1 ether);
    }

    function testValidateUserOpReturnsSuccessForValidSignature() public {
        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        bytes memory executeData = abi.encodeWithSelector(SmartWallet.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateUserOperation(executeData, helperConfig.getConfig(), address(smartWallet));

        bytes32 userOperationHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);
        uint256 missingAccountFunds = 1e18;

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = smartWallet.validateUserOp(packedUserOp, userOperationHash, missingAccountFunds);
        assertEq(validationData, 0);
    }

    function testValidateUserOpRevertsIfCallerIsNotEntryPoint() public {
        PackedUserOperation memory emptyOp;
        bytes32 emptyHash;

        vm.prank(user);
        vm.expectRevert(SmartWallet.SmartWallet__NotFromEntryPoint.selector);
        smartWallet.validateUserOp(emptyOp, emptyHash, 0);
    }

    function testFuzz_ValidateUserOpWithRandomKey(uint256 privateKey) public {
        privateKey = bound(privateKey, 1, type(uint96).max);
        address derivedUser = vm.addr(privateKey);

        address dest = address(usdc);
        uint256 value = 0;
        bytes memory functionData = abi.encodeWithSelector(ERC20Mock.mint.selector, address(smartWallet), AMOUNT);
        bytes memory executeData = abi.encodeWithSelector(SmartWallet.execute.selector, dest, value, functionData);

        PackedUserOperation memory packedUserOp =
            sendPackedUserOp.generateUserOperation(executeData, helperConfig.getConfig(), address(smartWallet));

        bytes32 userOpHash = IEntryPoint(helperConfig.getConfig().entryPoint).getUserOpHash(packedUserOp);

        bytes32 digest = userOpHash.toEthSignedMessageHash();
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        packedUserOp.signature = abi.encodePacked(r, s, v);

        vm.prank(helperConfig.getConfig().entryPoint);
        uint256 validationData = smartWallet.validateUserOp(packedUserOp, userOpHash, 0);

        if (derivedUser == smartWallet.owner()) {
            assertEq(validationData, SIG_VALIDATION_SUCCESS);
        } else {
            assertEq(validationData, SIG_VALIDATION_FAILED);
        }
    }
}
