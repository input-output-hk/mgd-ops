#!/usr/bin/env nu

const network_magic = 42
const security_param = 10
const num_spo_nodes = 1
const init_supply = 12000000
let start_time = (date now | date to-timezone UTC) + 1min
const root = "example"
const cardano_version = "8-11-0-sancho-235e34f"

rm -r $root
mkdir $root
cd $root

{
  heavyDelThd: "300000000000",
  maxBlockSize: "2000000",
  maxTxSize: "4096",
  maxHeaderSize: "2000000",
  maxProposalSize: "700",
  mpcThd: "20000000000000",
  scriptVersion: 0,
  slotDuration: "1000",
  softforkRule: {
    initThd: "900000000000000",
    minThd: "600000000000000",
    thdDecrement: "50000000000000"
  },
  txFeePolicy: {
    multiplier: "43946000000",
    summand: "155381000000000"
  },
  unlockStakeEpoch: "18446744073709551615",
  updateImplicit: "10000",
  updateProposalThd: "100000000000000",
  updateVoteThd: "1000000000000"
} | save -f byron.genesis.spec.json

{
  collateralPercentage: 150,
  costModels: {
    PlutusV1: [197209, 0, 1, 1, 396231, 621, 0, 1, 150000, 1000, 0, 1, 150000, 32, 2477736, 29175, 4, 29773, 100, 29773, 100, 29773, 100, 29773, 100, 29773, 100, 29773, 100, 100, 100, 29773, 100, 150000, 32, 150000, 32, 150000, 32, 150000, 1000, 0, 1, 150000, 32, 150000, 1000, 0, 8, 148000, 425507, 118, 0, 1, 1, 150000, 1000, 0, 8, 150000, 112536, 247, 1, 150000, 10000, 1, 136542, 1326, 1, 1000, 150000, 1000, 1, 150000, 32, 150000, 32, 150000, 32, 1, 1, 150000, 1, 150000, 4, 103599, 248, 1, 103599, 248, 1, 145276, 1366, 1, 179690, 497, 1, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 148000, 425507, 118, 0, 1, 1, 61516, 11218, 0, 1, 150000, 32, 148000, 425507, 118, 0, 1, 1, 148000, 425507, 118, 0, 1, 1, 2477736, 29175, 4, 0, 82363, 4, 150000, 5000, 0, 1, 150000, 32, 197209, 0, 1, 1, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 150000, 32, 3345831, 1, 1]
  },
  executionPrices: {
    prMem: 0.0577,
    prSteps: 7.21e-05
  },
  lovelacePerUTxOWord: 34482,
  maxBlockExUnits: {
    exUnitsMem: 50000000,
    exUnitsSteps: 40000000000
  },
  maxCollateralInputs: 3,
  maxTxExUnits: {
    exUnitsMem: 10000000,
    exUnitsSteps: 10000000000
  },
  maxValueSize: 5000
} | save -f genesis.alonzo.spec.json

{
  poolVotingThresholds: {
    committeeNormal: 0.51,
    committeeNoConfidence: 0.51,
    hardForkInitiation: 0.51,
    motionNoConfidence: 0.51,
    ppSecurityGroup: 0.51
  },
  dRepVotingThresholds: {
    motionNoConfidence: 0.51,
    committeeNormal: 0.51,
    committeeNoConfidence: 0.51,
    updateToConstitution: 0.51,
    hardForkInitiation: 0.51,
    ppNetworkGroup: 0.51,
    ppEconomicGroup: 0.51,
    ppTechnicalGroup: 0.51,
    ppGovGroup: 0.51,
    treasuryWithdrawal: 0.51
  },
  committeeMinSize: 0,
  committeeMaxTermLength: 5000000,
  govActionLifetime: 100,
  govActionDeposit: 1000000000,
  dRepDeposit: 2000000,
  dRepActivity: 20,
  minFeeRefScriptCostPerByte: 0,
  plutusV3CostModel: [205665, 812, 1, 1, 1000, 571, 0, 1, 1000, 24177, 4, 1, 1000, 32, 117366, 10475, 4, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 23000, 100, 100, 100, 23000, 100, 19537, 32, 175354, 32, 46417, 4, 221973, 511, 0, 1, 89141, 32, 497525, 14068, 4, 2, 196500, 453240, 220, 0, 1, 1, 1000, 28662, 4, 2, 245000, 216773, 62, 1, 1060367, 12586, 1, 208512, 421, 1, 187000, 1000, 52998, 1, 80436, 32, 43249, 32, 1000, 32, 80556, 1, 57667, 4, 1000, 10, 197145, 156, 1, 197145, 156, 1, 204924, 473, 1, 208896, 511, 1, 52467, 32, 64832, 32, 65493, 32, 22558, 32, 16563, 32, 76511, 32, 196500, 453240, 220, 0, 1, 1, 69522, 11687, 0, 1, 60091, 32, 196500, 453240, 220, 0, 1, 1, 196500, 453240, 220, 0, 1, 1, 1159724, 392670, 0, 2, 806990, 30482, 4, 1927926, 82523, 4, 265318, 0, 4, 0, 85931, 32, 205665, 812, 1, 1, 41182, 32, 212342, 32, 31220, 32, 32696, 32, 43357, 32, 32247, 32, 38314, 32, 35190005, 10, 57996947, 18975, 10, 39121781, 32260, 10, 23000, 100, 23000, 100, 832808, 18, 3209094, 6, 331451, 1, 65990684, 23097, 18, 114242, 18, 94393407, 87060, 18, 16420089, 18, 2145798, 36, 3795345, 12, 889023, 1, 204237282, 23271, 36, 129165, 36, 189977790, 85902, 36, 33012864, 36, 388443360, 1, 401885761, 72, 2331379, 72, 1927926, 82523, 4, 117366, 10475, 4, 1292075, 24469, 74, 0, 1, 936157, 49601, 237, 0, 1],
  constitution: {
    anchor: {
      url: "",
      dataHash: "0000000000000000000000000000000000000000000000000000000000000000"
    }
  },
  committee: {
    members: {},
    threshold: 0
  }
} | save -f genesis.conway.spec.json

