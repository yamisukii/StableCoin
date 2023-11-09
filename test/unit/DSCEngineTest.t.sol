// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {MockV3Aggregator} from "../mocks/MockV3Aggregator.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/ERC20Mock.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";
import {DecentralizedStableCoin} from "../../src/DecentralizedStableCoin.sol";
import {DeployDSC} from "../../script/DeployDSC.s.sol";
import {HelperConfig} from "../../script/HelperConfig.s.sol";

contract DSCEngineTest is Test {
    DeployDSC deployer;
    DecentralizedStableCoin dsc;
    DSCEngine engine;
    HelperConfig config;
    address ethUsdPriceFeed;
    address weth;
    address wbtc;

    address public user = makeAddr("user");
    uint256 public constant AMMOUNT_COLLETRAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed,, weth, wbtc,) = config.activeNetworkConfig();
        if (block.chainid == 31337) {
            // vm.deal(user, STARTING_USER_BALANCE);
            ERC20Mock(weth).mint(user, STARTING_ERC20_BALANCE);
            ERC20Mock(wbtc).mint(user, STARTING_ERC20_BALANCE);
        }
    }

    /////////////////////
    // Price test  ////
    ///////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 usdValue = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, usdValue);
        console.log(usdValue);
    }

    ///////////////////////////////
    // depositColletral test  ////
    /////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(user);

        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertIfTokenIsDiffrent() public {
        vm.startPrank(user);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(0), 1);
        vm.stopPrank();
    }

    function testCanColleteralBeDeposit() public {
        vm.startPrank(user);
        ERC20Mock(weth).approve(address(engine), 5);
        engine.depositCollateral(weth, 5);
        uint256 depositedColletral = engine.getCollateralDeposited(user, weth);
        assertEq(5, depositedColletral);
        vm.stopPrank();
    }
}
