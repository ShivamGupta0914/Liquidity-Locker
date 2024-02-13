const { expect } = require("chai");
const  { loadFixture} = require("@nomicfoundation/hardhat-network-helpers");
const  helpers = require("@nomicfoundation/hardhat-network-helpers");

const { ethers } = require("hardhat");

describe("Token contract", function () {

  async function deployTokenFixture() {
    const [deployer, user1, user2] = await ethers.getSigners();
    const coinsContract = await ethers.getContractFactory("Coins");
    const Coins = await coinsContract.deploy("Shiva", "SHIVA");
    await Coins.deployed();
    const coins2 = await ethers.getContractFactory("Coins2");
    const Coins2 = await coins2.deploy("ERC777Shiva", "SHIVA777", 100000);
    await Coins2.deployed();
    const locker = await ethers.getContractFactory("Locker");
    const Locker = await locker.deploy(Coins.address, Coins2.address);
    await Locker.deployed();
    return { Locker, Coins, Coins2, deployer, user1, user2 };
  }

  it("should switch roles", async function () {
    const { Locker, user1 } = await loadFixture(deployTokenFixture);
    await Locker.switchRole();
    await Locker.switchRole();
    await Locker.switchRole();
    await expect(Locker.connect(user1).switchRole()).to.be.revertedWith("you are not authorized for any action");
  });

  it("should be able to change the rewards list", async function () {
    const { Locker, user1 } = await loadFixture(deployTokenFixture);
    await Locker.setRewards(60, 5);
    expect(await Locker.rewardChart(60)).to.equal(5);
    await expect(Locker.connect(user1).setRewards(60, 5)).to.be.revertedWith("you are not authorized for any action");
  });

  it("should return the rewards according to time entered in seconds", async function () {
    const { Locker } = await loadFixture(deployTokenFixture);
    expect(await Locker.rewardChart(60)).to.equal(3);
    expect(await Locker.rewardChart(61)).to.equal(3);
    expect(await Locker.rewardChart(36000)).to.equal(8);
    expect(await Locker.rewardChart(1800)).to.equal(6);
    expect(await Locker.rewardChart(10)).to.equal(0);
  });

  it("user should be able to invest ERC20 token successfully", async function () {
    const { Locker, user1, Coins } = await loadFixture(deployTokenFixture);
    await expect(Locker.investERC20(0, Coins.address)).to.be.revertedWith("amount should be greater than 100");
    await expect(Locker.investERC20(200, Coins.address)).to.be.revertedWith("please allow the contract to invest tokens with the given amount");
    await Coins.approve(Locker.address, 200);
    await Locker.investERC20(200, Coins.address);
    await expect(Locker.investERC20(200, Coins.address)).to.be.revertedWith("you have already invested");
  });

  it("user should be able to invest ERC777 token successfully", async function () {
    const { Locker, Coins, Coins2, deployer, user1 } = await loadFixture(deployTokenFixture);
    await expect(Locker.investERC777(0, Coins2.address)).to.be.revertedWith("amount should be greater than 100");
    await expect(Locker.investERC777(200, Coins2.address)).to.be.revertedWith("please allow the contract to invest tokens with the given amount");
    await Coins2.authorizeOperator(Locker.address);
    await Locker.investERC777(200, Coins2.address);
    await expect(Locker.investERC777(200, Coins2.address)).to.be.revertedWith("you have already invested");
  });

  it("user can withdraw his tokens", async function () {
    const { Locker, Coins, Coins2, deployer, user1 } = await loadFixture(deployTokenFixture);
    await Coins2.send(Locker.address, 200, 0x00);
    await Coins2.authorizeOperator(Locker.address);
    await Locker.investERC777(200, Coins2.address);
    await expect(Locker.connect(user1).withdraw()).to.be.revertedWith("you have not invested here anymore");
    await expect(Locker.withdraw()).that.be.revertedWith("you can not withdraw money before cliff time");
    await helpers.time.increase(61);
    await Locker.withdraw();
    expect(await Coins2.balanceOf(deployer.address)).to.equal(100000- 200 - 200 + 4 + 201);
  });

  it("should workk getMoney for ERC20", async function () {
    const { Locker, Coins, Coins2, deployer, user1 } = await loadFixture(deployTokenFixture);

    await Coins.transfer(Locker.address, 200);
    await Coins.approve(Locker.address, 200);
    await Locker.investERC20(200, Coins.address);
    await expect(Locker.connect(user1).withdraw()).to.be.revertedWith("you have not invested here anymore");
    await expect(Locker.withdraw()).that.be.revertedWith("you can not withdraw money before cliff time");
    console.log(await Coins.balanceOf(deployer.address));
    await helpers.time.increase(61);
    await Locker.withdraw();
  });


});