{
  ByronGenesisFile: genesis/byron/genesis.json,
  ShelleyGenesisFile: genesis/shelley/genesis.json,
  AlonzoGenesisFile: genesis/shelley/genesis.alonzo.json,
  ConwayGenesisFile: genesis/shelley/genesis.conway.json,
  SocketPath: db/node.socket,
  MaxConcurrencyBulkSync: 1,
  MaxConcurrencyDeadline: 2,
  Protocol: Cardano,
  PBftSignatureThreshold: 0.6,
  RequiresNetworkMagic: RequiresMagic,
  LastKnownBlockVersion-Major: 8,
  LastKnownBlockVersion-Minor: 0,
  LastKnownBlockVersion-Alt: 0,
  TurnOnLogging: true,
  TurnOnLogMetrics: true,
  TestShelleyHardForkAtEpoch: 0,
  TestAllegraHardForkAtEpoch: 0,
  TestMaryHardForkAtEpoch: 0,
  TestAlonzoHardForkAtEpoch: 0,
  TestBabbageHardForkAtEpoch: 0,
  TestConwayHardForkAtEpoch: 0,
  ExperimentalProtocolsEnabled: true,
  ExperimentalHardForksEnabled: true,
  minSeverity: Info,
  TracingVerbosity: NormalVerbosity,
  setupBackends: [ KatipBK ],
  defaultBackends: [ KatipBK ],
  setupScribes: [
    [ scKind, scName, scFormat ];
    [ FileSK, logs/mainnet.log, ScText ],
    [ StdoutSK, stdout, ScText ]
  ],
  defaultScribes: [
    [ FileSK, logs/mainnet.log ],
    [ StdoutSK, stdout ]
  ],
  rotation: {
    rpLogLimitBytes: 5000000,
    rpKeepFilesNum: 3,
    rpMaxAgeHours: 24
  },
  TraceBlockFetchClient: false,
  TraceBlockFetchDecisions: false,
  TraceBlockFetchProtocol: false,
  TraceBlockFetchProtocolSerialised: false,
  TraceBlockFetchServer: false,
  TraceBlockchainTime: false,
  TraceChainDb: true,
  TraceChainSyncClient: false,
  TraceChainSyncBlockServer: false,
  TraceChainSyncHeaderServer: false,
  TraceChainSyncProtocol: false,
  TraceDNSResolver: false,
  TraceDNSSubscription: false,
  TraceErrorPolicy: true,
  TraceLocalErrorPolicy: true,
  TraceForge: false,
  TraceHandshake: false,
  TraceIpSubscription: false,
  TraceLocalRootPeers: false,
  TracePublicRootPeers: false,
  TracePeerSelection: false,
  TraceDebugPeerSelection: false,
  TracePeerSelectionActions: false,
  TraceConnectionManager: false,
  TraceServer: true,
  TraceLocalConnectionManager: false,
  TraceLocalServer: false,
  TraceLocalChainSyncProtocol: false,
  TraceLocalHandshake: false,
  TraceLocalTxSubmissionProtocol: false,
  TraceLocalTxSubmissionServer: false,
  TraceMempool: true,
  TraceMux: false,
  TraceTxInbound: false,
  TraceTxOutbound: false,
  TraceTxSubmissionProtocol: false,
  options: {
    mapBackends: {
      cardano.node.metrics: [ EKGViewBK ]
    },
    mapScribes: {
      cardano.node.metrics: [ "FileSK::logs/mainnet.log" ]
    },
    mapSeverity: {
      cardano.node.ChainDB: Notice,
      cardano.node.DnsSubscription: Debug
    }
  }
} | save -f configuration.json

let cardano_cli = (
  nix build
    --print-out-paths
    --no-link
    $"github:input-output-hk/capkgs#cardano-cli-input-output-hk-cardano-node-($cardano_version)"
)

$env.PATH = ($env.PATH | append $"($cardano_cli)/bin")	

