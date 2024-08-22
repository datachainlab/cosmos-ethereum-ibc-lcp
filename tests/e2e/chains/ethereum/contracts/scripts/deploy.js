const portMock = "mockapp";
const lcpClientType = "lcp-client";

function saveAddress(contractName, contract) {
  const fs = require("fs");
  const path = require("path");

  const dirpath = "addresses";
  if (!fs.existsSync(dirpath)) {
    fs.mkdirSync(dirpath, {recursive: true});
  }

  const filepath = path.join(dirpath, contractName);
  fs.writeFileSync(filepath, contract.target);

  console.log(`${contractName} address:`, contract.target);
}

async function deploy(deployer, contractName, args = []) {
  const factory = await hre.ethers.getContractFactory(contractName);
  const contract = await factory.connect(deployer).deploy(...args);
  await contract.waitForDeployment();
  return contract;
}

async function deployAndLink(deployer, contractName, libraries, args = []) {
  const factory = await hre.ethers.getContractFactory(contractName, {
    libraries: libraries
  });
  const contract = await factory.connect(deployer).deploy(...args);
  await contract.waitForDeployment();
  return contract;
}

async function deployIBC(deployer) {
  const logicNames = [
    "IBCClient",
    "IBCConnectionSelfStateNoValidation",
    "IBCChannelHandshake",
    "IBCChannelPacketSendRecv",
    "IBCChannelPacketTimeout",
    "IBCChannelUpgradeInitTryAck",
    "IBCChannelUpgradeConfirmOpenTimeoutCancel"
  ];
  const logics = [];
  for (const name of logicNames) {
    const logic = await deploy(deployer, name);
    logics.push(logic);
  }
  return deploy(deployer, "OwnableIBCHandler", logics.map(l => l.target));
}

async function main() {
  // This is just a convenience check
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network localhost'"
    );
  }

  const fs = require('fs');
  let rootCert;
  if (process.env.SGX_MODE === "SW") {
    console.log("RA simulation is enabled");
    rootCert = fs.readFileSync("../config/simulation_rootca.der");
  } else {
    console.log("RA simulation is disabled");
    rootCert = fs.readFileSync("../config/Intel_SGX_Attestation_RootCA.der");
  }

  // ethers is available in the global scope
  const [deployer] = await hre.ethers.getSigners();
  console.log(
    "Deploying the contracts with the account:",
    await deployer.getAddress()
  );
  console.log("Account balance:", (await hre.ethers.provider.getBalance(deployer.getAddress())).toString());

  const ibcHandler = await deployIBC(deployer);
  saveAddress("IBCHandler", ibcHandler)

  const lcpProtoMarshaler = await deploy(deployer, "LCPProtoMarshaler");
  saveAddress("LCPProtoMarshaler", lcpProtoMarshaler)
  const avrValidator = await deploy(deployer, "AVRValidator");
  saveAddress("AVRValidator", avrValidator)
  const lcpClient = await deployAndLink(deployer, "LCPClient", {
    LCPProtoMarshaler: lcpProtoMarshaler.target,
    AVRValidator: avrValidator.target
  }, [ibcHandler.target, true, rootCert]);
  saveAddress("LCPClient", lcpClient)
  await ibcHandler.registerClient(lcpClientType, lcpClient.target);

  const mockApp = await deploy(deployer, "IBCChannelUpgradableMockApp", [ibcHandler.target]);
  saveAddress("IBCChannelUpgradableMockApp", mockApp);

  await ibcHandler.bindPort(portMock, mockApp.target);
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

exports.deployIBC = deployIBC;
