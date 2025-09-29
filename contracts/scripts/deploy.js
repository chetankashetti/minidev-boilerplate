const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  
  console.log("Deploying contracts with account:", deployer.address);
  console.log("Account balance:", ethers.formatEther(await deployer.provider.getBalance(deployer.address)), "ETH");
  
  // Deploy ERC20 Template
  const ERC20Template = await ethers.getContractFactory("ERC20Template");
  const erc20Template = await ERC20Template.deploy(
    "Token", "TK", 18, ethers.parseEther("1000000")
  );
  await erc20Template.waitForDeployment();
  
  console.log("✅ ERC20Template deployed to:", await erc20Template.getAddress());
  // Save deployment info for frontend
  const fs = require('fs');
  const deploymentInfo = {
    ERC20Template: await erc20Template.getAddress(),
    deployer: deployer.address,
    network: 'baseSepolia', // Explicitly set to Base Sepolia
    chainId: 84532, // Base Sepolia chain ID
    rpcUrl: process.env.BASE_SEPOLIA_RPC_URL || 'https://sepolia.base.org',
    timestamp: new Date().toISOString(),
    transactionHash: await erc20Template.deploymentTransaction()?.hash
  };
  
  try {
    fs.writeFileSync('./deployment-info.json', JSON.stringify(deploymentInfo, null, 2));
    console.log("📄 Deployment info saved to deployment-info.json");
  } catch (error) {
    console.log("⚠️  Could not save deployment info:", error.message);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Deployment failed:", error);
    process.exit(1);
  });
