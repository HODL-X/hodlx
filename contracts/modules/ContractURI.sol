// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract ContractURI {

    string private _contractURI = "";

    event ContractURIChanged(string _old, string _new);

    // @notice this sets the contractURI, set to internal
    // @param newURI - string to URI of Contract Metadata
    // @notice: let the metadata be in this format
    //{
    //  "name": Project's name,
    //  "description": Project's Description,
    //  "image": pfp for project,
    //  "external_link": web url,
    //  "seller_fee_basis_points": 100 -> Indicates a 1% seller fee.
    //  "fee_recipient": checksum address
    //}
    function _setContractURI(string memory newURI) internal {
        string memory old = _contractURI;
        _contractURI = newURI;
        emit ContractURIChanged(old, _contractURI);
    }

    // @notice contractURI() called for retreval of OpenSea style collections pages
    // @return - string thisContractURI
    function contractURI() external view returns (string memory) {
        return _contractURI;
    }

}