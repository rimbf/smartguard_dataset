
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

 


   
}