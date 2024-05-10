// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.12;

import {Height} from "@hyperledger-labs/yui-ibc-solidity/contracts/proto/Client.sol";
import {Packet} from "@hyperledger-labs/yui-ibc-solidity/contracts/core/04-channel/IIBCChannel.sol";
import {IIBCHandler} from "@hyperledger-labs/yui-ibc-solidity/contracts/core/25-handler/IIBCHandler.sol";
import {IIBCModule} from "@hyperledger-labs/yui-ibc-solidity/contracts/core/26-router/IIBCModule.sol";
import {IBCAppBase} from "@hyperledger-labs/yui-ibc-solidity/contracts/apps/commons/IBCAppBase.sol";

contract MockApp is IBCAppBase {
    string public constant MOCKAPP_VERSION = "mockapp-1";

    IIBCHandler immutable ibcHandler;

    constructor(IIBCHandler ibcHandler_) {
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

    function onRecvPacket(Packet calldata packet, address relayer)
        external
        virtual
        override
        onlyIBC
        returns (bytes memory acknowledgement)
    {
        return packet.data;
    }

    function onAcknowledgementPacket(Packet calldata packet, bytes calldata acknowledgement, address relayer)
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
