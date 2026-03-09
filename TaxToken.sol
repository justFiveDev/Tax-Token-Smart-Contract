// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract PumpToken {
    string public name;
    string public symbol;
    uint8 public decimals;

    address public factory;
    address public creator;
    address public treasury;
    address public uniswapMarketingWallet;
    address public uniswapDevelopmentWallet;

    bool public isBondingCurve;
    bool public initialized;
    uint256 public maxSupply;

    uint256 public taxFeeToTreasury;
    uint256 public uniswapMarketingTaxFee;
    uint256 public uniswapDevelopmentTaxFee;
    uint256 public uniswapCreatorTaxFee;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    function initialize(
        string memory _name,
        string memory _symbol,
        address _creator,
        address _uniswapMarketingWallet,
        address _uniswapDevelopmentWallet,
        address _treasury,
        uint256 _uniswapMarketingTaxFee,
        uint256 _uniswapDevelopmentTaxFee,
        uint256 _uniswapCreatorTaxFee,
        uint256 _feeTreasury,
        uint256 _maxSupply
    ) external {
        require(!initialized, "Already initialized");
        name = _name;
        symbol = _symbol;
        creator = _creator;
        factory = msg.sender;
        treasury = _treasury;

        uniswapMarketingWallet = _uniswapMarketingWallet;
        uniswapDevelopmentWallet = _uniswapDevelopmentWallet;

        uniswapMarketingTaxFee = _uniswapMarketingTaxFee;
        uniswapDevelopmentTaxFee = _uniswapDevelopmentTaxFee;
        uniswapCreatorTaxFee = _uniswapCreatorTaxFee;
        taxFeeToTreasury = _feeTreasury;
        maxSupply = _maxSupply;

        decimals = 18;
        isBondingCurve = true;
        initialized = true;
    }

    function setIsBondingCurve(bool _isBondingCurve) external onlyFactory {
        isBondingCurve = _isBondingCurve;
    }

    function _mint(address to, uint256 amount) internal {
        require(to != address(0), "Mint to zero address");
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function mintFromFactory(address to, uint256 amount) external onlyFactory {
        require(totalSupply + amount <= maxSupply, "Cap exceeded");
        _mint(to, amount);
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        allowance[msg.sender][spender] += addedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 current = allowance[msg.sender][spender];
        require(current >= subtractedValue, "Decreased below zero");
        allowance[msg.sender][spender] = current - subtractedValue;
        emit Approval(msg.sender, spender, allowance[msg.sender][spender]);
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        _transfer(msg.sender, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        allowance[from][msg.sender] -= amount;
        _transfer(from, to, amount);
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "From zero address");
        require(to != address(0), "To zero address");
        require(balanceOf[from] >= amount, "Insufficient balance");

        // Deduct total from sender
        balanceOf[from] -= amount;

        uint256 feeTreasury = 0;
        uint256 feeMarketing = 0;
        uint256 feeDevelopment = 0;
        uint256 feeCreator = 0;

        if (!isBondingCurve) {
            feeTreasury = (amount * taxFeeToTreasury) / 10000;
            feeMarketing = (amount * uniswapMarketingTaxFee) / 10000;
            feeDevelopment = (amount * uniswapDevelopmentTaxFee) / 10000;
            feeCreator = (amount * uniswapCreatorTaxFee) / 10000;
        }

        uint256 totalFee = feeTreasury + feeMarketing + feeDevelopment + feeCreator;
        uint256 amountAfterFee = amount - totalFee;

       

        // Transfer fees to fee wallets
        if (feeTreasury > 0) {
            balanceOf[treasury] += feeTreasury;
            emit Transfer(from, treasury, feeTreasury);
        }
        if (feeMarketing > 0) {
            balanceOf[uniswapMarketingWallet] += feeMarketing;
            emit Transfer(from, uniswapMarketingWallet, feeMarketing);
        }
        if (feeDevelopment > 0) {
            balanceOf[uniswapDevelopmentWallet] += feeDevelopment;
            emit Transfer(from, uniswapDevelopmentWallet, feeDevelopment);
        }
        if (feeCreator > 0) {
            balanceOf[creator] += feeCreator;
            emit Transfer(from, creator, feeCreator);
        }

         // Transfer net amount to recipient
        balanceOf[to] += amountAfterFee;
        emit Transfer(from, to, amountAfterFee);
    }
}