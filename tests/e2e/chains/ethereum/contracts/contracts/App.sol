// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.20;

import {IIBCHandler} from "@hyperledger-labs/yui-ibc-solidity/contracts/core/25-handler/IIBCHandler.sol";
import {IBCContractUpgradableUUPSMockApp} from "@datachainlab/ethereum-ibc-relay-chain/contracts/IBCContractUpgradableUUPSMockApp.sol";

contract AppV1 is IBCContractUpgradableUUPSMockApp {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) IBCContractUpgradableUUPSMockApp(ibcHandler_) {}

    function __AppV1_init(string memory initialVersion) public initializer {
        __IBCContractUpgradableUUPSMockApp_init(initialVersion);
    }
}

contract AppV2 is AppV1 {
    string public val2;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) AppV1(ibcHandler_) {}

    function __AppV2_init(string memory v_) public reinitializer(2) {
        val2 = v_;
    }
}

contract AppV3 is AppV2 {
    string public val3;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) AppV2(ibcHandler_) {}

    function __AppV3_init(string memory v_) public reinitializer(3) {
        val3 = v_;
    }
}

contract AppV4 is AppV3 {
    string public val4;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) AppV3(ibcHandler_) {}

    function __AppV4_init(string memory v_) public reinitializer(4) {
        val4 = v_;
    }
}

contract AppV5 is AppV4 {
    string public val5;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) AppV4(ibcHandler_) {}

    function __AppV5_init(string memory v_) public reinitializer(5) {
        val5 = v_;
    }
}

contract AppV6 is AppV5 {
    string public val6;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) AppV5(ibcHandler_) {}

    function __AppV6_init(string memory v_) public reinitializer(6) {
        val6 = v_;
    }
}

contract AppV7 is AppV6 {
    string public val7;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor(IIBCHandler ibcHandler_) AppV6(ibcHandler_) {}

    function __AppV7_init(string memory v_) public reinitializer(7) {
        val7 = v_;
    }
}
