import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const DexContractModule = buildModule('DexContractModule', (m) => {
	const operatorManger = m.getParameter('_operatorManager', process.env.OPERATOR_MANAGER_CONTRACT_ADDRESS);
	const dexContract = m.contract('DexContractNew', [operatorManger]);

	return { dexContract };
});

export default DexContractModule;
