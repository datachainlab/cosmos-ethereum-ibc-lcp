// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.9;

import "@hyperledger-labs/yui-ibc-solidity/contracts/core/25-handler/IBCHandler.sol";
import "@hyperledger-labs/yui-ibc-solidity/contracts/apps/commons/IBCAppBase.sol";

contract MockApp is IBCAppBase {
    string public constant MOCKAPP_VERSION = "mockapp-1";

    IBCHandler ibcHandler;

    constructor(IBCHandler ibcHandler_) {
        ibcHandler = ibcHandler_;
    }

    function ibcAddress() public view virtual override returns (address) {
        return address(ibcHandler);
    }

    function sendPacket(
        string calldata message,
        string calldata sourcePort,
        string calldata sourceChannel,
        uint64 timeoutHeight,
        uint64 timeoutTimestamp
    ) external {
        ibcHandler.sendPacket(
            sourcePort,
            sourceChannel,
            Height.Data({revision_number: 0, revision_height: timeoutHeight}),
            0,
            bytes(message)
        );
    }

    function onRecvPacket(Packet.Data calldata packet, address relayer)
        external
        virtual
        override
        onlyIBC
        returns (bytes memory acknowledgement)
    {
        return packet.data;
    }

    function onAcknowledgementPacket(Packet.Data calldata packet, bytes calldata acknowledgement, address relayer)
        external
        virtual
        override
        onlyIBC
    {
        require(keccak256(packet.data) == keccak256(acknowledgement), "message mismatch");
    }

    function onChanOpenInit(IIBCModule.MsgOnChanOpenInit calldata msg_)
        external
        virtual
        override
        onlyIBC
        returns (string memory)
    {
        require(
            bytes(msg_.version).length == 0 || keccak256(bytes(msg_.version)) == keccak256(bytes(MOCKAPP_VERSION)),
            "version mismatch"
        );
        return MOCKAPP_VERSION;
    }

    function onChanOpenTry(IIBCModule.MsgOnChanOpenTry calldata msg_)
        external
        virtual
        override
        onlyIBC
        returns (string memory)
    {
        require(keccak256(bytes(msg_.counterpartyVersion)) == keccak256(bytes(MOCKAPP_VERSION)), "version mismatch");
        return MOCKAPP_VERSION;
    }
}
