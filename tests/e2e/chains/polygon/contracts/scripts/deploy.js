const portMock = "mockapp";
// lcp-go's relay module emits "lcp-client-zkdcap" as the IBC client type
// regardless of whether the on-chain implementation is IAS or zkDCAP — it's a
// fixed identifier, not a build-mode discriminator. Registering anything else
// here causes MsgCreateClient to revert with IBCClientUnregisteredClientType.
const lcpClientType = "lcp-client-zkdcap";

// The relayer's HD signer (configs/templates/ibc-1.json.tpl) derives this
// address from `math razor capable expose worth grape metal sunset metal sudden
// usage scheme` at m/44'/60'/0'/0/0. Kurtosis-pos only prefunds its admin
// account; we fund the relayer EOA out of the admin so HD-signer txs can pay
// gas.
const relayerEoa = "0xa89F47C6b463f74d87572b058427dA0A13ec5425";
const relayerFundingEth = "100";

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

async function deployLCPClientIAS(deployer, ibcHandler, developMode, rootCert) {
  const lcpProtoMarshaler = await deploy(deployer, "LCPProtoMarshaler");
  saveAddress("LCPProtoMarshaler", lcpProtoMarshaler);
  const avrValidator = await deploy(deployer, "AVRValidator");
  saveAddress("AVRValidator", avrValidator);
  const lcpClient = await deployAndLink(deployer, "LCPClientIAS", {
    LCPProtoMarshaler: lcpProtoMarshaler.target,
    AVRValidator: avrValidator.target
  }, [ibcHandler.target, developMode, rootCert]);
  saveAddress("LCPClient", lcpClient);
  return lcpClient;
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

async function deployProxy(deployer, contractName, constructorArgs, unsafeAllow, initializer, initialArgs) {
  const factory = await hre.ethers.getContractFactory(contractName).then(f => f.connect(deployer));
  const proxyOptions = {
    txOverrides: {},
    unsafeAllow: unsafeAllow ?? [],
    constructorArgs,
    initializer: initializer ?? false,
    redeployImplementation: 'always'
  };
  const proxyContract = await upgrades.deployProxy(
    factory,
    initialArgs ?? [],
    proxyOptions
  );
  await proxyContract.waitForDeployment();
  return proxyContract.connect(deployer);
}

async function deployApp(deployer, ibcHandler) {
  const unsafeAllow = [
    "constructor",
    "state-variable-immutable",
    "state-variable-assignment"
  ];
  const proxyV1 = await deployProxy(deployer, "AppV1", [ibcHandler.target], unsafeAllow, "__AppV1_init(string)", ["mockapp-1"]);
  saveAddress("AppV1", proxyV1);
  return proxyV1;
}

async function fundRelayer(deployer) {
  const balance = await hre.ethers.provider.getBalance(relayerEoa);
  if (balance >= hre.ethers.parseEther(relayerFundingEth)) {
    console.log(`Relayer EOA ${relayerEoa} already funded:`, balance.toString());
    return;
  }
  const tx = await deployer.sendTransaction({
    to: relayerEoa,
    value: hre.ethers.parseEther(relayerFundingEth)
  });
  await tx.wait();
  console.log(`Funded relayer EOA ${relayerEoa} with ${relayerFundingEth} ETH`);
}

async function main() {
  if (network.name === "hardhat") {
    console.warn(
      "You are trying to deploy a contract to the Hardhat Network, which" +
        "gets automatically created and destroyed every time. Use the Hardhat" +
        " option '--network bor_local'"
    );
  }

  const fs = require('fs');
  let rootCert;
  if (process.env.NO_RUN_LCP === "false" && process.env.SGX_MODE === "SW") {
    console.log("RA simulation is enabled");
    rootCert = fs.readFileSync("../config/simulation_rootca.der");
  } else {
    console.log("RA simulation is disabled");
    rootCert = fs.readFileSync("../config/Intel_SGX_Attestation_RootCA.der");
  }

  const developMode = process.env.LCP_ENCLAVE_DEBUG === "1";
  console.log("Develop mode:", developMode);

  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", await deployer.getAddress());
  console.log("Account balance:", (await hre.ethers.provider.getBalance(deployer.getAddress())).toString());

  await fundRelayer(deployer);

  const ibcHandler = await deployIBC(deployer);
  saveAddress("IBCHandler", ibcHandler);

  console.log("Deploying LCPClientIAS");
  const lcpClient = await deployLCPClientIAS(deployer, ibcHandler, developMode, rootCert);
  await ibcHandler.registerClient(lcpClientType, lcpClient.target).then(tx => tx.wait());

  const app = await deployApp(deployer, ibcHandler);
  await ibcHandler.bindPort(portMock, app.target).then(tx => tx.wait());
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}
