// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract HarvestToken is ERC1155, AccessControl {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant AGENT_ROLE = keccak256("AGENT_ROLE");

    // mapping tokenId => tokenURI
    mapping(uint256 => string) private _tokenURIs;
    // mapping tokenId => isLocked
    mapping(uint256 => bool) public isLocked;

    event HarvestTokenized(
        uint256 indexed tokenId,
        address indexed farmer,
        uint256 amountKg,
        string ipfsUri
    );
    event CollateralLocked(uint256 indexed tokenId, address indexed lendingVault);
    event CollateralReleased(uint256 indexed tokenId, address indexed farmer);

    constructor(address adminSafe) ERC1155("") {
        _grantRole(DEFAULT_ADMIN_ROLE, adminSafe);
        _grantRole(AGENT_ROLE, adminSafe);
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount,
        string calldata ipfsUri,
        bytes calldata data
    ) external onlyRole(MINTER_ROLE) {
        _mint(to, id, amount, data);
        _tokenURIs[id] = ipfsUri;
        emit HarvestTokenized(id, to, amount, ipfsUri);
    }

    function uri(uint256 id) public view override returns (string memory) {
        return _tokenURIs[id];
    }

    function markLocked(uint256 tokenId) external onlyRole(AGENT_ROLE) {
        isLocked[tokenId] = true;
        emit CollateralLocked(tokenId, msg.sender);
    }

    function markReleased(uint256 tokenId) external onlyRole(AGENT_ROLE) {
        isLocked[tokenId] = false;
        emit CollateralReleased(tokenId, msg.sender);
    }

    // Override _update to enforce lock checks on transfers
    function _update(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory values
    ) internal override(ERC1155) {
        // If it's a transfer (from is not address(0)), ensure none of the tokens are locked
        if (from != address(0)) {
            for (uint256 i = 0; i < ids.length; i++) {
                require(!isLocked[ids[i]], "HarvestToken: token is locked as collateral");
            }
        }
        super._update(from, to, ids, values);
    }

    // Overridden to support both AccessControl and ERC1155
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC1155, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
