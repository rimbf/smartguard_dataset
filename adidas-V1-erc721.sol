// SPDX-License-Identifier: MIT

// Into the Metaverse NFTs are governed by the following terms and conditions: https://a.did.as/into_the_metaverse_tc

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import './AbstractERC1155Factory.sol';
import "./PaymentSplitter.sol";

contract AdidasOriginals is AbstractERC1155Factory, PaymentSplitter  {

    uint256 constant MAX_SUPPLY = 30000;
    uint256 constant MAX_EARLY_ACCESS = 20380;

    uint8 maxPerTx = 2;
    uint8 maxTxPublic = 2;
    uint8 maxTxEarly = 1;

    uint256 public mintPrice = 200000000000000000;
    uint256 public cardIdToMint = 1;

    uint256 public earlyAccessWindowOpens = 32533921476;
    uint256 public purchaseWindowOpens    = 32533921477;
    uint256 public purchaseWindowCloses   = 32533921478;

    uint256 public burnWindowOpens  = 32533921479;
    uint256 public burnWindowCloses = 32533921480;

    bytes32 public merkleRoot;
    mapping(address => uint256) public purchaseTxs;

    event RedeemedForCard(uint256 indexed indexToRedeem, uint256 indexed indexToMint, address indexed account, uint256 amount);
    event Purchased(uint256 indexed index, address indexed account, uint256 amount);


   string name_;
    string symbol_;   


    
    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) private _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

