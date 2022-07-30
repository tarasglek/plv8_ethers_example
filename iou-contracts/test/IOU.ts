import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("Lock", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshopt in every test.
  async function deployIOU_Fixture() {
    // Contracts are deployed using the first signer/account by default
    const [lender, otherAccount] = await ethers.getSigners();

    const IOU = await ethers.getContractFactory("IOU");
    const iou = await IOU.deploy();

    return { iou, lender, otherAccount };
  }

  describe("Deployment", function () {
    it("first test", async function () {
      const { iou, lender, otherAccount } = await loadFixture(deployIOU_Fixture);
      expect(await iou.lenderTotalLent(lender.address)).to.equal(0);
      // expect(await lock.unlockTime()).to.equal(unlockTime);
    });
  });
});
