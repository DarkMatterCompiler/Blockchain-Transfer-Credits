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

    function transferCredit(uint256 creditId, address to) public {
        // Ensure the sender owns the credit
        address currentOwner = creditToOwner[creditId];
        require(currentOwner == msg.sender, "You do not own this credit");

        // Find the credit index
        Credit[] storage credits = studentCredits[msg.sender];
        uint256 creditIndex = findCreditIndex(creditId, credits);
        
        // Ensure the credit exists and hasn't been transferred
        require(creditIndex < credits.length, "Credit not found");
        require(credits[creditIndex].id == creditId, "Invalid credit ID");
        require(!credits[creditIndex].isTransferred, "Credit already transferred");
        
        // Transfer credit
        Credit memory creditToTransfer = credits[creditIndex];
        creditToTransfer.isTransferred = true;

        // Remove the credit from the sender's list
        credits[creditIndex] = credits[credits.length - 1];
        credits.pop();
        
        // Add the credit to the recipient's list
        studentCredits[to].push(creditToTransfer);

        // Update ownership
        creditToOwner[creditId] = to;

        // Emit event
        emit CreditTransferred(creditId, msg.sender, to);
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

    function getCreditOwner(uint256 creditId) public view returns (address) {
        return creditToOwner[creditId];
    }
}
