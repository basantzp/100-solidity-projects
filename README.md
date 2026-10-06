# 💯 100 Solidity Smart Contract Projects (Production Architecture)

[![Foundry](https://img.shields.io/badge/Foundry-v1.8.4-red.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.26-363636.svg)](https://soliditylang.org/)
[![Cancun EVM](https://img.shields.io/badge/EVM-Cancun%20(EIP--1153)-blue.svg)](https://eips.ethereum.org/EIPS/eip-1153)
[![Test Suite](https://img.shields.io/badge/Tests-151%2F151%20Passing-brightgreen.svg)](test/)

A production-grade, battle-tested open-source curriculum of **100 Solidity Smart Contract Projects** engineered for modern EVM protocols, Layer 2 networks, and decentralized finance.

All contracts feature comprehensive **Foundry test suites (151/151 tests passing across 62 test suites)**, gas telemetry, custom errors, and Cancun EVM optimizations.

---

## 🏛️ Implemented Protocols & Benchmarks

| Project # | Protocol / Contract | Category | Core Innovation | Gas Profile / Status |
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
| **#11** | [`MultiSigWallet.sol`](src/03_Governance/MultiSigWallet.sol) | Governance | M-of-N multi-signature transaction consensus & execution | ~44,000 gas submit |
| **#12** | [`TimelockController.sol`](src/03_Governance/TimelockController.sol) | Governance | Time-delayed execution with grace periods and cancellation | ~142,000 gas execute |
| **#13** | [`RoleBasedAccessControl.sol`](src/03_Governance/RoleBasedAccessControl.sol) | Governance | Granular hierarchical role manager with role-admin delegation | ~101,000 gas grant |
| **#14** | [`Ownable2Step.sol`](src/04_Security/Ownable2Step.sol) | Security | Safe two-step ownership handover preventing lost admins | ~15,000 gas transfer |
| **#15** | [`PaymentSplitter.sol`](src/03_Governance/PaymentSplitter.sol) | Governance | Proportional native and token revenue sharing with pull claiming | ~273,000 gas split |
| **#16** | [`SocialRecoveryWallet.sol`](src/03_Governance/SocialRecoveryWallet.sol) | Governance | Guardian-based threshold account recovery with security delay | ~71,000 gas execute |
| **#17** | [`EmergencyPausable.sol`](src/04_Security/EmergencyPausable.sol) | Security | Circuit breaker emergency halt for state mutations during exploits | ~65,000 gas pause |
| **#18** | [`BlacklistGate.sol`](src/04_Security/BlacklistGate.sol) | Security | Compliance and sanctions filter blocking malicious addresses | ~69,000 gas check |
| **#19** | [`SpendingLimitAccount.sol`](src/03_Governance/SpendingLimitAccount.sol) | Governance | Rolling 24-hour operator withdrawal quota enforcement | ~109,000 gas withdraw |
| **#20** | [`DeadManSwitch.sol`](src/03_Governance/DeadManSwitch.sol) | Governance | Heartbeat-dependent cryptocurrency inheritance trigger | ~62,000 gas ping |
| **#21** | [`ConstantProductAMM.sol`](src/02_DeFi/ConstantProductAMM.sol) | DeFi | $x \cdot y = k$ swap invariant with TWAP cumulative price accumulators | ~400,000 gas swap |
| **#22** | [`ConcentratedLiquidityPool.sol`](src/02_DeFi/ConcentratedLiquidityPool.sol) | DeFi | Uniswap v3 style $Q64.96$ tick-range concentrated liquidity AMM | ~212,000 gas mint |
| **#23** | [`DutchAuction.sol`](src/02_DeFi/DutchAuction.sol) | DeFi | Descending price auction with linear decay & refund | ~143,000 gas buy |
| **#24** | [`EnglishAuction.sol`](src/02_DeFi/EnglishAuction.sol) | DeFi | Ascending auction with pull-over-push anti-DoS refunds | ~411,000 gas lifecycle |
| **#25** | [`OrderBookDEX.sol`](src/02_DeFi/OrderBookDEX.sol) | DeFi | On-chain limit order book matching and partial/full settlement | ~259,000 gas place |
| **#26** | [`StableSwapAMM.sol`](src/02_DeFi/StableSwapAMM.sol) | DeFi | Curve amplification coefficient ($A$) Stableswap invariant with Newton-Raphson | ~130,000 gas swap |
| **#28** | [`TWAMM.sol`](src/02_DeFi/TWAMM.sol) | DeFi | Time-Weighted AMM long-term order virtual slicing engine | ~327,000 gas order |
| **#29** | [`LiquidityBootstrappingPool.sol`](src/02_DeFi/LiquidityBootstrappingPool.sol) | DeFi | Balancer-style dynamic weight-shifting anti-bot token auction pool | ~128,000 gas swap |
| **#31** | [`StakingRewards.sol`](src/02_DeFi/StakingRewards.sol) | DeFi | Synthetix continuous proportional reward distribution engine | ~351,000 gas stake |
| **#32** | [`CollateralizedDebtPosition.sol`](src/02_DeFi/CollateralizedDebtPosition.sol) | DeFi | MakerDAO-style overcollateralized stablecoin borrowing and liquidation | ~229,000 gas borrow |
| **#33** | [`FlashLender.sol`](src/02_DeFi/FlashLender.sol) | DeFi | ERC-3156 compliant uncollateralized flash loan provider | ~98,000 gas loan |
| **#35** | [`AutoCompoundingVault.sol`](src/02_DeFi/AutoCompoundingVault.sol) | DeFi | Yearn-style yield harvest and automated reinvestment controller | ~277,000 gas deposit |
| **#37** | [`PeerToPeerLending.sol`](src/02_DeFi/PeerToPeerLending.sol) | DeFi | Bilateral isolated loan agreements with escrowed collateral | ~481,000 gas lifecycle |
| **#38** | [`VariableRateMarket.sol`](src/02_DeFi/VariableRateMarket.sol) | DeFi | Dynamic utilization-based kinked interest rate borrow market | ~219,000 gas borrow |
| **#39** | [`FixedTermBond.sol`](src/02_DeFi/FixedTermBond.sol) | DeFi | Zero-coupon discount bond issuance and par redemption at maturity | ~503,000 gas flow |
| **#41** | [`MerkleAirdrop.sol`](src/05_Cryptographic/MerkleAirdrop.sol) | Cryptography | 256-bit bitfield bitmap claim tracker with Merkle proofs | ~118,000 gas claim |
| **#42** | [`EIP712MetaTransactions.sol`](src/05_Cryptographic/EIP712MetaTransactions.sol) | Cryptography | ERC-2771 / EIP-712 structured data gasless forwarder | ~154,000 gas forward |
| **#43** | [`CommitReveal.sol`](src/05_Cryptographic/CommitReveal.sol) | Cryptography | MEV-resistant commit-reveal sealed-bid scheme | ~326,000 gas flow |
| **#45** | [`ECDSAKeyRecovery.sol`](src/05_Cryptographic/ECDSAKeyRecovery.sol) | Cryptography | Malleability-safe standard and compact (EIP-2098) ECDSA signature recovery | ~17,000 gas recover |
| **#46** | [`HTLC.sol`](src/05_Cryptographic/HTLC.sol) | Cryptography | Hash Time-Locked Contract for cross-chain atomic swaps | ~252,000 gas withdraw |
| **#51** | [`TransientReentrancyGuard.sol`](src/04_Security/TransientReentrancyGuard.sol) | Cancun EVM | EIP-1153 transient storage (`tstore`/`tload`) 100-gas reentrancy lock | ~100 gas lock vs 2,100 SSTORE |
| **#52** | [`BitPackingStorageEngine.sol`](src/06_CancunEVM/BitPackingStorageEngine.sol) | Cancun EVM | Multi-variable packing of 5 data types into a single 32-byte slot | 1 SSTORE (~20k gas) |
| **#54** | [`TransientFeeCalculator.sol`](src/06_CancunEVM/TransientFeeCalculator.sol) | Cancun EVM | EIP-1153 zero-SSTORE intra-transaction fee accumulator | ~107,000 gas batch route |
| **#57** | [`GasOptimizedMathLib.sol`](src/06_CancunEVM/GasOptimizedMathLib.sol) | Cancun EVM | Pure Yul assembly fixed-point WAD ($10^{18}$) and RAY ($10^{27}$) math library | ~11,000 gas operation |
| **#58** | [`BitMapFlagRegistry.sol`](src/06_CancunEVM/BitMapFlagRegistry.sol) | Cancun EVM | 256 boolean flags per storage word, cutting storage costs by 99% | ~22,000 gas / flag write |
| **#61** | [`ERC1967UUPSProxy.sol`](src/06_Upgradeability/ERC1967UUPSProxy.sol) | Proxies | Universal Upgradeable Proxy Standard with ERC-1967 storage slots | ~175,000 gas upgrade |
| **#62** | [`TransparentUpgradeableProxy.sol`](src/06_Upgradeability/TransparentUpgradeableProxy.sol) | Proxies | EIP-1967 Transparent proxy with strict admin/user selector segregation | ~118,000 gas upgrade |
| **#63** | [`MinimalProxyFactory.sol`](src/06_Upgradeability/MinimalProxyFactory.sol) | Proxies | EIP-1167 minimal bytecode clone deployer (CREATE & CREATE2) | ~80,000 gas clone |
| **#64** | [`DiamondPattern.sol`](src/06_Upgradeability/DiamondPattern.sol) | Proxies | ERC-2535 multi-facet diamond proxy standard with granular cuts | ~128,000 gas route |
| **#65** | [`BeaconProxy.sol`](src/06_Upgradeability/BeaconProxy.sol) | Proxies | Centralized UpgradeableBeacon pointer enabling single-tx fleet upgrades | ~229,000 gas fleet upgrade |
| **#71** | [`GovernorBravo.sol`](src/03_Governance/GovernorBravo.sol) | DAOs | Full proposal lifecycle, quorum threshold, and on-chain vote execution | ~498,000 gas lifecycle |
| **#72** | [`QuadraticVotingEngine.sol`](src/03_Governance/QuadraticVotingEngine.sol) | DAOs | Sybil-resistant quadratic voting ballot aggregator ($\text{cost} = \text{votes}^2$) | ~334,000 gas vote |
| **#73** | [`RageQuitTreasury.sol`](src/03_Governance/RageQuitTreasury.sol) | DAOs | Moloch DAO inspired minority protection proportional ragequit redemption | ~340,000 gas ragequit |
| **#79** | [`StreamingPaymentPayroll.sol`](src/03_Governance/StreamingPaymentPayroll.sol) | DAOs | Second-by-second linear real-time token salary streaming | ~410,000 gas stream |
| **#81** | [`ModularSmartAccount.sol`](src/07_AccountAbstraction/ModularSmartAccount.sol) | Account Abstraction | ERC-4337 UserOperation signature validation and execution wallet | ~54,000 gas validate |
| **#82** | [`VerifyingPaymaster.sol`](src/07_AccountAbstraction/VerifyingPaymaster.sol) | Account Abstraction | ERC-4337 off-chain backend signature gas sponsorship paymaster | ~29,000 gas validate |
| **#83** | [`SessionKeyPlugin.sol`](src/07_AccountAbstraction/SessionKeyPlugin.sol) | Account Abstraction | Granular scoped session keys restricting target, selector, spend & expiry | ~214,000 gas session |
| **#89** | [`BatchTransactionAggregator.sol`](src/07_AccountAbstraction/BatchTransactionAggregator.sol) | Account Abstraction | Multi-target atomic batch execution with failure tolerance | ~100,000 gas batch |
| **#91** | [`TWAPOracle.sol`](src/08_Oracles/TWAPOracle.sol) | Oracles | Time-Weighted Average Price cumulative observation accumulator | ~182,000 gas consult |
| **#92** | [`ChainlinkFallbackOracle.sol`](src/08_Oracles/ChainlinkFallbackOracle.sol) | Oracles | Resilient Chainlink Aggregator V3 consumer with heartbeat bounds & fallback | ~192,000 gas resolve |
| **#93** | [`CrossChainTokenBridge.sol`](src/09_CrossChain/CrossChainTokenBridge.sol) | Cross-Chain | Replay-protected lock-and-mint / burn-and-mint validator attestation bridge | ~268,000 gas lock |
| **#94** | [`MEVBackrunShield.sol`](src/08_Oracles/MEVBackrunShield.sol) | MEV Defense | Private RPC bundle verification and backrun arbitrage profit sharing | ~153,000 gas rebate |

*For the complete 100-project roadmap specifications, see [`ROADMAP.md`](ROADMAP.md).*

---

## 🧪 Testing & Invariant Verification

Run the entire test suite via Foundry:

```bash
# Build contracts with Solc 0.8.26 on Cancun
forge build

# Run all 151 unit, integration, and fuzz tests
forge test

# Run tests with detailed call traces
forge test -vvv

# Generate gas report across all contracts
forge test --gas-report
```

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
