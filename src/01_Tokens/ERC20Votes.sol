// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @title ERC20Votes
/// @notice Checkpoint-based voting power tracker and delegation extension for ERC-20.
/// @dev Implements historical voting snapshot queries with binary search.
contract ERC20Votes {
    // --- Errors ---
    error InsufficientBalance();
    error InsufficientAllowance();
    error BlockNotYetMined();
    error ZeroAddress();

    // --- Events ---
    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);
    event DelegateVotesChanged(address indexed delegate, uint256 previousVotes, uint256 newVotes);

    // --- Structs ---
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    // --- State Variables ---
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    mapping(address => address) public delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    // --- ERC-20 Methods ---

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 currentAllowance = allowance[from][msg.sender];
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) revert InsufficientAllowance();
            unchecked {
                allowance[from][msg.sender] = currentAllowance - amount;
            }
        }
        _transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        if (to == address(0)) revert ZeroAddress();
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);

        _moveVotingPower(address(0), delegates[to], amount);
        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    function burn(address from, uint256 amount) external {
        if (balanceOf[from] < amount) revert InsufficientBalance();
        balanceOf[from] -= amount;
        totalSupply -= amount;
        emit Transfer(from, address(0), amount);

        _moveVotingPower(delegates[from], address(0), amount);
        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    function _transfer(address from, address to, uint256 amount) internal {
        if (to == address(0)) revert ZeroAddress();
        if (balanceOf[from] < amount) revert InsufficientBalance();

        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);

        _moveVotingPower(delegates[from], delegates[to], amount);
    }

    // --- Voting & Delegation ---

    function delegate(address delegatee) external {
        address currentDelegate = delegates[msg.sender];
        delegates[msg.sender] = delegatee;
        emit DelegateChanged(msg.sender, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, balanceOf[msg.sender]);
    }

    function getVotes(address account) external view returns (uint256) {
        uint256 nCheckpoints = _checkpoints[account].length;
        return nCheckpoints == 0 ? 0 : _checkpoints[account][nCheckpoints - 1].votes;
    }

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        if (blockNumber >= block.number) revert BlockNotYetMined();
        return _binarySearchCheckpoints(_checkpoints[account], blockNumber);
    }

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256) {
        if (blockNumber >= block.number) revert BlockNotYetMined();
        return _binarySearchCheckpoints(_totalSupplyCheckpoints, blockNumber);
    }

    // --- Internal Helpers ---

    function _moveVotingPower(address src, address dst, uint256 amount) internal {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }
            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) pure returns (uint256) op,
        uint256 delta
    ) internal returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;
        oldWeight = pos == 0 ? 0 : ckpts[pos - 1].votes;
        newWeight = op(oldWeight, delta);

        if (pos > 0 && ckpts[pos - 1].fromBlock == block.number) {
            ckpts[pos - 1].votes = uint224(newWeight);
        } else {
            ckpts.push(Checkpoint({fromBlock: uint32(block.number), votes: uint224(newWeight)}));
        }
    }

    function _binarySearchCheckpoints(Checkpoint[] storage ckpts, uint256 blockNumber) internal view returns (uint256) {
        uint256 len = ckpts.length;
        if (len == 0) return 0;
        if (ckpts[len - 1].fromBlock <= blockNumber) return ckpts[len - 1].votes;
        if (ckpts[0].fromBlock > blockNumber) return 0;

        uint256 low = 0;
        uint256 high = len - 1;

        while (low < high) {
            uint256 mid = (low + high + 1) / 2;
            if (ckpts[mid].fromBlock <= blockNumber) {
                low = mid;
            } else {
                high = mid - 1;
            }
        }
        return ckpts[low].votes;
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }
}
