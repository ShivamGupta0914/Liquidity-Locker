// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;
import "./IERC20.sol";
import "./IERC777.sol";

contract Locker {
    uint256 public constant CLIFFDURATION = 60;
    address private owner;
    address public coins20Address;
    address public coins777Address;
    mapping(uint256 => uint256) private rewardChartSeconds;
    mapping(address => information) public userInformation;
    IERC20 private ERC20;
    IERC777 private ERC777;
    Roles currentRole;
    struct information {
        uint256 investedAmount;
        uint256 startingInvestedTime;
        address referredTokenAddresses;
        uint16 referredTokenNumber;
    }
    enum Roles {
        FeeManager,
        ReferalManager
    }

    constructor(address _erc20Address, address _erc777Address) {
        owner = msg.sender;
        rewardChartSeconds[60] = 3;
        rewardChartSeconds[1800] = 6;
        rewardChartSeconds[3600] = 8;
        coins20Address = _erc20Address;
        coins777Address = _erc777Address;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "you are not authorized for any action");
        _;
    }

    modifier onlyOnce() {
        require(
            userInformation[msg.sender].investedAmount == 0,
            "you have already invested"
        );
        _;
    }

    function switchRole() external onlyOwner {
        if (currentRole == Roles.FeeManager) {
            currentRole = Roles.ReferalManager;
        } else {
            currentRole = Roles.FeeManager;
        }
    }

    function setRewards(
        uint256 _timingInSeconds,
        uint _rewardValue
    ) external onlyOwner {
        rewardChartSeconds[_timingInSeconds] = _rewardValue;
    }

    function withdraw() external {
        require(
            userInformation[msg.sender].startingInvestedTime > 0,
            "you have not invested here anymore"
        );
        uint256 timeInvested = block.timestamp -
            userInformation[msg.sender].startingInvestedTime;
        require(
            timeInvested >= CLIFFDURATION,
            "you can not withdraw money before cliff time"
        );

        uint256 rewardPercentage;
        if (timeInvested >= 3600) {
            rewardPercentage = rewardChartSeconds[3600];
        } else if (timeInvested >= 1800) {
            rewardPercentage = rewardChartSeconds[1800];
        } else {
            rewardPercentage = rewardChartSeconds[60];
        }

        uint256 rewardedAmount = ((userInformation[msg.sender].investedAmount) *
            (rewardPercentage)) / (100);
        if (userInformation[msg.sender].referredTokenNumber == 777) {
            ERC777.send(
                msg.sender,
                userInformation[msg.sender].investedAmount,
                ""
            );
            IERC777(coins777Address).send(msg.sender, rewardedAmount, "");
        } else {
            ERC20.transfer(
                msg.sender,
                userInformation[msg.sender].investedAmount
            );
            IERC20(coins20Address).transfer(msg.sender, rewardedAmount);
        }
        delete userInformation[msg.sender];
    }

    function rewardChart(uint256 _seconds) external view returns (uint256) {
        if (_seconds >= 3600) {
            return rewardChartSeconds[3600];
        } else if (_seconds >= 1800) {
            return rewardChartSeconds[1800];
        } else if (_seconds >= 60) {
            return rewardChartSeconds[60];
        } else {
            return 0;
        }
    }

    function investERC20(
        uint256 _amount,
        address _addressToken
    ) external onlyOnce {
        require(_amount >= 100, "amount should be greater than 100");
        uint256 amountForDeployer = _calculatComission(_amount);
        uint256 leftInvestedAmount = _amount - amountForDeployer;

        ERC20 = IERC20(_addressToken);
        require(
            ERC20.allowance(msg.sender, address(this)) >= _amount,
            "please allow the contract to invest tokens with the given amount"
        );
        ERC20.transferFrom(msg.sender, owner, amountForDeployer);
        ERC20.transferFrom(msg.sender, address(this), leftInvestedAmount);
        _setInformationForUser(20, leftInvestedAmount, _addressToken);
    }

    function investERC777(
        uint256 _amount,
        address _addressToken
    ) external onlyOnce {
        require(_amount >= 100, "amount should be greater than 100");
        uint256 amountForDeployer = _calculatComission(_amount);
        uint256 leftInvestedAmount = _amount - amountForDeployer;

        ERC777 = IERC777(_addressToken);
        require(
            ERC777.isOperatorFor(address(this), msg.sender) == true,
            "please allow the contract to invest tokens with the given amount"
        );

        ERC777.operatorSend(msg.sender, owner, amountForDeployer, "", "");
        ERC777.operatorSend(
            msg.sender,
            address(this),
            leftInvestedAmount,
            "",
            ""
        );
        _setInformationForUser(777, leftInvestedAmount, _addressToken);
    }

    function _setInformationForUser(
        uint16 _tokenNumber,
        uint256 _investment,
        address _tokenAddress
    ) internal {
        userInformation[msg.sender].referredTokenNumber = _tokenNumber;
        userInformation[msg.sender].investedAmount = _investment;
        userInformation[msg.sender].referredTokenAddresses = _tokenAddress;
        userInformation[msg.sender].startingInvestedTime = block.timestamp;
    }

    function _calculatComission(
        uint256 _amount
    ) internal view returns (uint256) {
        uint256 amountForDeployer;
        if (currentRole == Roles.FeeManager) {
            amountForDeployer = (_amount * 2) / (100);
        } else {
            amountForDeployer = (_amount * 1) / (100);
        }
        return amountForDeployer;
    }
}
