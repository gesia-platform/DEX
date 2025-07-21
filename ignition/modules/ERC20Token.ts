import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const ERC20TokenModule = buildModule('ERC20TokenModule', (m) => {
	const erc20Token = m.contract('ERC20Token', []);

	return { erc20Token };
});

export default ERC20TokenModule;
