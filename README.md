# 💯 100 Solidity Smart Contract Projects (Production Architecture)

[![Foundry](https://img.shields.io/badge/Foundry-v1.8.4-red.svg)](https://getfoundry.sh/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Solidity](https://img.shields.io/badge/Solidity-0.8.26-363636.svg)](https://soliditylang.org/)
[![Cancun EVM](https://img.shields.io/badge/EVM-Cancun%20(EIP--1153)-blue.svg)](https://eips.ethereum.org/EIPS/eip-1153)

A production-grade, battle-tested open-source curriculum of **100 Solidity Smart Contract Projects** engineered for modern EVM protocols, Layer 2 networks, and decentralized finance.

All contracts feature comprehensive **Foundry test suites (47/47 tests passing)**, gas telemetry, custom errors, and Cancun EVM optimizations.

---

## 🏛️ Implemented Core Protocols & Benchmarks

| Project # | Protocol / Contract | Category | Core Innovation | Gas Profile / Status |
| :--- | :--- | :--- | :--- | :--- |
| **#01** | [`ERC20Permit.sol`](src/01_Tokens/ERC20Permit.sol) | Tokens | EIP-2612 gasless permit approval, immutable domain separator | ~51,000 gas transfer |
| **#02** | [`ERC721NFT.sol`](src/01_Tokens/ERC721NFT.sol) | Tokens | EIP-721 NFT with EIP-2981 on-chain royalty standard | ~91,000 gas transfer |
| **#03** | [`ERC1155MultiToken.sol`](src/01_Tokens/ERC1155MultiToken.sol) | Tokens | EIP-1155 multi-token standard with batch transfers | ~78,000 gas transfer |
| **#04** | [`ERC4626YieldVault.sol`](src/01_Tokens/ERC4626YieldVault.sol) | Tokens | EIP-4626 yield vault with virtual shares inflation defense | ~228,000 gas deposit |
| **#06** | [`WETH9.sol`](src/01_Tokens/WETH9.sol) | Tokens | Canonical Wrapped Ether native conversion | ~121,000 gas deposit |
| **#10** | [`VestingWallet.sol`](src/01_Tokens/VestingWallet.sol) | Tokens | Cliff and continuous linear token/ETH release schedule | ~114,000 gas release |
| **#11** | [`MultiSigWallet.sol`](src/03_Governance/MultiSigWallet.sol) | Governance | M-of-N multi-signature transaction consensus & execution | ~44,000 gas submit |
| **#12** | [`TimelockController.sol`](src/03_Governance/TimelockController.sol) | Governance | Time-delayed execution with grace periods and cancellation | ~142,000 gas execute |
| **#14** | [`Ownable2Step.sol`](src/04_Security/Ownable2Step.sol) | Security | Safe two-step ownership handover preventing lost admins | ~15,000 gas transfer |
| **#21** | [`ConstantProductAMM.sol`](src/02_DeFi/ConstantProductAMM.sol) | DeFi | $x \cdot y = k$ swap invariant with TWAP cumulative price accumulators | ~400,000 gas swap |
| **#23** | [`DutchAuction.sol`](src/02_DeFi/DutchAuction.sol) | DeFi | Descending price auction with linear decay & refund | ~143,000 gas buy |
| **#24** | [`EnglishAuction.sol`](src/02_DeFi/EnglishAuction.sol) | DeFi | Ascending auction with pull-over-push anti-DoS refunds | ~411,000 gas lifecycle |
| **#31** | [`StakingRewards.sol`](src/02_DeFi/StakingRewards.sol) | DeFi | Synthetix continuous proportional reward distribution engine | ~351,000 gas stake |
| **#33** | [`FlashLender.sol`](src/02_DeFi/FlashLender.sol) | DeFi | ERC-3156 compliant uncollateralized flash loan provider | ~98,000 gas loan |
| **#41** | [`MerkleAirdrop.sol`](src/05_Cryptographic/MerkleAirdrop.sol) | Cryptography | 256-bit bitfield bitmap claim tracker with Merkle proofs | ~118,000 gas claim |
| **#43** | [`CommitReveal.sol`](src/05_Cryptographic/CommitReveal.sol) | Cryptography | MEV-resistant commit-reveal sealed-bid scheme | ~326,000 gas flow |
| **#46** | [`HTLC.sol`](src/05_Cryptographic/HTLC.sol) | Cryptography | Hash Time-Locked Contract for cross-chain atomic swaps | ~252,000 gas withdraw |
| **#51** | [`TransientReentrancyGuard.sol`](src/04_Security/TransientReentrancyGuard.sol) | Security | EIP-1153 transient storage (`tstore`/`tload`) 100-gas reentrancy lock | ~100 gas lock vs 2,100 SSTORE |
| **#63** | [`MinimalProxyFactory.sol`](src/06_Upgradeability/MinimalProxyFactory.sol) | Proxies | EIP-1167 minimal bytecode clone deployer (CREATE & CREATE2) | ~80,000 gas clone |

*For the complete 100-project master plan spanning DAOs, Account Abstraction, Cross-Chain, and MEV, see [`ROADMAP.md`](ROADMAP.md).*

---

## 🧪 Testing & Invariant Verification

Run the entire test suite via Foundry:

```bash
# Build contracts with Solc 0.8.26 on Cancun
forge build

# Run all 47 unit, integration, and fuzz tests
forge test

# Run tests with detailed call traces
forge test -vvv

# Generate gas report across all contracts
forge test --gas-report
```

---

## 📄 License

This repository is licensed under the [MIT License](LICENSE).
