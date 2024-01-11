## 체인링크 운영자 노드 설정 및 API 컨슈머 테스트

이 프로젝트는 체인링크 API 소비자의 구현을 테스트하고 바이낸스 스마트 체인 테스트넷에서 체인링크 운영자 노드를 설정하는 것을 목표로 합니다.

### 체인링크 운영자 노드 설정

- 체인링크에 대한 PostgreSQL 데이터베이스 컨테이너를 설정하기 위해 다음 명령어를 실행하세요.

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

- 다음 내용을 포함하여 ~/.chainlink-bsc-test 디렉토리에 config.toml 파일을 생성하십시오.

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

> BSC_TESTNET_WS_URL 및 BSC_TESTNET_HTTP_URL을 바이낸스 스마트 체인 테스트넷에 적합한 URL로 교체하세요.

- 다음 내용을 포함하여 ~/.chainlink-bsc-test 디렉토리에 secrets.toml 파일을 생성하십시오.

```toml
[Password]
Keystore = 'YOUR_POSTGRESQL_PASSWORD'

[Database]
URL = 'postgresql://postgres:`YOUR_POSTGRESQL_PASSWORD`@host.docker.internal:5432/postgres?sslmode=disable'
```

> YOUR_POSTGRESQL_PASSWORD를 1단계에서 설정한 비밀번호로 교체하세요.

- 다음 명령어로 체인링크 노드를 실행하세요:

```bash
cd ~/.chainlink-bnb && docker run --platform linux/x86_64/v8 --name chainlink -v ~/.chainlink-bnb:/chainlink -it -p 6688:6688 --add-host=host.docker.internal:host-gateway smartcontract/chainlink:2.0.0 node -config /chainlink/config.toml -secrets /chainlink/secrets.toml start
```

> 차례대로 귀하의 체인링크 이메일과 비밀번호를 입력하세요.

- 웹 브라우저에서 localhost:6688을 방문하여 체인링크 노드에 접근할 수 있습니다. 이메일과 비밀번호를 사용하여 로그인하고 노드의 기능과 기능들을 탐색하세요.

### Example Image
<img width="1876" alt="Operator Node UI" src="https://github.com/ash991213/chainlink-test/assets/99451647/349893cc-e61d-4d24-bbb2-bade9284438b">

### API 컨슈머 테스트

- 다음 매개변수를 제공하여 체인링크 운영자 계약을 배포하세요.

    - link: BNB LINK 토큰 주소.
    - owner: 계약의 소유자.

적절한 네트워크에 대한 BNB LINK 토큰 주소는 체인링크 문서에서 찾을 수 있습니다.

https://docs.chain.link/resources/link-token-contracts

- setAuthorizedSenders 함수를 사용하여 운영자 노드의 승인된 발신자를 설정하세요. 발신자 매개변수로 운영자 노드의 주소를 전달하세요.

### Example Image
<img width="488" alt="setAuthorizedSenders" src="https://github.com/ash991213/chainlink-test/assets/99451647/c63f9614-54cd-49b4-8f8c-a5fc96592c24">

- 다음 코드를 사용하여 새로운 작업을 생성하세요.

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

> YOUR_OPERATOR_CONTRACT_ADDRESS를 귀하의 운영자 계약 주소로 교체하세요.

- 다음 매개변수를 제공하여 TestToken 계약을 배포하세요

    - name: TestToken의 이름.
    - symbol: TestToken의 심볼.

- 다음 매개변수를 제공하여 ChainlinkAPIConsumer 계약을 배포하세요

    - token: 귀하의 TestToken 계약의 주소.

- TestToken 계약의 addOperator 함수를 사용하여 ChainlinkAPIConsumer 계약을 운영자로 추가하세요. 운영자 매개변수로 ChainlinkAPIConsumer 계약 주소를 전달하세요.

### Example Image
<img width="485" alt="addOperator" src="https://github.com/ash991213/chainlink-test/assets/99451647/bb51cd04-5721-41a2-ac89-04e4d51f8cbd">

- ChainlinkAPIConsumer 계약에 LINK 토큰을 보내고 운영자 노드 주소로 BNB 토큰을 보냅니다.

- ChainlinkAPIConsumer 계약의 approveMint 함수를 사용하여 오라클로부터 데이터 요청을 시작합니다. 다음 매개변수를 전달하세요:

    - oracle: 운영자 계약의 주소.

    - jobid: 오라클과 관련된 작업 ID.

> 오라클은 데이터를 검색하여 요청을 이행할 것입니다.

- approveMint 함수가 호출될 때 다음과 같은 과정이 진행됩니다:

1. _oracle (오라클 계약 주소) 및 _jobId (운영자 UI의 작업 ID) 매개변수로 함수가 활성화됩니다.

2. 함수 내부에서 buildChainlinkRequest 함수를 사용하여 Chainlink 요청이 구성됩니다. 요청에는 지정된 작업 ID, 현재 계약 주소(콜백 주소로서), 그리고 fulfillAmount 함수(콜백 함수로서)가 포함됩니다.

3. 요청은 엔드포인트 URL ('http://43.200.114.1/test-amount'), 원하는 데이터 경로 ('test_amount'), 그리고 곱셈 요소(1)로 구성됩니다.

4. sendChainlinkRequestTo 함수가 호출되어 지정된 오라클 계약 주소(_oracle)로 Chainlink 요청을 보냅니다. 요청에는 오라클이 요청을 이행하는 데 필요한 지불금(ORACLE_PAYMENT)도 포함됩니다.

5. 오라클은 요청을 받고 지정된 외부 API 호출을 수행하여 제공된 URL에서 원하는 데이터를 가져옵니다.

6. 데이터가 검색되면, observationSource에 지정된 디코딩 및 파싱 과정을 거쳐 관련 값이 추출됩니다.

7. 추출된 값은 지정된 요소(1)로 곱해집니다.

8. fulfillAmount 함수가 호출되며, 요청 ID와 계산된 값을 매개변수로 전달합니다.

9. fulfillAmount 내부에서, RequestEthereumPriceFulfilled 이벤트가 요청 ID와 받은 값과 함께 트리거됩니다.

10. 받은 값은 currentAmount 변수에 저장됩니다.

11. currentAmount가 0보다 크면, IMintOperator 계약(대표적으로 nfvToken)의 mintByOperator 함수가 호출되어 토큰을 발행합니다. 발행된 토큰의 양은 currentAmount에 1e18을 곱하여 계산됩니다.

12. 과정이 완료되고 거래 실행이 마무리됩니다.

> 이 과정을 통해 계약은 Chainlink 네트워크와 상호 작용하고, 외부 데이터를 가져오고, 받은 데이터를 기반으로 작업을 수행할 수 있습니다.

### Example Image
<img width="1266" alt="스크린샷 2023-07-12 오후 2 25 18" src="https://github.com/ash991213/chainlink-test/assets/99451647/7bf8af8a-8c8d-4dce-8417-acdabf035e3a">

<img width="1358" alt="스크린샷 2023-07-12 오후 2 26 46" src="https://github.com/ash991213/chainlink-test/assets/99451647/f88a4ab4-a02c-4cf1-84af-18c61e3f1e7d">

이 프로젝트는 체인링크를 사용하여 외부 데이터를 가져오는 기능과 오라클 노드를 설정하는 것을 테스트하는 것을 목표로 합니다. 제공된 모든 코드는 테스트 목적으로만 사용되며,실제 서비스 환경에서는 추가적인 보안 요소가 추가되어야 합니다.
