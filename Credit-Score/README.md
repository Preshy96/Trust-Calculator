# Trust Score Calculator Smart Contract

## Overview

The Trust Score Calculator is a smart contract deployed on the Stacks blockchain that calculates and manages trust scores for users. This system provides a transparent and decentralized way to establish trust metrics based on transaction history and verification status.

## Features

- **Trust Score Calculation**: Automatically calculates user trust scores based on transaction history and verification status
- **User Management**: Creates and maintains user profiles with associated trust metrics
- **Verification System**: Supports user verification status that impacts trust scores
- **Transaction Tracking**: Records and factors in transaction count when calculating trust
- **Admin Controls**: Provides contract owner with special privileges for system management

## Contract Structure

### Data Maps

- `user-trust-scores`: Stores user trust information including total score, transaction count, last updated block, and verification status
- `trust-factors`: Stores configurable factors that can be used in trust calculations

### Constants

- `MIN-SCORE`: 0
- `MAX-SCORE`: 100
- Error codes for various failure conditions

### Functions

#### Read-Only Functions

- `get-trust-score`: Retrieves the trust score for a specified user
- `get-user-data`: Retrieves all trust data for a specified user
- `get-factor`: Retrieves information about a specific trust factor

#### Public Functions

- `initialize-user`: Creates a new user profile with default values
- `update-verification-status`: Updates a user's verification status and recalculates their trust score
- `increment-transaction-count`: Increments a user's transaction count and recalculates their trust score
- `add-trust-factor`: Adds a new factor that can influence trust calculations
- `update-factor-status`: Updates the active status of an existing trust factor

#### Admin Functions

- `set-contract-owner`: Transfers contract ownership to a new principal
- `admin-set-trust-score`: Directly sets a user's trust score (for special cases)

## Trust Score Calculation

Trust scores are calculated based on the following components:

1. **Base Score**: Every user starts with a base score of 50
2. **Transaction Factor**: Users gain additional points based on their transaction count (up to a maximum of 30 points)
3. **Verification Bonus**: Verified users receive an additional 20 points

The formula for calculating the trust score is:
```
Trust Score = Base Score (50) + Transaction Factor + Verification Bonus
```

Where:
- Transaction Factor = min(transaction_count * 3, 30)
- Verification Bonus = 20 if verified, 0 if not verified

All trust scores are capped between 0 and 100.

## Usage Examples

### Initializing a User

```clarity
;; Initialize a new user
(contract-call? .trust-score-calculator initialize-user tx-sender)
```

### Updating Verification Status

```clarity
;; Mark a user as verified
(contract-call? .trust-score-calculator update-verification-status tx-sender true)
```

### Recording a Transaction

```clarity
;; Increment transaction count after successful transaction
(contract-call? .trust-score-calculator increment-transaction-count tx-sender)
```

### Adding a Trust Factor

```clarity
;; Only contract owner can add factors
(contract-call? .trust-score-calculator add-trust-factor u1 "Payment History" u20)
```

### Checking a User's Trust Score

```clarity
;; Get a user's trust score
(contract-call? .trust-score-calculator get-trust-score 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

## Error Codes

- `ERR-NOT-AUTHORIZED (u100)`: Caller is not authorized to perform the operation
- `ERR-INVALID-SCORE (u101)`: The provided score is invalid
- `ERR-USER-NOT-FOUND (u102)`: The specified user does not exist
- `ERR-SCORE-OUT-OF-RANGE (u103)`: The score is outside the valid range (0-100)

## Security Considerations

- Only the contract owner can add or modify trust factors
- Only the contract owner can transfer ownership or directly set trust scores
- User verification must be managed carefully to maintain system integrity
- Trust scores are calculated automatically to prevent manipulation

## Deployment

To deploy this contract on the Stacks blockchain:

1. Install the Stacks CLI
2. Build and test the contract locally
3. Deploy to testnet for additional testing
4. When ready, deploy to mainnet

Example deployment command:
```
clarinet deploy --keychain /path/to/keychain.json --network testnet
```