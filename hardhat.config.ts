import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";


const ALCHEMY_API_KEY = vars.get("ALCHEMY_API_KEY");
const ARB_SCAN_API_KEY = vars.get("ARB_SCAN_API_KEY");

const config: HardhatUserConfig = {
    solidity: "0.8.27",

    networks: {
        arbitrumSepolia: {
            url: `https://arb-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}`,
            accounts: vars.has("PRIVATE_KEY") ? [vars.get("PRIVATE_KEY")] : [],
        },
    },

    etherscan: {
        apiKey: ARB_SCAN_API_KEY,
        customChains: [
            {
                network: "arbitrumSepolia",
                chainId: 421614,
                urls: {
                    apiURL: "https://arb-sepolia.g.alchemy.com/v2/${ALCHEMY_API_KEY}",
                    browserURL: "https://sepolia.arbiscan.io/"
                }
            }
        ],
    },

};

export default config;