mapping(uint256 => uint256) private _totalSupply;
    string private _uri;


    constructor(
        string memory _name,
        string memory _symbol,
        string memory _uri,
        bytes32 _merkleRoot,
        address[] memory payees,
        uint256[] memory shares_
    ) ERC1155(_uri) PaymentSplitter(payees, shares_) {
        name_ = _name;
        symbol_ = _symbol;

        merkleRoot = _merkleRoot;

        _mint(0x8c685C44fACB8Bf246fCb0E383CCa4Bd46634bF8, 0, 380, "");
    }

   
    function startNextStage() external onlyOwner {
        cardIdToMint += 1;
    }

   
    function returnToPreviousStage() external onlyOwner {
        require(cardIdToMint > 1, "Cannot go below stage 1");

        cardIdToMint -= 1;
    }



    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }

 
    function setPrice(uint256 _mintPrice) external onlyOwner {
        mintPrice = _mintPrice;
    }

  
    function editSaleRestrictions(uint8 _maxPerTx, uint8 _maxTxEarly, uint8 _maxTxPublic) external onlyOwner {
        maxPerTx = _maxPerTx;
        maxTxEarly = _maxTxEarly;
        maxTxPublic = _maxTxPublic;
    }

   
    function editWindows(
        uint256 _purchaseWindowOpens,
        uint256 _purchaseWindowCloses,
        uint256 _earlyAccessWindowOpens,
        uint256 _burnWindowOpens,
        uint256 _burnWindowCloses
    ) external onlyOwner {
        require(
            _burnWindowOpens > _purchaseWindowCloses &&
            _purchaseWindowOpens > _earlyAccessWindowOpens &&
            _purchaseWindowCloses > _purchaseWindowOpens &&
            _burnWindowCloses > _burnWindowOpens,
            "window combination not allowed"
        );

        purchaseWindowOpens = _purchaseWindowOpens;
        purchaseWindowCloses = _purchaseWindowCloses;
        earlyAccessWindowOpens = _earlyAccessWindowOpens;

        burnWindowOpens = _burnWindowOpens;
        burnWindowCloses = _burnWindowCloses;
    }

   
    function earlyAccessSale(
        uint256 amount,
        uint256 index,
        bytes32[] calldata merkleProof
    ) external payable whenNotPaused {
        require(block.timestamp >= earlyAccessWindowOpens && block.timestamp <= purchaseWindowCloses, "Early access: window closed");
        require(totalSupply(0) + amount <= MAX_EARLY_ACCESS, "Early access: max supply reached");
        require(purchaseTxs[msg.sender] < maxTxEarly , "max tx amount exceeded");

        bytes32 node = keccak256(abi.encodePacked(index, msg.sender, uint256(2)));
        require(
            MerkleProof.verify(merkleProof, merkleRoot, node),
            "MerkleDistributor: Invalid proof."
        );

        _purchase(amount);
    }

   
    function purchase(uint256 amount) external payable whenNotPaused {
        require(block.timestamp >= purchaseWindowOpens && block.timestamp <= purchaseWindowCloses, "Purchase: window closed");
        require(purchaseTxs[msg.sender] < maxTxPublic , "max tx amount exceeded");

        _purchase(amount);

    }

  
    function _purchase(uint256 amount) private {
        require(amount > 0 && amount <= maxPerTx, "Purchase: amount prohibited");
        require(totalSupply(0) + amount <= MAX_SUPPLY, "Purchase: Max supply reached");
        require(msg.value == amount * mintPrice, "Purchase: Incorrect payment");

        purchaseTxs[msg.sender] += 1;

        _mint(msg.sender, 0, amount, "");
        emit Purchased(0, msg.sender, amount);
    }

 
    function redeemCardForOther(uint256 cardIdToRedeem, uint256 amount) external whenNotPaused {
        require(balanceOf(msg.sender, cardIdToRedeem) >= amount && amount > 0, "BurnCardForOther: amount not allowed");
        require(block.timestamp >= burnWindowOpens && block.timestamp <= burnWindowCloses, "BurnCardForOther: window closed");
        require(cardIdToRedeem < cardIdToMint, "BurnCardForOther: card cannot be burned");

        _burn(msg.sender, cardIdToRedeem, amount);
        _mint(msg.sender, cardIdToMint, amount, "");

        emit RedeemedForCard(cardIdToRedeem, cardIdToMint, msg.sender, amount);
    }

   
    function release(address payable account) public override {
        require(msg.sender == account || msg.sender == owner(), "Release: no permission");

        super.release(account);
    }

    function burn(
        address account,
        uint256 id,
        uint256 value
    ) public virtual override {
        require(block.timestamp > purchaseWindowCloses || totalSupply(0) == MAX_SUPPLY, "Burn: not allowed during sale");

        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burn(account, id, value);
    }

    function burnBatch(
        address account,
        uint256[] memory ids,
        uint256[] memory values
    ) public virtual override {
        require(block.timestamp > purchaseWindowCloses || totalSupply(0) == MAX_SUPPLY, "Burn: not allowed during sale");

        require(
            account == _msgSender() || isApprovedForAll(account, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );

        _burnBatch(account, ids, values);
    }


    function uri(uint256 _id) public view override returns (string memory) {
            require(exists(_id), "URI: nonexistent token");

            return string(abi.encodePacked(super.uri(_id), Strings.toString(_id)));
    }


     function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }    

    function setURI(string memory baseURI) external onlyOwner {
        _setURI(baseURI);
    }    

    function name() public view returns (string memory) {
        return name_;
    }

    function symbol() public view returns (string memory) {
        return symbol_;
    }          

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override(ERC1155, ERC1155Supply) {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


     function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC1155).interfaceId ||
            interfaceId == type(IERC1155MetadataURI).interfaceId ||
            super.supportsInterface(interfaceId);
    }


    function uri(uint256) public view virtual override returns (string memory) {
        return _uri;
    }

    function balanceOf(address account, uint256 id) public view virtual override returns (uint256) {
        require(account != address(0), "ERC1155: balance query for the zero address");
        return _balances[id][account];
    }

    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(accounts.length == ids.length, "ERC1155: accounts and ids length mismatch");

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

   
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

  
    function isApprovedForAll(address account, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[account][operator];
    }

 
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }


    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: transfer caller is not owner nor approved"
        );
        _safeBatchTransferFrom(from, to, ids, amounts, data);
    }

 
    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, _asSingletonArray(id), _asSingletonArray(amount), data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

  
    function _safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
            _balances[id][to] += amount;
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, from, to, ids, amounts, data);
    }

   
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

  
    function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, _asSingletonArray(id), _asSingletonArray(amount), data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

    function _mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {
        require(to != address(0), "ERC1155: mint to the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; i++) {
            _balances[ids[i]][to] += amounts[i];
        }

        emit TransferBatch(operator, address(0), to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(operator, address(0), to, ids, amounts, data);
    }


    function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), _asSingletonArray(id), _asSingletonArray(amount), "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);
    }


    function _burnBatch(
        address from,
        uint256[] memory ids,
        uint256[] memory amounts
    ) internal virtual {
        require(from != address(0), "ERC1155: burn from the zero address");
        require(ids.length == amounts.length, "ERC1155: ids and amounts length mismatch");

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            uint256 fromBalance = _balances[id][from];
            require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
            unchecked {
                _balances[id][from] = fromBalance - amount;
            }
        }

        emit TransferBatch(operator, from, address(0), ids, amounts);
    }


    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual {}

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155Received(operator, from, id, amount, data) returns (bytes4 response) {
                if (response != IERC1155Receiver.onERC1155Received.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try IERC1155Receiver(to).onERC1155BatchReceived(operator, from, ids, amounts, data) returns (
                bytes4 response
            ) {
                if (response != IERC1155Receiver.onERC1155BatchReceived.selector) {
                    revert("ERC1155: ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("ERC1155: transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }


    
    function totalSupply(uint256 id) public view virtual returns (uint256) {
        return _totalSupply[id];
    }

    function exists(uint256 id) public view virtual returns (bool) {
        return ERC1155Supply.totalSupply(id) > 0;
    }

   
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal virtual override {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);

        if (from == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] += amounts[i];
            }
        }

        if (to == address(0)) {
            for (uint256 i = 0; i < ids.length; ++i) {
                _totalSupply[ids[i]] -= amounts[i];
            }
        }
    }
}










   
