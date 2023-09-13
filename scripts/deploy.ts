import { ethers } from "hardhat";

async function main() {

  const stablecoinEscrow = await ethers.deployContract("StablecoinEscrow");

  await stablecoinEscrow.waitForDeployment();

  console.log("StablecoinEscrow deployed to : ",await stablecoinEscrow.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
