## Chainlink operator node setup & API Consumer Test

This project is aimed at testing the implementation of a Chainlink API Consumer and setting up a Chainlink Operator node on the Binance Smart Chain testnet

### Chainlink operator node setup

- Run the following command to set up the PostgreSQL database container for Chainlink

```shell
$ docker run --name chainlink-postgres -e POSTGRES_PASSWORD="SET_YOUR_PASSWORD" -p 5432:5432 -d postgres
```

- Verify that the PostgreSQL container is running

```shell
$ docker ps -a -f name=chainlink-postgres
```

- Create a directory for your Chainlink BSC testnet configuration

```shell
$ mkdir ~/.chainlink-bsc-test
```

- Create a config.toml file in the ~/.chainlink-bsc-test directory with the following content

```toml
[Log]
Level = 'info'

[WebServer]
AllowOrigins = '\*'
SecureCookies = false

[WebServer.TLS]
HTTPSPort = 0

[[EVM]]
ChainID = '97'

[[EVM.Nodes]]
Name = 'Binance Smart Chain Testnet'
WSURL = 'BSC_TESTNET_WS_URL'
HTTPURL = 'BSC_TESTNET_HTTP_URL'
```

> Replace BSC_TESTNET_WS_URL and BSC_TESTNET_HTTP_URL with the appropriate URLs for the Binance Smart Chain testnet.

- Create a secrets.toml file in the ~/.chainlink-bsc-test directory with the following content

```toml
[Password]
Keystore = 'YOUR_POSTGRESQL_PASSWORD'

[Database]
URL = 'postgresql://postgres:`YOUR_POSTGRESQL_PASSWORD`@host.docker.internal:5432/postgres?sslmode=disable'
```

> Replace YOUR_POSTGRESQL_PASSWORD with the password you set in step 1.

- Run the Chainlink node with the following command:

```bash
cd ~/.chainlink-bnb && docker run --platform linux/x86_64/v8 --name chainlink -v ~/.chainlink-bnb:/chainlink -it -p 6688:6688 --add-host=host.docker.internal:host-gateway smartcontract/chainlink:2.0.0 node -config /chainlink/config.toml -secrets /chainlink/secrets.toml start
```

> Enter your Chainlink email and password in sequence

- You can access the Chainlink node by visiting localhost:6688 in your web browser. Use your email and password to log in and explore the features and functionalities of the node.

### Sample Image
<img width="1876" alt="Operator Node UI" src="https://github.com/ash991213/chainlink-test/assets/99451647/349893cc-e61d-4d24-bbb2-bade9284438b">

### API Consumer Test

- Deploy the Chainlink operator contract, providing the following parameters

    - link: The BNB LINK token address.
    - owner: The contract owner.

You can find the BNB LINK token address for the appropriate network in the Chainlink documentation.

https://docs.chain.link/resources/link-token-contracts

- Use the setAuthorizedSenders function to set the authorized senders for your operator node. Pass the addresses of your operator nodes as the senders parameter.

### Sample Image
<img width="488" alt="setAuthorizedSenders" src="https://github.com/ash991213/chainlink-test/assets/99451647/c63f9614-54cd-49b4-8f8c-a5fc96592c24">

- Create a new job by using the following code

```toml
# THIS IS EXAMPLE CODE THAT USES HARDCODED VALUES FOR CLARITY.
# THIS IS EXAMPLE CODE THAT USES UN-AUDITED CODE.
# DO NOT USE THIS CODE IN PRODUCTION.

name = "Get > Uint256 - (TOML)"
schemaVersion = 1
type = "directrequest"
# Optional External Job ID: Automatically generated if unspecified
# externalJobID = "b1d42cd5-4a3a-4200-b1f7-25a68e48aad8"
contractAddress = "YOUR_OPERATOR_CONTRACT_ADDRESS"
maxTaskDuration = "0s"
minIncomingConfirmations = 0
observationSource = """
    decode_log   [type="ethabidecodelog"
                  abi="OracleRequest(bytes32 indexed specId, address requester, bytes32 requestId, uint256 payment, address callbackAddr, bytes4 callbackFunctionId, uint256 cancelExpiration, uint256 dataVersion, bytes data)"
                  data="$(jobRun.logData)"
                  topics="$(jobRun.logTopics)"]

    decode_cbor  [type="cborparse" data="$(decode_log.data)"]
    fetch        [type="http" method=GET url="$(decode_cbor.get)" allowUnrestrictedNetworkAccess="true"]
    parse        [type="jsonparse" path="$(decode_cbor.path)" data="$(fetch)"]

    multiply     [type="multiply" input="$(parse)" times="$(decode_cbor.times)"]

    encode_data  [type="ethabiencode" abi="(bytes32 requestId, uint256 value)" data="{ \\"requestId\\": $(decode_log.requestId), \\"value\\": $(multiply) }"]
    encode_tx    [type="ethabiencode"
                  abi="fulfillOracleRequest2(bytes32 requestId, uint256 payment, address callbackAddress, bytes4 callbackFunctionId, uint256 expiration, bytes calldata data)"
                  data="{\\"requestId\\": $(decode_log.requestId), \\"payment\\":   $(decode_log.payment), \\"callbackAddress\\": $(decode_log.callbackAddr), \\"callbackFunctionId\\": $(decode_log.callbackFunctionId), \\"expiration\\": $(decode_log.cancelExpiration), \\"data\\": $(encode_data)}"
                  ]
    submit_tx    [type="ethtx" to="YOUR_OPERATOR_CONTRACT_ADDRESS" data="$(encode_tx)"]

    decode_log -> decode_cbor -> fetch -> parse -> multiply -> encode_data -> encode_tx -> submit_tx
"""
```

