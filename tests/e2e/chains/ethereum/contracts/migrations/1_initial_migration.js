const IBCClient = artifacts.require("@hyperledger-labs/yui-ibc-solidity/IBCClient");
const IBCConnection = artifacts.require("@hyperledger-labs/yui-ibc-solidity/IBCConnection");
const IBCChannelHandshake = artifacts.require("@hyperledger-labs/yui-ibc-solidity/IBCChannelHandshake");
const IBCPacket = artifacts.require("@hyperledger-labs/yui-ibc-solidity/IBCPacket");
const IBCHandler = artifacts.require("@hyperledger-labs/yui-ibc-solidity/OwnableIBCHandler");
const MockClient = artifacts.require("@hyperledger-labs/yui-ibc-solidity/MockClient");
const LCPProtoMarshaler = artifacts.require("@datachainlab/lcp-solidity/LCPProtoMarshaler");
const AVRValidator = artifacts.require("@datachainlab/lcp-solidity/AVRValidator");
const LCPClient = artifacts.require("@datachainlab/lcp-solidity/LCPClient");
const ERC20Token = artifacts.require("@hyperledger-labs/yui-ibc-solidity/ERC20Token");
const ICS20TransferBank = artifacts.require("@hyperledger-labs/yui-ibc-solidity/ICS20TransferBank");
const ICS20Bank = artifacts.require("@hyperledger-labs/yui-ibc-solidity/ICS20Bank");
const MockApp = artifacts.require("MockApp");

const PortMock = "mockapp"
const PortTransfer = "transfer"
const MockClientType = "mock-client"
const LCPClientType = "lcp-client"

module.exports = async (deployer) => {
  const fs = require('fs');
  var rootCert;
  if (process.env.SGX_MODE === "SW") {
    console.log("RA simulation is enabled");
    rootCert = fs.readFileSync("../config/simulation_rootca.der");
  } else {
    console.log("RA simulation is disabled");
    rootCert = fs.readFileSync("../config/Intel_SGX_Attestation_RootCA.der");
  }

  await deployer.deploy(IBCClient);
  await deployer.deploy(IBCConnection);
  await deployer.deploy(IBCChannelHandshake);
  await deployer.deploy(IBCPacket);
  await deployer.deploy(IBCHandler, IBCClient.address, IBCConnection.address, IBCChannelHandshake.address, IBCPacket.address);

  await deployer.deploy(MockClient, IBCHandler.address);

  await deployer.deploy(LCPProtoMarshaler);
  await deployer.deploy(AVRValidator);
  await deployer.link(LCPProtoMarshaler, LCPClient);
  await deployer.link(AVRValidator, LCPClient);

  await deployer.deploy(LCPClient, IBCHandler.address, rootCert, true);
  await deployer.deploy(MockApp, IBCHandler.address);
  await deployer.deploy(ERC20Token, "simple", "simple", 1_000_000_000_000);
  await deployer.deploy(ICS20Bank)
  await deployer.deploy(ICS20TransferBank, IBCHandler.address, ICS20Bank.address);

  const ibcHandler = await IBCHandler.deployed();

  for(const f of [
    () => ibcHandler.bindPort(PortMock, MockApp.address),
    () => ibcHandler.bindPort(PortTransfer, ICS20TransferBank.address),
    () => ibcHandler.registerClient(MockClientType, MockClient.address),
    () => ibcHandler.registerClient(LCPClientType, LCPClient.address)
  ]) {
    const result = await f();
    if(!result.receipt.status) {
      console.log(result);
      throw new Error(`transaction failed to execute. ${result.tx}`);
    }
  }
};
