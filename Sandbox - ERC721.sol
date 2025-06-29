pragma solidity ^0.5.2;

import "./ERC165.sol";
import "./ERC721Events.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic interface
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
/*interface*/
contract ERC721 is ERC165, ERC721Events {

     event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    //   function exists(uint256 tokenId) external view returns (bool exists);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId)
        external
        view
        returns (address operator);

    function setApprovalForAll(address operator, bool approved) external;
    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);

    function transferFrom(address from, address to, uint256 tokenId)
        external;
    function safeTransferFrom(address from, address to, uint256 tokenId)
        external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}