import { Command } from 'commander'
import * as fs from 'fs'
import Web3 from 'web3'
import { AbiItem } from 'web3-utils'
import * as dotenv from 'dotenv'
import DepositABI from '../json/deposit.json'

dotenv.config()
const program = new Command()

interface callParams {
  nodeURL: string
  privateKey: string
  depositContractAddr: string
  keyDir: string
  mode: string
}

const ZERO_ADDRESS = '0x0000000000000000000000000000000000000000'

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
    mode: opts.mode,
  }
  return callParams
}

const main = async (): Promise<void> => {
  const args = checkArgs()
  if (args === undefined) throw 'args is invalid'
  console.log(`command: ${args.mode}`)

  try {
    const web3 = new Web3(args.nodeURL)

    // PRIVATE_KEY variable defined
    web3.eth.accounts.wallet.add(args.privateKey)
    const account = web3.eth.accounts.wallet[0].address

    switch (args.mode) {
      case 'deposit': {
        const contractAbi: AbiItem[] = DepositABI as AbiItem[]
        const deposit = new web3.eth.Contract(
          contractAbi,
          args.depositContractAddr
        )

        const callDeposit = async (
          pubkey: string,
          withdrawalCredentials: string,
          signature: string,
          depositDataRoot: string
        ) => {
          console.log(`call deposit function: pubkey: ${pubkey}`)

          const result = await deposit.methods
            .deposit(pubkey, withdrawalCredentials, signature, depositDataRoot)
            .send({ from: account, gasLimit: 90000, value: 32000000000000000000 });
          console.log(result)
        }

        // Read deposit_data-*.json from ${KEY_DIR}
        const path = `${process.cwd()}/${args.keyDir}`
        const jsons = fs.readdirSync(path)
        const target = jsons.filter(json => json.includes('deposit_data-'))
        if (target.length !== 1) throw new Error('deposit_data json file is not found');

        const depositData = JSON.parse(fs.readFileSync(`${path}/${target[0]}`, 'utf8'))

        // call deposit        
        for (const data of depositData) {
          await callDeposit(`0x${data.pubkey}`, `0x${data.withdrawal_credentials}`, `0x${data.signature}`, `0x${data.deposit_data_root}`)
        }        
        break
      }
    }
  } catch (e) {
    console.error(e)
  }
}

void main()
