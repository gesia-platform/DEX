import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const ERC1155TokenModule = buildModule('ERC1155TokenModule', (m) => {
	const url = m.getParameter('url', 'http://localhost:8000');
	const erc1155Token = m.contract('ERC1155Token', [url]);

	return { erc1155Token };
});

export default ERC1155TokenModule;
