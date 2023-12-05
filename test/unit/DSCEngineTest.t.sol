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
    address btcUsdPriceFeed;
    address weth;
    address wbtc;

    address public USER = makeAddr("USER");
    uint256 public constant AMMOUNT_COLLETRAL = 10 ether;
    uint256 public constant STARTING_ERC20_BALANCE = 10 ether;

    function setUp() public {
        deployer = new DeployDSC();
        (dsc, engine, config) = deployer.run();
        (ethUsdPriceFeed, btcUsdPriceFeed, weth, wbtc,) = config.activeNetworkConfig();
        if (block.chainid == 31337) {
            // vm.deal(USER, STARTING_USER_BALANCE);
            ERC20Mock(weth).mint(USER, STARTING_ERC20_BALANCE);
            ERC20Mock(wbtc).mint(USER, STARTING_ERC20_BALANCE);
        }
    }

    //////////////////
    // Modifier  ////
    ////////////////
    modifier depositedCollateral() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMMOUNT_COLLETRAL);
        engine.depositCollateral(weth, AMMOUNT_COLLETRAL);
        vm.stopPrank();
        _;
    }

    modifier depositedCollateralAndMinted() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMMOUNT_COLLETRAL);
        engine.depositCollateralAndMintDsc(weth, AMMOUNT_COLLETRAL, AMMOUNT_COLLETRAL);
        vm.stopPrank();
        _;
    }

    modifier approveToken() {
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMMOUNT_COLLETRAL);
        vm.stopPrank();
        _;
    }

    ///////////////////////////
    // Constructor  test  ////
    /////////////////////////

    address[] public tokenAddresses;
    address[] public priceFeedAddresses;

    function testRevertsIfTokenLengthDoesntMatchPriceFeeds() public {
        tokenAddresses.push(weth);
        priceFeedAddresses.push(ethUsdPriceFeed);
        priceFeedAddresses.push(btcUsdPriceFeed);
        vm.expectRevert(DSCEngine.DSCEngine__TokenAddressAndPriceFeedAddressesMustBeSameLength.selector);
        new DSCEngine(tokenAddresses, priceFeedAddresses, address(dsc));
    }

    ////////////////////
    // Price test  ////
    //////////////////

    function testGetUsdValue() public {
        uint256 ethAmount = 15e18;
        uint256 expectedUsd = 30000e18;
        uint256 usdValue = engine.getUsdValue(weth, ethAmount);
        assertEq(expectedUsd, usdValue);
    }

    function testgetTokenAmountFromUsd() public {
        uint256 usdAmount = 100 ether;
        uint256 expectedWeth = 0.05 ether;
        uint256 actualWeth = engine.getTokenAmountFromUsd(weth, usdAmount);
        assertEq(expectedWeth, actualWeth);
    }

    ///////////////////////////////
    // depositColletral test  ////
    /////////////////////////////

    function testRevertsIfCollateralZero() public {
        vm.startPrank(USER);

        vm.expectRevert(DSCEngine.DSCEngine__NeedMoreThanZero.selector);
        engine.depositCollateral(weth, 0);
        vm.stopPrank();
    }

    function testRevertIfTokenIsDiffrent() public {
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(0), 1);
        vm.stopPrank();
    }

    function testRevertsWithUnapprovedCollateral() public {
        ERC20Mock ranToken = new ERC20Mock("RAN", "RAN", USER, AMMOUNT_COLLETRAL);
        vm.startPrank(USER);
        vm.expectRevert(DSCEngine.DSCEngine__NotAllowedToken.selector);
        engine.depositCollateral(address(ranToken), AMMOUNT_COLLETRAL);
        vm.stopPrank();
    }

    function testCanDepositCollateralAndGetAccountInfo() public depositedCollateral {
        (uint256 totalDscMinted, uint256 collateralValueInUsd) = engine.getAccountInformation(USER);
        uint256 expectedDscMinted = 0;
        uint256 expectedDepositAmount = engine.getTokenAmountFromUsd(weth, collateralValueInUsd);
        assertEq(totalDscMinted, expectedDscMinted);
        assertEq(AMMOUNT_COLLETRAL, expectedDepositAmount);
    }

    function testDepositsCorrect() public depositedCollateral {
        uint256 accountDepositInStorage = engine.getCollateralDeposited(USER, weth);
        uint256 actualDepositAmount = AMMOUNT_COLLETRAL;
        assertEq(accountDepositInStorage, actualDepositAmount);
    }

    ///////////////////
    // mint test  ////
    /////////////////

    function testMintedAmountIsCorrect() public depositedCollateral {
        uint256 amountDscShouldMinted = AMMOUNT_COLLETRAL;
        vm.prank(USER);
        engine.mintDsc(AMMOUNT_COLLETRAL);
        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, amountDscShouldMinted);
    }

    /////////////////////////////
    // deposit & mint test  ////
    ///////////////////////////

    function testCanDepoistAndMint() public approveToken {
        uint256 amountDscShouldMinted = AMMOUNT_COLLETRAL;
        vm.prank(USER);
        engine.depositCollateralAndMintDsc(weth, AMMOUNT_COLLETRAL, AMMOUNT_COLLETRAL);
        uint256 userBalance = dsc.balanceOf(USER);
        assertEq(userBalance, amountDscShouldMinted);
    }

    function testRevertHealthfactorForDepositMint() public approveToken {
        uint256 toMuchDSCAmount = 20000000000000000000000;
        vm.startPrank(USER);

        uint256 expectedHealthFactor =
            engine.calculateHealthFactor(toMuchDSCAmount, engine.getUsdValue(weth, AMMOUNT_COLLETRAL));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        engine.depositCollateralAndMintDsc(weth, AMMOUNT_COLLETRAL, toMuchDSCAmount);
        vm.stopPrank();
    }

    function testRevertsIfMintedDscBreaksHealthFactor() public {
        (, int256 price,,,) = MockV3Aggregator(ethUsdPriceFeed).latestRoundData();
        uint256 amountToMint = (AMMOUNT_COLLETRAL * (uint256(price) * 1e10)) / 1e18;
        console.log(amountToMint);
        vm.startPrank(USER);
        ERC20Mock(weth).approve(address(engine), AMMOUNT_COLLETRAL);

        uint256 expectedHealthFactor =
            engine.calculateHealthFactor(amountToMint, engine.getUsdValue(weth, AMMOUNT_COLLETRAL));
        vm.expectRevert(abi.encodeWithSelector(DSCEngine.DSCEngine__BreaksHealthFactor.selector, expectedHealthFactor));
        engine.depositCollateralAndMintDsc(weth, AMMOUNT_COLLETRAL, amountToMint);
        vm.stopPrank();
    }

    //////////////////
    // burn test  ////
    /////////////////

    function testIfDSCCanBurn() public depositedCollateralAndMinted {
        uint256 amountToBeBurned = 10;
        uint256 dscAmountBeforeBurned = engine.getMintedDscAmountForAccount(USER);
        vm.startPrank(USER);
        dsc.approve(address(engine), amountToBeBurned);
        engine.burnDsc(amountToBeBurned);
        vm.stopPrank();
        uint256 dscAmountAfterBurned = engine.getMintedDscAmountForAccount(USER);
        assertEq(dscAmountBeforeBurned, dscAmountAfterBurned + amountToBeBurned);
    }

    /////////////////////////
    // Liqudation test  ////
    ///////////////////////

    function testLiquidationRevertHealthFactorOk() public depositedCollateralAndMinted {
        uint256 debtToCover = 1 ether;
        vm.startPrank(makeAddr("Liquidator"));
        vm.expectRevert(DSCEngine.DSCEngine__HealthFactorOk.selector);
        engine.liquidate(weth, USER, debtToCover);
        vm.stopPrank();
    }
}