> Replace YOUR_OPERATOR_CONTRACT_ADDRESS with the address of your operator contract.

- Deploy the TestToken contract, providing the following parameters

    - name: The name of the TestToken.
    - symbol: The symbol of the TestToken.

- Deploy the ChainlinkAPIConsumer contract, providing the following parameters

    - token: The address of your TestToken contract.

- Use the addOperator function of the TestToken contract to add the ChainlinkAPIConsumer contract as an operator. Pass the ChainlinkAPIConsumer contract address as the operator parameter.

### Sample Image
<img width="485" alt="addOperator" src="https://github.com/ash991213/chainlink-test/assets/99451647/bb51cd04-5721-41a2-ac89-04e4d51f8cbd">

- Send LINK tokens to the ChainlinkAPIConsumer contract and send BNB tokens to the operator node address.

- Use the approveMint function of the ChainlinkAPIConsumer contract to initiate the data request from the oracle. Pass the following parameters:

    - oracle: The address of the operator contract.

    - jobid: The Job ID associated with the oracle.

> The oracle will retrieve the data and fulfill the request.

- When the approveMint function is called, the following process takes place

1. The function is triggered with the parameters _oracle (Oracle contract address) and _jobId (Job ID of the operator UI).

2. Inside the function, a Chainlink request is built using the buildChainlinkRequest function. The request includes the specified job ID, the current contract address as the callback address, and the fulfillAmount function as the callback function.

3. The request is configured with the endpoint URL ("http://43.200.114.1/test-amount"), the desired data path ("test_amount"), and the multiplication factor (1).

4. The sendChainlinkRequestTo function is called to send the Chainlink request to the specified Oracle contract address (_oracle). The request also includes the required payment (ORACLE_PAYMENT) to compensate the Oracle for fulfilling the request.

5. The Oracle receives the request and performs the specified external API call to fetch the desired data from the provided URL.

6. Once the data is retrieved, it goes through the decoding and parsing process specified in the observationSource to extract the relevant value.

7. The extracted value is multiplied by the specified factor (1).

8. The fulfillAmount function is called, passing the request ID and the calculated value as parameters.

9. Inside fulfillAmount, the emitted event RequestEthereumPriceFulfilled is triggered with the request ID and the received value.

10. The received value is stored in the currentAmount variable.

11. If the currentAmount is greater than 0, the mintByOperator function of the IMintOperator contract (represented by nfvToken) is called to mint tokens. The amount of tokens minted is calculated by multiplying the currentAmount by 1e18.

12. The process is completed, and the transaction execution is finished.

> This process allows the contract to interact with the Chainlink network, fetch external data, and perform actions based on the received data.

### Sample Image
<img width="1266" alt="스크린샷 2023-07-12 오후 2 25 18" src="https://github.com/ash991213/chainlink-test/assets/99451647/7bf8af8a-8c8d-4dce-8417-acdabf035e3a">

<img width="1358" alt="스크린샷 2023-07-12 오후 2 26 46" src="https://github.com/ash991213/chainlink-test/assets/99451647/f88a4ab4-a02c-4cf1-84af-18c61e3f1e7d">

This project aims to test the functionality of fetching external data using Chainlink and setting up an Oracle node. All the code provided is for testing purposes only and should not be used in a production environment.
