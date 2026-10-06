// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title FixedTermBond
/// @notice Zero-coupon fixed-term discount bond primitive redeemable at face value upon maturity.
contract FixedTermBond {
    // --- Errors ---
    error ZeroAmount();
    error BondNotMatured();
    error BondAlreadyMatured();
    error InsufficientSupply();
    error TransferFailed();

    // --- Structs ---
    struct Bond {
        address issuer;
        address settlementToken;
        uint256 faceValuePerBond; // e.g. 100 USDC par
        uint256 discountPrice; // e.g. 95 USDC purchase price
        uint256 maturity;
        uint256 totalBonds;
        uint256 soldBonds;
    }

    uint256 public nextBondId;
    mapping(uint256 => Bond) public bonds;
    mapping(uint256 => mapping(address => uint256)) public bondBalances;

    event BondIssued(uint256 indexed bondId, address indexed issuer, uint256 totalBonds, uint256 maturity);
    event BondPurchased(uint256 indexed bondId, address indexed buyer, uint256 count);
    event BondRedeemed(uint256 indexed bondId, address indexed holder, uint256 count, uint256 payout);

    /// @notice Issuer deposits face value to back the full issuance
    function issueBond(
        address settlementToken,
        uint256 count,
        uint256 faceValue,
        uint256 discountPrice,
        uint256 maturity
    ) external returns (uint256 bondId) {
        if (count == 0 || faceValue == 0 || maturity <= block.timestamp) revert ZeroAmount();

        bondId = nextBondId++;
        bonds[bondId] = Bond({
            issuer: msg.sender,
            settlementToken: settlementToken,
            faceValuePerBond: faceValue,
            discountPrice: discountPrice,
            maturity: maturity,
            totalBonds: count,
            soldBonds: 0
        });

        // Issuer deposits the total face value redemption reserve
        uint256 totalReserve = count * faceValue;
        _safeTransferFrom(settlementToken, msg.sender, address(this), totalReserve);

        emit BondIssued(bondId, msg.sender, count, maturity);
    }

    /// @notice Buyer purchases bonds at discounted price; proceeds go to issuer
    function buyBonds(uint256 bondId, uint256 count) external {
        Bond storage bond = bonds[bondId];
        if (block.timestamp >= bond.maturity) revert BondAlreadyMatured();
        if (bond.soldBonds + count > bond.totalBonds) revert InsufficientSupply();

        bond.soldBonds += count;
        bondBalances[bondId][msg.sender] += count;

        uint256 totalCost = count * bond.discountPrice;
        _safeTransferFrom(bond.settlementToken, msg.sender, bond.issuer, totalCost);

        emit BondPurchased(bondId, msg.sender, count);
    }

    /// @notice Bondholder redeems bonds at face value after maturity
    function redeemBonds(uint256 bondId, uint256 count) external {
        Bond storage bond = bonds[bondId];
        if (block.timestamp < bond.maturity) revert BondNotMatured();
        if (bondBalances[bondId][msg.sender] < count) revert InsufficientSupply();

        bondBalances[bondId][msg.sender] -= count;
        uint256 payout = count * bond.faceValuePerBond;

        _safeTransfer(bond.settlementToken, msg.sender, payout);

        emit BondRedeemed(bondId, msg.sender, count, payout);
    }

    function _safeTransfer(address token, address to, uint256 amount) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }

    function _safeTransferFrom(address token, address from, address to, uint256 amount) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSignature("transferFrom(address,address,uint256)", from, to, amount));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
