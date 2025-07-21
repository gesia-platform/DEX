import { buildModule } from '@nomicfoundation/hardhat-ignition/modules';

const OperatorManagerModule = buildModule('OperatorManagerModule', (m) => {
	const operatorManager = m.contract('OperatorManager', []);

	return { operatorManager };
});

export default OperatorManagerModule;
