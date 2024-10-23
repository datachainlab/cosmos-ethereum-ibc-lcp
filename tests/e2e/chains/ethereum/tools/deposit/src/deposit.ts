import { Command } from 'commander'
import { ethers } from 'ethers'
import * as fs from 'fs'
import * as process from 'node:process'
import * as dotenv from 'dotenv'
import { Deposit, Deposit__factory } from '../types/ethers-contracts'

dotenv.config()
const program = new Command()

interface callParams {
  nodeURL: string
  privateKey: string
  depositContractAddr: string
  keyDir: string
}

const checkArgs = (): callParams | undefined => {
  program.option('-m, --mode <string>', 'deposit').parse(process.argv)
  const opts = program.opts()

  // required params
  const params = ['mode']
  for (const param of params) {
    if (!opts[param]) {
      console.error(`${param} option is required`)
      return undefined
    }
  }

  // check environment variables
  const envParams = [
    'NODE_URL',
    'DEPOSIT_CONTRACT_ADDRESS',
    'PRIVATE_KEY',
    'KEY_DIR',
  ]
  for (const param of envParams) {
    if (!process.env[param]) {
      console.error(`${param} environment variable is required`)
      return undefined
    }
  }

  // set returned object
  const callParams: callParams = {
    nodeURL: process.env.NODE_URL || '',
    privateKey: process.env.PRIVATE_KEY || '',
    depositContractAddr: process.env.DEPOSIT_CONTRACT_ADDRESS || '',
    keyDir: process.env.KEY_DIR || '',
  }
  return callParams
}

const main = async (): Promise<void> => {
  const args = checkArgs()
  if (args === undefined) throw 'args is invalid'

  const provider = new ethers.JsonRpcProvider(args.nodeURL)
  const signingKey = args.privateKey.startsWith('0x')
    ? args.privateKey
    : `0x${args.privateKey}`
  const signer = new ethers.BaseWallet(
    new ethers.SigningKey(signingKey),
    provider,
  )
  const deposit = Deposit__factory.connect(args.depositContractAddr, signer)

  // Read deposit_data-*.json from ${KEY_DIR}
  const path = `${process.cwd()}/${args.keyDir}`
  const jsons = fs.readdirSync(path)
  const target = jsons.filter((json) => json.includes('deposit_data-'))
  if (target.length !== 1)
    throw new Error('deposit_data json file is not found')

  const depositData = JSON.parse(
    fs.readFileSync(`${path}/${target[0]}`, 'utf8'),
  )

  // call deposit
  for (const data of depositData) {
    const params = {
      pubKey: `0x${data.pubkey}`,
      credentials: `0x${data.withdrawal_credentials}`,
      signature: `0x${data.signature}`,
      depositDataRoot: `0x${data.deposit_data_root}`,
    }
    console.log(`${JSON.stringify(params, null, 2)}`)

    const resp = await callDeposit(
      deposit,
      params.pubKey,
      params.credentials,
      params.signature,
      params.depositDataRoot,
    )

    const maxRetryCount = 30;
    let retryCount = 0;
    let receipt;
    while (true) {
      try {
        receipt = await resp.wait()
        break
      } catch (err: any) {
        console.error(err);
        if (err.error.data == "transaction indexing is in progress" && retryCount < maxRetryCount) {
          await sleep(1000)
          console.log(`retry:${retryCount++}`)
        } else {
          throw err;
        }
      }
    }
    console.log(JSON.stringify(receipt, null, 2))
  }
}

const sleep = (ms: number) => new Promise((res) => setTimeout(res, ms))

const callDeposit = async (
  depositContract: Deposit,
  pubkey: string,
  withdrawalCredentials: string,
  signature: string,
  depositDataRoot: string,
) => {
  console.log(`call deposit function: pubkey: ${pubkey}`)

  const result = await depositContract.deposit(
    pubkey,
    withdrawalCredentials,
    signature,
    depositDataRoot,
    { value: ethers.parseEther('32') },
  )
  console.log(result)
  return result
}

main().catch((err) => {
  console.error(err)
  process.exit(1)
})
