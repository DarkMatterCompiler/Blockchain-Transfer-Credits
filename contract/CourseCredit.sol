// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CourseCredit {
    struct Credit {
        uint256 id;
        string courseName;
        string issuingInstitution;
        uint256 creditHours;
        bool isTransferred;
    }

    mapping(address => Credit[]) public studentCredits;
    mapping(uint256 => address) public creditToOwner;
    uint256 public nextCreditId;

    event CreditIssued(address indexed student, uint256 creditId, string courseName, string issuingInstitution, uint256 creditHours);
    event CreditTransferred(uint256 creditId, address indexed from, address indexed to);

    function issueCredit(address student, string memory courseName, string memory issuingInstitution, uint256 creditHours) public {
        Credit memory newCredit = Credit({
            id: nextCreditId,
            courseName: courseName,
            issuingInstitution: issuingInstitution,
            creditHours: creditHours,
            isTransferred: false
        });

        studentCredits[student].push(newCredit);
        creditToOwner[nextCreditId] = student;
        emit CreditIssued(student, nextCreditId, courseName, issuingInstitution, creditHours);
        nextCreditId++;
    }

    function transferCredit(address from, address to, uint256 creditId) public {
        // Check if the credit exists and retrieve the current owner
        address currentOwner = creditToOwner[creditId];
        require(currentOwner == from, "The specified 'from' address does not own this credit");
        require(currentOwner != address(0), "Credit does not exist");

        // Find the credit index in the sender's list
        Credit[] storage credits = studentCredits[from];
        uint256 creditIndex = findCreditIndex(creditId, credits);
        require(creditIndex < credits.length, "Credit not found");

        // Ensure the credit has not already been transferred
        Credit storage creditToTransfer = credits[creditIndex];
        require(!creditToTransfer.isTransferred, "Credit already transferred");

        // Mark the credit as transferred
        creditToTransfer.isTransferred = true;

        // Remove the credit from the sender's list
        credits[creditIndex] = credits[credits.length - 1];
        credits.pop();

        // Add the credit to the recipient's list
        studentCredits[to].push(creditToTransfer);

        // Update the ownership mapping
        creditToOwner[creditId] = to;

        // Emit an event to log the transfer
        emit CreditTransferred(creditId, from, to);
    }

    function findCreditIndex(uint256 creditId, Credit[] storage credits) internal view returns (uint256) {
        for (uint256 i = 0; i < credits.length; i++) {
            if (credits[i].id == creditId) {
                return i;
            }
        }
        revert("Credit not found");
    }

    function viewCredits(address student) public view returns (Credit[] memory) {
        return studentCredits[student];
    }

    function verifyCredit(uint256 creditId) public view returns (string memory courseName, string memory issuingInstitution, uint256 creditHours, address owner) {
        require(creditToOwner[creditId] != address(0), "Credit does not exist");
        Credit memory credit = studentCredits[creditToOwner[creditId]][findCreditIndex(creditId, studentCredits[creditToOwner[creditId]])];
        return (credit.courseName, credit.issuingInstitution, credit.creditHours, creditToOwner[creditId]);
    }

    function verifyCreditOwner(uint256 creditId) internal view returns (address) {
        address owner = creditToOwner[creditId];
        require(owner != address(0), "Credit does not exist");
        return owner;
    }

    function getCreditOwner(uint256 creditId) public view returns (address) {
        return creditToOwner[creditId];
    }
}
