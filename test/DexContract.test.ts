import { loadFixture } from '@nomicfoundation/hardhat-toolbox/network-helpers';
import { assert, expect } from 'chai';
import { ethers } from 'hardhat';

describe('DexContractNew', function () {
	let tokenID = 1; // 테스트에서 사용할 토큰 ID
	let amount = 100; // 수량
	let price = 100; // 가격

	async function deployDexContractFixture() {
		// 필요한 계약 인스턴스를 배포합니다.
		const ERC1155Token = await ethers.getContractFactory('ERC1155Token');
		const OperatorManager = await ethers.getContractFactory('OperatorManager');
		const DexContractNew = await ethers.getContractFactory('DexContractNew');

		// ERC1155 토큰과 OperatorManager, DexContractNew 계약을 배포합니다.
		const erc1155Token = await ERC1155Token.deploy(`http://localhost:8545`);
		const operatorManager = await OperatorManager.deploy();
		const dexContract = await DexContractNew.deploy(operatorManager.getAddress());

		const [user1, user2, user3] = await ethers.getSigners(); // 두 명의 사용자를 가져옵니다.

		return {
			erc1155Token,
			operatorManager,
			dexContract,
			user1,
			user2,
			user3,
		};
	}

	describe('Bid and Ask Orders', function () {
		// 사용자로 하여금 입찰(bid) 및 판매(ask) 주문을 생성할 수 있는지 테스트합니다.
		it('should allow a user to create a bid order', async function () {
			const { dexContract, user1, erc1155Token } = await loadFixture(deployDexContractFixture);

			// User1이 bidOrder 함수를 통해 입찰 주문을 생성합니다.
			await dexContract.connect(user1).bidOrder(erc1155Token.getAddress(), tokenID, amount, price, { value: amount * price });

			// 주문 생성 확인
			const order = await dexContract.connect(user1).detailOrder(1);
			expect(order.user).to.equal(user1.address); // 주문자의 주소가 user1의 주소와 일치하는지 확인
			expect(order.isBuyOrder).to.be.true; // isBuyOrder가 true인지 확인 (입찰 주문임을 나타냄)
			expect(order.amount).to.equal(amount); // 주문 수량이 올바른지 확인
			expect(order.price).to.equal(price); // 주문 가격이 올바른지 확인
		});

		it('should allow a user to create an ask order', async function () {
			const { erc1155Token, dexContract, user1 } = await loadFixture(deployDexContractFixture);

			// User1에게 토큰을 발행(mint)합니다.
			await erc1155Token.mint(user1.address, tokenID, amount);

			// Dex Contract에게 토큰을 위임(approve)합니다.
			await erc1155Token.connect(user1).setApprovalForAll(dexContract.getAddress(), true);

			// User1이 askOrder 함수를 통해 판매 주문을 생성합니다.
			await dexContract.connect(user1).askOrder(erc1155Token.getAddress(), tokenID, amount, price);

			// 주문 생성 확인
			const order = await dexContract.detailOrder(1);
			expect(order.user).to.equal(user1.address); // 주문자의 주소가 user1의 주소와 일치하는지 확인
			expect(order.isBuyOrder).to.be.false; // isBuyOrder가 false인지 확인 (판매 주문임을 나타냄)
			expect(order.amount).to.equal(amount); // 주문 수량이 올바른지 확인
			expect(order.price).to.equal(price); // 주문 가격이 올바른지 확인
		});

		it('should handle order execution', async function () {
			const { erc1155Token, dexContract, user1, user2 } = await loadFixture(deployDexContractFixture);

			// User1가 입찰 주문을 생성합니다.
			await dexContract.connect(user1).bidOrder(erc1155Token.getAddress(), tokenID, amount, price, { value: amount * price });

			// User2에게 토큰을 발행합니다.
			await erc1155Token.mint(user2.address, tokenID, amount);

			// Dex Contract에게 토큰을 위임(approve)합니다.
			await erc1155Token.connect(user2).setApprovalForAll(dexContract.getAddress(), true);

			// User2이 askOrder 함수를 통해 판매 주문을 생성합니다.
			await dexContract.connect(user2).askOrder(erc1155Token.getAddress(), tokenID, amount, price);

			// 주문을 실행합니다.
			await dexContract.connect(user1).executeOrder([1], [2], [amount]);

			// 토큰 이전 및 잔고 확인
			const user1Balance = await erc1155Token.balanceOf(user1.address, tokenID);
			const user2Balance = await erc1155Token.balanceOf(user2.address, tokenID);
			expect(user1Balance).to.equal(amount); // User1의 잔고가 올바른 수량인지 확인
			expect(user2Balance).to.equal(0); // User2의 잔고가 0인지 확인 (모든 토큰이 User1로 이전됨)
		});

		it('should allow order cancellation', async function () {
			const { erc1155Token, dexContract, user1 } = await loadFixture(deployDexContractFixture);

			// User1에게 토큰을 발행하고 판매 주문을 생성합니다.
			await erc1155Token.mint(user1.address, tokenID, amount);
			await erc1155Token.connect(user1).setApprovalForAll(dexContract.getAddress(), true);
			await dexContract.connect(user1).askOrder(erc1155Token.getAddress(), tokenID, amount, price);

			// 주문을 취소합니다.
			await dexContract.connect(user1).cancelOrder([1]);

			// 주문이 비활성 상태인지 확인
			const order = await dexContract.detailOrder(1);
			expect(order.isActive).to.be.false; // isActive가 false인지 확인 (주문이 취소됨)
		});

		it('should successfully execute a valid bid and ask order', async function () {
			const { erc1155Token, dexContract, user1, user2 } = await loadFixture(deployDexContractFixture);

			const bidAmount = 10;
			const bidPrice = 150;
			await dexContract.connect(user1).bidOrder(erc1155Token.getAddress(), tokenID, bidAmount, bidPrice, { value: bidAmount * bidPrice });

			const askAmount = 5;
			await erc1155Token.mint(user2.address, tokenID, askAmount);

			await erc1155Token.connect(user2).setApprovalForAll(dexContract.getAddress(), true);

			const askPrice = 50;
			await dexContract.connect(user2).askOrder(erc1155Token.getAddress(), tokenID, askAmount, askPrice);

			await dexContract.connect(user1).executeOrderWithRefund([1], [2], [askAmount]);

			const actualRefund = BigInt(bidAmount) * BigInt(bidPrice) - BigInt(askAmount) * BigInt(askPrice);
			console.log('Actual refund:', actualRefund.toString()); // 환불액은 50이어야 합니다.
		});
	});

	describe('Access Control', function () {
		// 주문 실행이 운영자에게만 제한되는지 테스트합니다.
		it('should restrict order execution to operators only', async function () {
			const { dexContract, user3 } = await loadFixture(deployDexContractFixture);

			// 비운영자 사용자가 주문을 실행하려고 시도합니다.
			await expect(dexContract.connect(user3).executeOrder([0], [1], [amount])).to.be.revertedWith('#operatorsOnly:'); // 오류 메시지가 정확한지 확인
		});
	});
});
