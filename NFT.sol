// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Libraries.sol";

contract NFT_HYPER is ERC721, Ownable {
    using Strings for uint256;

    uint256 public MAX_SUPPLY = 2500;
    uint256 public TEAM_SUPPLY = 400;
    uint256 public TEAM_AIRDROP_SUPPLY = 100;
    uint256 public AIRDROP_SUPPLY = 1000;
    uint256 public PUBLIC_SUPPLY = 1000;
    uint256 public publicPrice;
    uint256 public teamMinted;
    uint256 public totalAirdropped;
    uint256 public totalPublicMinted;
    string public baseExtension = ".json";
    string public baseTokenURI;
    address public teamWallet;

    uint256 public airdropMinted;
    bytes32 public merkleRoot;
    mapping(address => bool) public airdropClaimed;

    constructor( address _teamWallet)
        ERC721("NFT HYPER", "nft")
    {
        teamWallet = _teamWallet;
    }

    // Set public price
    function setPrice(uint256 price) external onlyOwner {
        publicPrice = price;
    }

    // function setSupply( uint256 totalSupply, uint256 teamSupply, uint256 teamAirdrop, uint256 airdropSupply, uint256 pubSupply ) external onlyOwner {
    //     MAX_SUPPLY = totalSupply;
    //     TEAM_SUPPLY = teamSupply;
    //     TEAM_AIRDROP_SUPPLY = teamAirdrop;
    //     AIRDROP_SUPPLY = airdropSupply;
    //     PUBLIC_SUPPLY = pubSupply;
    // }

    // Mint function: owner can mint to addresses for team(max 400)
    function MintForTeam(uint256 count) external onlyOwner {
        require(
            count < 40            
        );
        for (uint256 i = 0; i < 10; i++) {
            _mint(teamWallet, i + count * 10); // Use _mint instead of _safeMint
        }
    }

    // Airdrop function: owner can airdrop to addresses for team(max 100)
    function AirdropForTeam(address[] calldata recipients) external onlyOwner {
        require(recipients.length <= TEAM_AIRDROP_SUPPLY);
        uint256 tokenId = TEAM_SUPPLY + totalAirdropped + 1;

        for (uint256 i = 0; i < recipients.length; i++) {
            _mint(recipients[i], tokenId);
            tokenId++;
            totalAirdropped++;
        }
    }

    // Airdrop function: owner can airdrop to addresses using MerkleTree(max 1000)
    function airdropMint(bytes32[] calldata merkleProof) external  {
        require(airdropMinted < AIRDROP_SUPPLY);
        require(!airdropClaimed[msg.sender]);

        // Verify Merkle proof
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(merkleProof, merkleRoot, leaf));

        airdropClaimed[msg.sender] = true;
        _safeMint(
            msg.sender,
            TEAM_SUPPLY + TEAM_AIRDROP_SUPPLY + airdropMinted + 1
        );
        airdropMinted++;
    }

    function setMerkleRoot(bytes32 _merkleRoot) external onlyOwner {
        merkleRoot = _merkleRoot;
    }  

    // Public mint function
    function publicMint(uint256 quantity) external payable {
        require(
            totalPublicMinted + quantity <= PUBLIC_SUPPLY,
            "Exceeds public sale limit"
        );
        require(msg.value >= publicPrice * quantity);

        uint256 tokenId = TEAM_SUPPLY +
            TEAM_AIRDROP_SUPPLY +
            AIRDROP_SUPPLY +
            totalPublicMinted +
            1;

        for (uint256 i = 0; i < quantity; i++) {
            _mint(msg.sender, tokenId);
            tokenId++;
            totalPublicMinted++;
        }
    }

    // Update base URI
    function setBaseURI(string memory newBaseURI) external onlyOwner {
        baseTokenURI = newBaseURI;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(
            _exists(tokenId)
        );

        return
            bytes(baseTokenURI).length > 0
                ? string(
                    abi.encodePacked(
                        baseTokenURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "/";
                        // return "https://ipfs.io/ipfs/bafkreif4jaotzbgtzum7l4tfqzh6alwfqjck7u344kyhwu7amzbfibjxpm";

    }

    // Withdraw funds
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
