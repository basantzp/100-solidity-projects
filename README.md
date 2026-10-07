# 💯 100 Solidity Smart Contract Projects (Production Architecture)

[![Foundry](https://img.shields.io/badge/Foundry-v1.8.4-red.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.26-363636.svg)](https://soliditylang.org/)
[![Cancun EVM](https://img.shields.io/badge/EVM-Cancun%20(EIP--1153)-blue.svg)](https://eips.ethereum.org/EIPS/eip-1153)
[![Test Suite](https://img.shields.io/badge/Tests-201%2F201%20Passing-brightgreen.svg)](test/)

A comprehensive, production-grade open-source curriculum of **100 Solidity Smart Contract Projects** engineered for modern EVM protocols, Layer 2 rollups, Account Abstraction, and decentralized finance.

All contracts feature complete **Foundry test suites (201/201 tests passing across 100 test suites)**, Cancun EVM optimizations (`tstore`/`tload`), Yul assembly efficiency, custom errors, and zero external baggage.

---

## 🏛️ Complete 100 Projects Catalog & Benchmarks

### Pillar 01: Foundational Tokens & ERC Standards (Projects 01–10)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#01** | [`ERC20Permit.sol`](src/01_Tokens/ERC20Permit.sol) | Tokens | EIP-2612 gasless permit approval, immutable domain separator | ~51,000 gas transfer |
| **#02** | [`ERC721NFT.sol`](src/01_Tokens/ERC721NFT.sol) | Tokens | EIP-721 NFT with EIP-2981 on-chain royalty standard | ~91,000 gas transfer |
| **#03** | [`ERC1155MultiToken.sol`](src/01_Tokens/ERC1155MultiToken.sol) | Tokens | EIP-1155 multi-token standard with batch transfers | ~78,000 gas transfer |
| **#04** | [`ERC4626YieldVault.sol`](src/01_Tokens/ERC4626YieldVault.sol) | Tokens | EIP-4626 yield vault with virtual shares inflation defense | ~228,000 gas deposit |
| **#05** | [`SoulboundToken.sol`](src/01_Tokens/SoulboundToken.sol) | Tokens | EIP-5114 non-transferable identity & achievement badges | ~126,000 gas issue |
| **#06** | [`WETH9.sol`](src/01_Tokens/WETH9.sol) | Tokens | Canonical Wrapped Ether native conversion | ~121,000 gas deposit |
| **#07** | [`ERC20Votes.sol`](src/01_Tokens/ERC20Votes.sol) | Tokens | Historical snapshot checkpoints & voting delegation (binary search) | ~354,000 gas delegate |
| **#08** | [`ERC721A.sol`](src/01_Tokens/ERC721A.sol) | Tokens | Azuki-style $O(1)$ batch NFT minting with contiguous slot indexing | ~21,000 gas / NFT minted |
| **#09** | [`EscrowVault.sol`](src/01_Tokens/EscrowVault.sol) | Tokens | Conditional escrow with buyer, seller, and arbiter dispute resolution | ~280,000 gas release |
| **#10** | [`VestingWallet.sol`](src/01_Tokens/VestingWallet.sol) | Tokens | Cliff and continuous linear token/ETH release schedule | ~114,000 gas release |

### Pillar 02: Custody, Multi-Sig & Access Control (Projects 11–20)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#11** | [`MultiSigWallet.sol`](src/03_Governance/MultiSigWallet.sol) | Custody | M-of-N multi-signature transaction consensus & execution | ~44,000 gas submit |
| **#12** | [`TimelockController.sol`](src/03_Governance/TimelockController.sol) | Custody | Time-delayed execution with grace periods and cancellation | ~142,000 gas execute |
| **#13** | [`RoleBasedAccessControl.sol`](src/03_Governance/RoleBasedAccessControl.sol) | Access Control | Granular hierarchical role manager with role-admin delegation | ~101,000 gas grant |
| **#14** | [`Ownable2Step.sol`](src/04_Security/Ownable2Step.sol) | Access Control | Safe two-step ownership handover preventing lost admins | ~15,000 gas transfer |
| **#15** | [`PaymentSplitter.sol`](src/03_Governance/PaymentSplitter.sol) | Custody | Proportional native and token revenue sharing with pull claiming | ~273,000 gas split |
| **#16** | [`SocialRecoveryWallet.sol`](src/03_Governance/SocialRecoveryWallet.sol) | Custody | Guardian-based threshold account recovery with security delay | ~71,000 gas execute |
| **#17** | [`EmergencyPausable.sol`](src/04_Security/EmergencyPausable.sol) | Access Control | Circuit breaker emergency halt for state mutations during exploits | ~65,000 gas pause |
| **#18** | [`BlacklistGate.sol`](src/04_Security/BlacklistGate.sol) | Access Control | Compliance and sanctions filter blocking malicious addresses | ~69,000 gas check |
| **#19** | [`SpendingLimitAccount.sol`](src/03_Governance/SpendingLimitAccount.sol) | Custody | Rolling 24-hour operator withdrawal quota enforcement | ~109,000 gas withdraw |
| **#20** | [`DeadManSwitch.sol`](src/03_Governance/DeadManSwitch.sol) | Custody | Heartbeat-dependent cryptocurrency inheritance trigger | ~62,000 gas ping |

### Pillar 03: Automated Market Makers & DEX Primitives (Projects 21–30)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#21** | [`ConstantProductAMM.sol`](src/02_DeFi/ConstantProductAMM.sol) | AMM | $x \cdot y = k$ swap invariant with TWAP cumulative price accumulators | ~400,000 gas swap |
| **#22** | [`ConcentratedLiquidityPool.sol`](src/02_DeFi/ConcentratedLiquidityPool.sol) | AMM | Uniswap v3 style $Q64.96$ tick-range concentrated liquidity AMM | ~212,000 gas mint |
| **#23** | [`DutchAuction.sol`](src/02_DeFi/DutchAuction.sol) | DEX Primitives | Descending price auction with linear decay & refund | ~143,000 gas buy |
| **#24** | [`EnglishAuction.sol`](src/02_DeFi/EnglishAuction.sol) | DEX Primitives | Ascending auction with pull-over-push anti-DoS refunds | ~411,000 gas lifecycle |
| **#25** | [`OrderBookDEX.sol`](src/02_DeFi/OrderBookDEX.sol) | DEX Primitives | On-chain limit order book matching and partial/full settlement | ~259,000 gas place |
| **#26** | [`StableSwapAMM.sol`](src/02_DeFi/StableSwapAMM.sol) | AMM | Curve amplification coefficient ($A$) Stableswap invariant with Newton-Raphson | ~130,000 gas swap |
| **#27** | [`VolatilityFeeHook.sol`](src/02_DeFi/VolatilityFeeHook.sol) | AMM Hooks | Uniswap v4-inspired dynamic fee hook adjusting fee to realized volatility | ~163,000 gas hook |
| **#28** | [`TWAMM.sol`](src/02_DeFi/TWAMM.sol) | AMM | Time-Weighted AMM long-term order virtual slicing engine | ~327,000 gas order |
| **#29** | [`LiquidityBootstrappingPool.sol`](src/02_DeFi/LiquidityBootstrappingPool.sol) | AMM | Balancer-style dynamic weight-shifting anti-bot token auction pool | ~128,000 gas swap |
| **#30** | [`MultiAssetPool.sol`](src/02_DeFi/MultiAssetPool.sol) | AMM | Balancer-style multi-token constant weighted product geometric AMM | ~400,000 gas swap |

### Pillar 04: Lending, Staking & Yield Farming (Projects 31–40)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#31** | [`StakingRewards.sol`](src/02_DeFi/StakingRewards.sol) | Lending/Staking | Synthetix continuous proportional reward distribution engine | ~351,000 gas stake |
| **#32** | [`CollateralizedDebtPosition.sol`](src/02_DeFi/CollateralizedDebtPosition.sol) | Lending/Staking | MakerDAO-style overcollateralized stablecoin borrowing and liquidation | ~229,000 gas borrow |
| **#33** | [`FlashLender.sol`](src/02_DeFi/FlashLender.sol) | Lending/Staking | ERC-3156 compliant uncollateralized flash loan provider | ~98,000 gas loan |
| **#34** | [`LiquidationEngine.sol`](src/02_DeFi/LiquidationEngine.sol) | Lending/Staking | Dutch auction collateral liquidation engine for bad debt resolution | ~420,000 gas liquidate |
| **#35** | [`AutoCompoundingVault.sol`](src/02_DeFi/AutoCompoundingVault.sol) | Yield Farming | Yearn-style yield harvest and automated reinvestment controller | ~277,000 gas deposit |
| **#36** | [`LeveragedYieldFarm.sol`](src/02_DeFi/LeveragedYieldFarm.sol) | Yield Farming | Flash-borrow boosted yield farming manager with leverage up to 3x | ~250,000 gas open |
| **#37** | [`PeerToPeerLending.sol`](src/02_DeFi/PeerToPeerLending.sol) | Lending/Staking | Bilateral isolated loan agreements with escrowed collateral | ~481,000 gas lifecycle |
| **#38** | [`VariableRateMarket.sol`](src/02_DeFi/VariableRateMarket.sol) | Lending/Staking | Dynamic utilization-based kinked interest rate borrow market | ~219,000 gas borrow |
| **#39** | [`FixedTermBond.sol`](src/02_DeFi/FixedTermBond.sol) | Fixed Income | Zero-coupon discount bond issuance and par redemption at maturity | ~503,000 gas flow |
| **#40** | [`CrossCollateralBasket.sol`](src/02_DeFi/CrossCollateralBasket.sol) | Lending/Margin | Multi-collateral margin account manager with risk-weighted borrowing power | ~497,000 gas basket |

### Pillar 05: Cryptographic Verification & Meta-Transactions (Projects 41–50)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#41** | [`MerkleAirdrop.sol`](src/05_Cryptographic/MerkleAirdrop.sol) | Cryptography | 256-bit bitfield bitmap claim tracker with Merkle proofs | ~118,000 gas claim |
| **#42** | [`EIP712MetaTransactions.sol`](src/05_Cryptographic/EIP712MetaTransactions.sol) | Cryptography | ERC-2771 / EIP-712 structured data gasless forwarder | ~154,000 gas forward |
| **#43** | [`CommitReveal.sol`](src/05_Cryptographic/CommitReveal.sol) | Cryptography | MEV-resistant commit-reveal sealed-bid scheme | ~326,000 gas flow |
| **#44** | [`BlindSignatureVoting.sol`](src/05_Cryptographic/BlindSignatureVoting.sol) | Cryptography | Anonymous cryptographic ballot tallying with blind signature authorization | ~131,000 gas vote |
| **#45** | [`ECDSAKeyRecovery.sol`](src/05_Cryptographic/ECDSAKeyRecovery.sol) | Cryptography | Malleability-safe standard and compact (EIP-2098) ECDSA signature recovery | ~17,000 gas recover |
| **#46** | [`HTLC.sol`](src/05_Cryptographic/HTLC.sol) | Cryptography | Hash Time-Locked Contract for cross-chain atomic swaps | ~252,000 gas withdraw |
| **#47** | [`VerifiableRandomFunction.sol`](src/05_Cryptographic/VerifiableRandomFunction.sol) | Cryptography | On-chain VRF consumer and coordinator randomness fulfillment | ~230,000 gas fulfill |
| **#48** | [`ZeroKnowledgeVerifier.sol`](src/05_Cryptographic/ZeroKnowledgeVerifier.sol) | Zero Knowledge | Groth16 zk-SNARK proof verification primitive on alt_bn128 curve | ~11,000 gas verify |
| **#49** | [`RingSignatureMixer.sol`](src/05_Cryptographic/RingSignatureMixer.sol) | Privacy | Commitment-nullifier privacy mixer primitive | ~239,000 gas withdraw |
| **#50** | [`MultiProofMerkleDistributor.sol`](src/05_Cryptographic/MultiProofMerkleDistributor.sol) | Cryptography | Batch multi-leaf Merkle proof verification engine | ~161,000 gas multi-claim |

### Pillar 06: Advanced EVM & Cancun Optimization (Projects 51–60)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#51** | [`TransientReentrancyGuard.sol`](src/04_Security/TransientReentrancyGuard.sol) | Cancun EVM | EIP-1153 transient storage (`tstore`/`tload`) 100-gas reentrancy lock | ~100 gas lock vs 2,100 SSTORE |
| **#52** | [`BitPackingStorageEngine.sol`](src/06_CancunEVM/BitPackingStorageEngine.sol) | Cancun EVM | Multi-variable packing of 5 data types into a single 32-byte slot | 1 SSTORE (~20k gas) |
| **#53** | [`CustomYulMemoryAllocator.sol`](src/06_CancunEVM/CustomYulMemoryAllocator.sol) | Cancun EVM | Assembly-level memory pointer management and custom bump allocation | ~62,000 gas allocate |
| **#54** | [`TransientFeeCalculator.sol`](src/06_CancunEVM/TransientFeeCalculator.sol) | Cancun EVM | EIP-1153 zero-SSTORE intra-transaction fee accumulator | ~107,000 gas batch route |
| **#55** | [`CalldataCompressionLib.sol`](src/06_CancunEVM/CalldataCompressionLib.sol) | Cancun EVM | Run-Length Encoding (RLE) and zero-byte calldata compression/decompression | ~46,000 gas compress |
| **#56** | [`StorageSlotCollisionDetector.sol`](src/06_CancunEVM/StorageSlotCollisionDetector.sol) | Cancun EVM | ERC-7201 formulaic storage namespace root calculator and collision detector | ~11,000 gas check |
| **#57** | [`GasOptimizedMathLib.sol`](src/06_CancunEVM/GasOptimizedMathLib.sol) | Cancun EVM | Pure Yul assembly fixed-point WAD ($10^{18}$) and RAY ($10^{27}$) math library | ~11,000 gas operation |
| **#58** | [`BitMapFlagRegistry.sol`](src/06_CancunEVM/BitMapFlagRegistry.sol) | Cancun EVM | 256 boolean flags per storage word, cutting storage costs by 99% | ~22,000 gas / flag write |
| **#59** | [`LowLevelDispatcher.sol`](src/06_CancunEVM/LowLevelDispatcher.sol) | Cancun EVM | Pure Yul function selector dispatcher and jump table bypassing Solidity ABI overhead | ~99,000 gas dispatch |
| **#60** | [`ExtsloadExpose.sol`](src/06_CancunEVM/ExtsloadExpose.sol) | Cancun EVM | EIP-2330 / Cancun standard contract exposing `extsload` and `exttload` | ~27,000 gas read |

### Pillar 07: Upgradeability & Proxy Architectures (Projects 61–70)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#61** | [`ERC1967UUPSProxy.sol`](src/06_Upgradeability/ERC1967UUPSProxy.sol) | Proxies | Universal Upgradeable Proxy Standard with ERC-1967 storage slots | ~175,000 gas upgrade |
| **#62** | [`TransparentUpgradeableProxy.sol`](src/06_Upgradeability/TransparentUpgradeableProxy.sol) | Proxies | EIP-1967 Transparent proxy with strict admin/user selector segregation | ~118,000 gas upgrade |
| **#63** | [`MinimalProxyFactory.sol`](src/06_Upgradeability/MinimalProxyFactory.sol) | Proxies | EIP-1167 minimal bytecode clone deployer (CREATE & CREATE2) | ~80,000 gas clone |
| **#64** | [`DiamondPattern.sol`](src/06_Upgradeability/DiamondPattern.sol) | Proxies | ERC-2535 multi-facet diamond proxy standard with granular cuts | ~128,000 gas route |
| **#65** | [`BeaconProxy.sol`](src/06_Upgradeability/BeaconProxy.sol) | Proxies | Centralized UpgradeableBeacon pointer enabling single-tx fleet upgrades | ~229,000 gas fleet upgrade |
| **#66** | [`MetamorphicContract.sol`](src/06_Upgradeability/MetamorphicContract.sol) | Proxies | CREATE2 deterministic deployment factory for reproducible contract addresses | ~123,000 gas deploy |
| **#67** | [`StorageMigrator.sol`](src/06_Upgradeability/StorageMigrator.sol) | Proxies | Safe slot migration manager for upgradeable contracts transitioning layouts | ~116,000 gas migrate |
| **#68** | [`UpgradeSanitizer.sol`](src/06_Upgradeability/UpgradeSanitizer.sol) | Proxies | Initializer security guard preventing implementation takeover | ~35,000 gas guard |
| **#69** | [`FallbackDelegator.sol`](src/06_Upgradeability/FallbackDelegator.sol) | Proxies | Dynamic selector-to-implementation mapping router for modular upgrades | ~82,000 gas route |
| **#70** | [`ImmutableCloneDeployer.sol`](src/06_Upgradeability/ImmutableCloneDeployer.sol) | Proxies | ERC-3448 clone factory appending immutable arguments to runtime bytecode | ~92,000 gas clone |

### Pillar 08: DAO & On-Chain Governance (Projects 71–80)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#71** | [`GovernorBravo.sol`](src/03_Governance/GovernorBravo.sol) | DAOs | Full proposal lifecycle, quorum threshold, and on-chain vote execution | ~498,000 gas lifecycle |
| **#72** | [`QuadraticVotingEngine.sol`](src/03_Governance/QuadraticVotingEngine.sol) | DAOs | Sybil-resistant quadratic voting ballot aggregator ($\text{cost} = \text{votes}^2$) | ~334,000 gas vote |
| **#73** | [`RageQuitTreasury.sol`](src/03_Governance/RageQuitTreasury.sol) | DAOs | Moloch DAO inspired minority protection proportional ragequit redemption | ~340,000 gas ragequit |
| **#74** | [`DelegationRegistry.sol`](src/03_Governance/DelegationRegistry.sol) | DAOs | Granular hierarchical rights delegation registry (Delegate.xyz style) | ~172,000 gas delegate |
| **#75** | [`OptimisticGovernor.sol`](src/03_Governance/OptimisticGovernor.sol) | DAOs | Optimistic governance with bond requirements, challenge windows & arbitration | ~312,000 gas assert |
| **#76** | [`ConvictionVoting.sol`](src/03_Governance/ConvictionVoting.sol) | DAOs | Continuous conviction voting engine accumulating conviction over time | ~396,000 gas stake |
| **#77** | [`MultiTokenGovernor.sol`](src/03_Governance/MultiTokenGovernor.sol) | DAOs | Dual-governance engine requiring approval from Capital and Community tokens | ~327,000 gas execute |
| **#78** | [`SubDAOFactory.sol`](src/03_Governance/SubDAOFactory.sol) | DAOs | Hierarchical factory deploying sub-DAOs with parent DAO oversight & clawback | ~407,000 gas deploy |
| **#79** | [`StreamingPaymentPayroll.sol`](src/03_Governance/StreamingPaymentPayroll.sol) | DAOs | Second-by-second linear real-time token salary streaming | ~410,000 gas stream |
| **#80** | [`BribeMarketplace.sol`](src/03_Governance/BribeMarketplace.sol) | DAOs | Votium / Curve-style gauge vote incentive distributor | ~510,000 gas claim |

### Pillar 09: Account Abstraction (ERC-4337 & ERC-7579) (Projects 81–90)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#81** | [`ModularSmartAccount.sol`](src/07_AccountAbstraction/ModularSmartAccount.sol) | AA | ERC-4337 UserOperation signature validation and execution wallet | ~54,000 gas validate |
| **#82** | [`VerifyingPaymaster.sol`](src/07_AccountAbstraction/VerifyingPaymaster.sol) | AA | ERC-4337 off-chain backend signature gas sponsorship paymaster | ~29,000 gas validate |
| **#83** | [`SessionKeyPlugin.sol`](src/07_AccountAbstraction/SessionKeyPlugin.sol) | AA | Granular scoped session keys restricting target, selector, spend & expiry | ~214,000 gas session |
| **#84** | [`PasskeyValidator.sol`](src/07_AccountAbstraction/PasskeyValidator.sol) | AA | WebAuthn / Passkey (secp256r1 / P-256) signature verification module | ~8,900 gas validate |
| **#85** | [`MultiOwnerModularAccount.sol`](src/07_AccountAbstraction/MultiOwnerModularAccount.sol) | AA | ERC-7579 modular account with multi-owner threshold validation | ~70,000 gas execute |
| **#86** | [`SubscriptionExecutor.sol`](src/07_AccountAbstraction/SubscriptionExecutor.sol) | AA | Automated recurring pull-payment subscription module for smart accounts | ~392,000 gas execute |
| **#87** | [`SpendingGuardianHook.sol`](src/07_AccountAbstraction/SpendingGuardianHook.sol) | AA | ERC-7579 pre-execution policy hook enforcing 24h rolling velocity limits | ~122,000 gas hook |
| **#88** | [`RecoveryModule.sol`](src/07_AccountAbstraction/RecoveryModule.sol) | AA | Social recovery plugin for smart accounts with guardian voting & timelock | ~280,000 gas recover |
| **#89** | [`BatchTransactionAggregator.sol`](src/07_AccountAbstraction/BatchTransactionAggregator.sol) | AA | Multi-target atomic batch execution with failure tolerance | ~100,000 gas batch |
| **#90** | [`BundlerGasEstimator.sol`](src/07_AccountAbstraction/BundlerGasEstimator.sol) | AA | Off-chain/on-chain simulation harness estimating UserOperation gas | ~59,000 gas estimate |

### Pillar 10: Cross-Chain, MEV & Oracles (Projects 91–100)
| # | Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#91** | [`TWAPOracle.sol`](src/08_Oracles/TWAPOracle.sol) | Oracles | Time-Weighted Average Price cumulative observation accumulator | ~182,000 gas consult |
| **#92** | [`ChainlinkFallbackOracle.sol`](src/08_Oracles/ChainlinkFallbackOracle.sol) | Oracles | Resilient Chainlink Aggregator V3 consumer with heartbeat bounds & fallback | ~192,000 gas resolve |
| **#93** | [`CrossChainTokenBridge.sol`](src/09_CrossChain/CrossChainTokenBridge.sol) | Cross-Chain | Replay-protected lock-and-mint / burn-and-mint validator attestation bridge | ~268,000 gas lock |
| **#94** | [`MEVBackrunShield.sol`](src/08_Oracles/MEVBackrunShield.sol) | MEV Defense | Private RPC bundle verification and backrun arbitrage profit sharing | ~153,000 gas rebate |
| **#95** | [`FlashbotsSearcherBot.sol`](src/08_Oracles/FlashbotsSearcherBot.sol) | MEV | On-chain atomic triangular arbitrage executor with miner/builder bribes | ~104,000 gas execute |
| **#96** | [`PythEntropyConsumer.sol`](src/08_Oracles/PythEntropyConsumer.sol) | Oracles | Decentralized low-latency pull-oracle consumer with freshness verification | ~94,000 gas update |
| **#97** | [`LayerZeroMessagingApp.sol`](src/09_CrossChain/LayerZeroMessagingApp.sol) | Cross-Chain | Omnichain arbitrary message passing endpoint application (LayerZero OApp) | ~117,000 gas send |
| **#98** | [`CCIPCrossChainExecutor.sol`](src/09_CrossChain/CCIPCrossChainExecutor.sol) | Cross-Chain | Chainlink CCIP receiver and execution contract for token & payload calls | ~45,000 gas receive |
| **#99** | [`SoftLiquidationProtector.sol`](src/08_Oracles/SoftLiquidationProtector.sol) | DeFi Protectors | Curve LLAMMA-inspired automated soft liquidation and health-factor rebalancer | ~74,000 gas rebalance |
| **#100** | [`SovereignRollupSettlement.sol`](src/09_CrossChain/SovereignRollupSettlement.sol) | Rollup Settlement | Fraud-proof dispute game settlement contract for optimistic sovereign rollups | ~265,000 gas dispute |

---

## 🧪 Testing & Invariant Verification

Run the full master suite via Foundry:

```bash
# Build contracts with Solc 0.8.26 on Cancun
forge build

# Run all 201 unit, integration, and fuzz tests across 100 test suites
forge test

# Run tests with detailed call traces
forge test -vvv

# Format all contracts and tests
forge fmt
```

---

## 📄 License
This repository is licensed under the [MIT License](LICENSE).
