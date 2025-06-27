
pragma solidity ^0.8.10;


error MintedOut();

error AuctionNotStarted();

error MintingTooMany();

error ValueTooLow();

error NotMintlisted();

error UnauthorizedEvolution();

error UnknownEvolution();



contract Pixelmon {
    using Strings for uint256;


    

    uint constant public provenanceHash = 0x9912e067bd3802c3b007ce40b6c125160d2ccb5352d199e20c092fdc17af8057;
    address constant gnosisSafeAddress = 0xF6BD9Fc094F7aB74a846E5d82a822540EE6c6971;
    uint constant auctionSupply = 7750 + 330;
    uint constant secondEvolutionOffset = 10005;
    uint constant thirdEvolutionOffset = secondEvolutionOffset + 4013;
    uint constant fourthEvolutionOffset = thirdEvolutionOffset + 1206;


                      
    

    uint secondEvolutionSupply = 0;
    uint thirdEvolutionSupply = 0;
    uint fourthEvolutionSupply = 0;
    address public serumContract;

    mapping(address => bool) public mintlisted;


                        
    

    uint256 constant public auctionStartPrice = 3 ether;
    uint256 constant public auctionStartTime = 1644256800;
    uint256 public mintlistPrice = 0.75 ether;

  
                           


    string public baseURI;

  
    

    constructor(string memory _baseURI) {
        baseURI = _baseURI;
        unchecked {
            balanceOf[gnosisSafeAddress] += 330;
            totalSupply += 330;
            for (uint256 i = 0; i < 330; i++) {
                ownerOf[i] = gnosisSafeAddress;
                emit Transfer(address(0), gnosisSafeAddress, i);
            }
        }
    }


    

    string public name = "Pixelmon";
    string public symbol = "PXLMN";

    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(uint256 => address) public ownerOf;
    mapping(uint256 => address) public getApproved;
    mapping(address => mapping(address => bool)) public isApprovedForAll;

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function tokenURI(uint256 id) public view returns (string memory) {
        return string(abi.encodePacked(baseURI, id.toString()));
    }

    function approve(address spender, uint256 id) public {
        address owner = ownerOf[id];
        require(msg.sender == owner || isApprovedForAll[owner][msg.sender], "NOT_AUTHORIZED") check_approve_msg_sender;
        getApproved[id] = spender;
        emit Approval(owner, spender, id) approval_event;
    }

    function setApprovalForAll(address operator, bool approved) public {
        isApprovedForAll[msg.sender][operator] = approved ;
        emit ApprovalForAll(msg.sender, operator, approved) approvalForAll_event;
    }

    function transferFrom(address from, address to, uint256 id) public {
        require(from == ownerOf[id], "WRONG_FROM") check_transferFrom_current_owner ;
        require(to != address(0), "INVALID_RECIPIENT") check_transferFrom_zero_address;
        require(msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED") check_transferFrom_msg_sender ;
        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }
        ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id) transferFrom_event;
    }

    function safeTransferFrom(address from, address to, uint256 id) public {
      require(from == ownerOf[id], "WRONG_FROM") check_safeTransferFrom_current_owner;
        require(to != address(0), "INVALID_RECIPIENT") check_safeTransferFrom_zero_address;
        require(msg.sender == from || msg.sender == getApproved[id] || isApprovedForAll[from][msg.sender], "NOT_AUTHORIZED") check_safeTransferFrom_msg_sender ;
        unchecked {
            balanceOf[from]--;
            balanceOf[to]++;
        }
        ownerOf[id] = to;
        delete getApproved[id];
        emit Transfer(from, to, id) safeTransferFrom_event;
        require(to.code.length == 0 || ERC721TokenReceiver(to).onERC721Received(msg.sender, from, id, "") == ERC721TokenReceiver.onERC721Received.selector, "UNSAFE_RECIPIENT") check_safeTransferFrom_contract;
    }

 

    function _mint(address to, uint256 id) internal {
        require(to != address(0), "INVALID_RECIPIENT");
        require(ownerOf[id] == address(0), "ALREADY_MINTED");
        unchecked {
            totalSupply++;
            balanceOf[to]++;
        }
        ownerOf[id] = to;
        emit Transfer(address(0), to, id);
    }

    function _burn(uint256 id) internal {
        address owner = ownerOf[id];
        require(ownerOf[id] != address(0), "NOT_MINTED");
        unchecked {
            totalSupply--;
            balanceOf[owner]--;
        }
        delete ownerOf[id];
        delete getApproved[id];
        emit Transfer(owner, address(0), id);
    }


    function validCalculatedTokenPrice() private view returns (uint) {
        uint priceReduction = ((block.timestamp - auctionStartTime) / 10 minutes) * 0.1 ether;
        return auctionStartPrice >= priceReduction ? (auctionStartPrice - priceReduction) : 0;
    }

    function getCurrentTokenPrice() public view returns (uint256) {
        return max(validCalculatedTokenPrice(), 0.2 ether);
    }

    function auction(bool mintingTwo) public payable {
        if(block.timestamp < auctionStartTime || block.timestamp > auctionStartTime + 1 days) revert AuctionNotStarted();
        uint count = mintingTwo ? 2 : 1;
        uint price = getCurrentTokenPrice();
        if(totalSupply + count > auctionSupply) revert MintedOut();
        if(balanceOf[msg.sender] + count > 2) revert MintingTooMany();
        if(msg.value < price * count) revert ValueTooLow();
        mintingTwo ? _mintTwo(msg.sender) : _mint(msg.sender, totalSupply);
    }

    function _mintTwo(address to) internal {
        require(to != address(0), "INVALID_RECIPIENT");
        require(ownerOf[totalSupply] == address(0), "ALREADY_MINTED");
        uint currentId = totalSupply;
        unchecked {
            totalSupply += 2;
            balanceOf[to] += 2;
            ownerOf[currentId] = to;
            ownerOf[currentId + 1] = to;
            emit Transfer(address(0), to, currentId);
            emit Transfer(address(0), to, currentId + 1);
        }
    }



    function setMintlistPrice(uint256 price) public onlyOwner {
        mintlistPrice = price;
    }

    function mintlistUser(address user) public onlyOwner {
        mintlisted[user] = true;
    }

    function mintlistUsers(address[] calldata users) public onlyOwner {
        for (uint256 i = 0; i < users.length; i++) {
            mintlisted[users[i]] = true;
        }
    }

    function mintlistMint() public payable {
        if(totalSupply >= secondEvolutionOffset) revert MintedOut();
        if(!mintlisted[msg.sender]) revert NotMintlisted();
        if(msg.value < mintlistPrice) revert ValueTooLow();
        mintlisted[msg.sender] = false;
        _mint(msg.sender, totalSupply);
    }


    

    function rollOverPixelmons(address[] calldata addresses) public onlyOwner {
        if(totalSupply + addresses.length > secondEvolutionOffset) revert MintedOut();
        for (uint256 i = 0; i < addresses.length; i++) {
            _mint(msg.sender, totalSupply);
        }
    }


    

    function setSerumContract(address _serumContract) public onlyOwner {
        serumContract = _serumContract; 
    }

   
}