(
  cardano-cli byron genesis genesis
    --protocol-magic $network_magic
    --start-time ($start_time | format date '%s')
    --k $security_param
    --n-poor-addresses 0
    --n-delegate-addresses $num_spo_nodes
    --total-balance $init_supply
    --delegate-share 1
    --avvm-entry-count 0
    --avvm-entry-balance 0
    --protocol-parameters-file byron.genesis.spec.json
    --genesis-output-dir byron-gen-command
)

(
  cardano-cli genesis create-staked
    --genesis-dir .
    --testnet-magic $network_magic
    --gen-pools $num_spo_nodes
    --supply          2000000000000
    --supply-delegated 240000000002
    --gen-stake-delegs $num_spo_nodes
    --start-time ($start_time | format date '%Y-%m-%dT%H:%M:%SZ')
    --gen-utxo-keys $num_spo_nodes
)

mkdir genesis/byron genesis/shelley

mv genesis.alonzo.json genesis/shelley/genesis.alonzo.json
mv genesis.conway.json genesis/shelley/genesis.conway.json

(
  open byron-gen-command/genesis.json
  | update protocolConsts { $in | update protocolMagic 42 }
  | save -f genesis/byron/genesis.json
)

(
  open genesis.json
  | update slotLength 0.1
  | update securityParam 10
  | update activeSlotsCoeff 0.1
  | update epochLength 500
  | update maxLovelaceSupply 2000000000000
  | update updateQuorum 2
  | update protocolParams {
    $in
    | insert major 9
    | update minFeeA 44
    | update minFeeB 155381
    | update minUTxOValue 1000000
    | update decentralisationParam 0.7
    | update rho 0.1
    | update tau 0.1
  }
  | collect { save -f genesis/shelley/genesis.json }
)

(
  open configuration.json
  | insert ByronGenesisHash (cardano-cli byron genesis print-genesis-hash --genesis-json genesis/byron/genesis.json)
  | insert ShelleyGenesisHash (cardano-cli shelley genesis hash --genesis genesis/shelley/genesis.json)
  | insert AlonzoGenesisHash (cardano-cli alonzo genesis hash --genesis genesis/shelley/genesis.alonzo.json)
  | insert ConwayGenesisHash (cardano-cli conway genesis hash --genesis genesis/shelley/genesis.conway.json)
  | collect { save -f configuration.json }
)

mkdir ../flake/nixosModules/node/
cp configuration.json                  ../flake/nixosModules/node/configuration.json
cp genesis/byron/genesis.json          ../flake/nixosModules/node/genesis.byron.json
cp genesis/shelley/genesis.json        ../flake/nixosModules/node/genesis.shelley.json
cp genesis/shelley/genesis.alonzo.json ../flake/nixosModules/node/genesis.alonzo.json
cp genesis/shelley/genesis.conway.json ../flake/nixosModules/node/genesis.conway.json
git add ../flake/nixosModules/node

let topology = 1..$num_spo_nodes | each {|n|
  {
    addr: "127.0.0.1",
    port: (3000 + $n),
    valency: 1
  }
}

1..$num_spo_nodes | each {|n|
  let node = $"node-spo($n)"
  let dst = $"($node)"
  let num = ($n - 1) | into string | fill --alignment right --character '0' --width 3
  let port = 3000 + $n
  let secret = $"../secrets/($node)"

  mkdir $dst
  mkdir $secret

  let files = {
    ($"pools/vrf($n).skey"): "vrf.skey",
    ($"pools/opcert($n).cert"): "opcert.cert",
    ($"pools/kes($n).skey"): "kes.skey",
    ($"byron-gen-command/delegate-keys.($num).key"): "byron-delegate.key",
    ($"byron-gen-command/delegation-cert.($num).json"): "byron-delegation.cert",
  }

  $files | items {|src, name|
    let secret_file = $"($secret)/($name).enc"
    sops --input-type binary --output-type binary --kms $env.KMS --encrypt $src | save -f $secret_file
    git add $secret_file
    mv $src $"($dst)/($name)"
  }

  $port | save -f $"($dst)/port"

  { Producers: ($topology | where port != $port) } | save -f $"($dst)/topology.json"

  $"#!/usr/bin/env nu

  \(
    nix run 'github:input-output-hk/capkgs#cardano-node-input-output-hk-cardano-node-($cardano_version)' -- run
      --config                          ($root)/configuration.json
      --topology                        ($root)/($node)/topology.json
      --database-path                   ($root)/($node)/db
      --socket-path                     ($root)/($node)/node.sock
      --shelley-kes-key                 ($root)/($node)/kes.skey
      --shelley-vrf-key                 ($root)/($node)/vrf.skey
      --byron-delegation-certificate    ($root)/($node)/byron-delegation.cert
      --byron-signing-key               ($root)/($node)/byron-delegate.key
      --shelley-operational-certificate ($root)/($node)/opcert.cert
      --port                            \(open "($root)/($node)/port")
      | ^tee -a ($root)/($node)/node.log
  )
  " | save -f $"($node).nu"

  chmod +x $"($node).nu"
}

print "All done"
