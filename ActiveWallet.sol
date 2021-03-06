// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";



contract ActiveWallet is ERC721Holder, ERC1155Holder, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address[] public keyHolders;
    mapping(address => bool) public isKeyHolder;
    //keyHolder => adress of receiver => amount
    mapping(address => mapping(address => uint256)) public approvalETH;
    //keyHolder => adress of erc20 => adress of receiver => amount
    mapping(address => mapping(address => mapping(address => uint256)))
        public approvalERC20;
    //keyHolder => adress of erc721 => adress of receiver => id => approval
    mapping(address => mapping(address => mapping(address => mapping(uint256 => bool))))
        public approvalERC721;
    //keyHolder => adress of erc1155 => adress of receiver => id => amount
    mapping(address => mapping(address => mapping(address => mapping(uint256 => uint256))))
        public approvalERC1155;

    event ApprovedETH(address keyHolder, address to, uint256 amount);
    event ApprovedERC20(
        address keyHolder,
        address token,
        address to,
        uint256 amount
    );
    event ApprovedERC721(
        address keyHolder,
        address token,
        address to,
        uint256 id,
        bool approval
    );
    event ApprovedERC1155(
        address keyHolder,
        address token,
        address to,
        uint256 id,
        uint256 amount
    );
    event Received(address, uint);


    event SentETH(address to, uint256 amount);
    event SentERC20(address token, address to, uint256 amount);
    event SentERC721(address token, address to, uint256 id, bool approval);
    event SentERC1155(address token, address to, uint256 id, uint256 amount);

    modifier onlyKeyHolder() {
        require(isKeyHolder[msg.sender], "Not a Key Holder!");
        _;
    }

    constructor(address[] memory _keyHolders) {
        require(
            _keyHolders.length == 3,
            "There should be 3 adresses as keyHolders"
        );
        for (uint256 i; i < _keyHolders.length; i++) {
            address keyHolder = _keyHolders[i];
            require(keyHolder != address(0), "Can't be zero address");
            require(!isKeyHolder[keyHolder], "Already registered as an owner!");
            isKeyHolder[keyHolder] = true;
            keyHolders.push(keyHolder);
        }
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    //This function uses the logic of 3 keyHolder wallets, so it will not find more than 1 non zero approval.
    function setApproveOrSendERC20(
        IERC20 token,
        address _toAddress,
        uint256 _amount
    ) external onlyKeyHolder {
        require(_toAddress != address(0));
        require(
            _amount >= 0,
            "You can't set token approval amount to less than zero!"
        );
        approvalERC20[msg.sender][address(token)][_toAddress] = _amount;

        bool isSent = false;
        if (_amount > 0) {
            for (uint256 i; i < keyHolders.length; i++) {
                if (keyHolders[i] == msg.sender) {
                    continue;
                }
                if (
                    approvalERC20[keyHolders[i]][address(token)][_toAddress] ==
                    _amount
                ) {
                    approvalERC20[keyHolders[i]][address(token)][
                        _toAddress
                    ] = 0;
                    approvalERC20[msg.sender][address(token)][_toAddress] = 0;
                    isSent = true;
                    token.safeTransfer(_toAddress, _amount);
                    emit SentERC20(address(token), _toAddress, _amount);
                }
            }
        }
        if(!isSent){
                    emit ApprovedERC20(msg.sender, address(token), _toAddress, _amount);
        }
    }

    function setApproveOrSendERC721(
        IERC721 token,
        address _toAddress,
        uint256 _id,
        bool _approval
    ) external onlyKeyHolder {
        require(_toAddress != address(0));
        approvalERC721[msg.sender][address(token)][_toAddress][_id] = _approval;

        bool isSent = false;
        if (_approval) {
            for (uint256 i; i < keyHolders.length; i++) {
                if (keyHolders[i] == msg.sender) {
                    continue;
                }
                if (
                    approvalERC721[keyHolders[i]][address(token)][_toAddress][
                        _id
                    ]
                ) {
                    approvalERC721[keyHolders[i]][address(token)][_toAddress][
                        _id
                    ] = false;
                    approvalERC721[msg.sender][address(token)][_toAddress][
                        _id
                    ] = false;
                    isSent = true;
                    token.safeTransferFrom(address(this), _toAddress, _id);
                    emit SentERC721(address(token), _toAddress, _id, _approval);
                }
            }
        }
        if(!isSent){
                    emit ApprovedERC721(
            msg.sender,
            address(token),
            _toAddress,
            _id,
            _approval
        );
        }

    }

    function setApproveOrSendERC1155(
        IERC1155 token,
        address _toAddress,
        uint256 _id,
        uint256 _amount,
        bytes calldata data
    ) external onlyKeyHolder {
        require(_toAddress != address(0));
        require(
            _amount >= 0,
            "You can't set token approval amount to less than zero!"
        );
        approvalERC1155[msg.sender][address(token)][_toAddress][_id] = _amount;
        bool isSent = false;
        if (_amount > 0) {
            for (uint256 i; i < keyHolders.length; i++) {
                if (keyHolders[i] == msg.sender) {
                    continue;
                }
                if (
                    approvalERC1155[keyHolders[i]][address(token)][_toAddress][
                        _id
                    ] == _amount
                ) {
                    approvalERC1155[keyHolders[i]][address(token)][_toAddress][
                        _id
                    ] = 0;
                    approvalERC1155[msg.sender][address(token)][_toAddress][
                        _id
                    ] = 0;
                    isSent = true;
                    token.safeTransferFrom(
                        address(this),
                        _toAddress,
                        _id,
                        _amount,
                        data
                    );
                    emit SentERC1155(address(token), _toAddress, _id, _amount);
                }
            }
        }
        if(!isSent){
                    emit ApprovedERC1155(
            msg.sender,
            address(token),
            _toAddress,
            _id,
            _amount
        );
        }
    }

    function setApproveOrSendETH(address _toAddress, uint256 _amount)
        external
        onlyKeyHolder
        nonReentrant
    {
        require(_toAddress != address(0));
        require(
            _amount >= 0,
            "You can't set ETH approval amount to less than zero!"
        );
        approvalETH[msg.sender][_toAddress] = _amount;
        
        bool isSent = false;
        if (_amount > 0) {
            for (uint256 i; i < keyHolders.length; i++) {
                if (keyHolders[i] == msg.sender) {
                    continue;
                }
                if (approvalETH[keyHolders[i]][_toAddress] == _amount) {
                    approvalETH[keyHolders[i]][_toAddress] = 0;
                    approvalETH[msg.sender][_toAddress] = 0;
                    isSent = true;
                    (payable(_toAddress)).transfer(_amount);
                    emit SentETH(_toAddress, _amount);
                }
            }
        }
        if(!isSent){
            emit ApprovedETH(msg.sender, _toAddress, _amount);
        }
    }
}
