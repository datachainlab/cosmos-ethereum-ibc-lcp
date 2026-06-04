const portMock = "mockapp";
// lcp-go's relay module emits "lcp-client-zkdcap" as the IBC client type
// regardless of whether the on-chain implementation is IAS or zkDCAP — it's a
// fixed identifier, not a build-mode discriminator. Registering anything else
// here causes MsgCreateClient to revert with IBCClientUnregisteredClientType.
const lcpClientType = "lcp-client-zkdcap";

// How much ETH the admin transfers to the deployer/relayer EOA so HD-signer
// txs can pay gas. The relayer's HD signer (configs/templates/ibc-1.json.tpl)
// derives its EOA from the same mnemonic + path as hardhat.config.js's second
// account, so the addresses match.
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

async function prepareImplementation(deployer, proxy, contractName, constructorArgs, unsafeAllow) {
  const factory = await hre.ethers.getContractFactory(contractName).then(f => f.connect(deployer));
  const implOptions = {
    constructorArgs,
    txOverrides: {},
    unsafeAllow: unsafeAllow ?? [],
    redeployImplementation: 'always',
    timeout: 600000,
    getTxResponse: true
  };
  const tx = await hre.upgrades.prepareUpgrade(proxy, factory, implOptions);
  const receipt = await tx.wait(3);
  const implContract = await hre.ethers.getContractAt(contractName, receipt.contractAddress);
  return implContract.connect(deployer);
}

async function deployApp(deployer, ibcHandler) {
  const unsafeAllow = [
    "constructor",
    "state-variable-immutable",
    "state-variable-assignment"
  ];
  const proxyV1 = await deployProxy(deployer, "AppV1", [ibcHandler.target], unsafeAllow, "__AppV1_init(string)", ["mockapp-1"]);
  saveAddress("AppV1", proxyV1);

  if (process.env.USE_UPGRADE_TEST === 'yes') {
    for (let i = 2; i <= 7; i++) {
      const contractName = `AppV${i}`;
      const impl = await prepareImplementation(deployer, proxyV1, contractName, [ibcHandler.target], unsafeAllow);
      saveAddress(contractName, impl);

      // ethereum-ibc-relay-chain v0.3.21 (commit d83238e4) takes the
      // implementation and initialCalldata as separate args; the struct
      // form some older commits accept is gone. tm2eth's deploy.js still
      // uses the struct form because its package-lock pinned a pre-tag
      // commit (b2579e90) — a latent bug that surfaces on fresh installs.
      await proxyV1.proposeAppVersion(
        `mockapp-${i}`,
        impl.target,
        impl.interface.encodeFunctionData(`__${contractName}_init(string)`, [contractName])
      ).then(tx => tx.wait());
    }
  } else {
    console.log(`Skipping AppV2-V7 deployment (USE_UPGRADE_TEST=${process.env.USE_UPGRADE_TEST})`);
  }

  return proxyV1;
}

async function fundRelayer(admin, target) {
  const balance = await hre.ethers.provider.getBalance(target);
  if (balance >= hre.ethers.parseEther(relayerFundingEth)) {
    console.log(`Deployer ${target} already funded:`, balance.toString());
    return;
  }
  const tx = await admin.sendTransaction({
    to: target,
    value: hre.ethers.parseEther(relayerFundingEth)
  });
  await tx.wait();
  console.log(`Funded deployer ${target} with ${relayerFundingEth} ETH from admin`);
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

  // signers[0] is the kurtosis admin (only L2-prefunded account), used purely
  // to fund the relayer EOA on first deploy. signers[1] is the relayer EOA
  // (same private key the HD signer derives) — AppV1 records its address as
  // `_deployer`, which is the only address allowed to call `eth upgrade propose`
  // (see IBCContractUpgradableUUPSMockApp._isContractUpgrader). Without this,
  // upgrade-test reverts with IBCChannelUpgradableModuleUnauthorizedUpgrader.
  const [admin, deployer] = await hre.ethers.getSigners();
  const deployerAddr = await deployer.getAddress();
  console.log("Admin (funding only):", await admin.getAddress());
  console.log("Deployer (contract owner):", deployerAddr);

  await fundRelayer(admin, deployerAddr);
  console.log("Deployer balance:", (await hre.ethers.provider.getBalance(deployerAddr)).toString());

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
