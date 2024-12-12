# Open Source Project Funding Smart Contract

## About
This Clarity smart contract enables decentralized funding for open-source projects on the Stacks blockchain. It provides a comprehensive system for creating, funding, and managing open-source projects with milestone-based development tracking and automated fund distribution.

## Features

### Project Management
- Create new open-source projects with detailed information
- Track project status and funding progress
- Milestone-based development tracking
- Automated fund distribution upon milestone completion

### Funding Mechanism
- Secure STX token contributions
- Individual contributor tracking
- Prevention of over-funding
- Automatic milestone-based fund distribution

### Access Control
- Project creator authorization
- Contract administrator controls
- Secure fund management
- Milestone completion verification

## Contract Functions

### Administrative Functions

#### `initialize-contract`
Initializes the contract with the deployer as the administrator.
```clarity
(define-public (initialize-contract))
```

### Project Management Functions

#### `create-open-source-project`
Creates a new open-source project.
```clarity
(define-public (create-open-source-project 
    (project-title (string-ascii 100)) 
    (project-description (string-utf8 500))
    (target-funding-amount uint)))
```
Parameters:
- `project-title`: Name of the project (max 100 characters)
- `project-description`: Detailed project description (max 500 characters)
- `target-funding-amount`: Total funding goal in microSTX

#### `add-project-milestone`
Adds a development milestone to an existing project.
```clarity
(define-public (add-project-milestone 
    (project-identifier uint)
    (milestone-title (string-ascii 100))
    (milestone-description (string-utf8 500))
    (milestone-deadline uint)
    (milestone-funding-amount uint)))
```
Parameters:
- `project-identifier`: Unique project ID
- `milestone-title`: Name of the milestone
- `milestone-description`: Detailed milestone description
- `milestone-deadline`: Block height deadline
- `milestone-funding-amount`: Funding amount for this milestone

### Funding Functions

#### `contribute-project-funding`
Contributes STX tokens to a project.
```clarity
(define-public (contribute-project-funding 
    (project-identifier uint) 
    (funding-amount uint)))
```
Parameters:
- `project-identifier`: Project ID to fund
- `funding-amount`: Amount of STX tokens to contribute

#### `complete-project-milestone`
Marks a milestone as complete and releases funds.
```clarity
(define-public (complete-project-milestone 
    (project-identifier uint) 
    (milestone-identifier uint)))
```
Parameters:
- `project-identifier`: Project ID
- `milestone-identifier`: Milestone ID to complete

### Read-Only Functions

#### `get-project-details`
Retrieves project information.
```clarity
(define-read-only (get-project-details 
    (project-identifier uint)))
```

#### `get-milestone-details`
Retrieves milestone information.
```clarity
(define-read-only (get-milestone-details 
    (project-identifier uint) 
    (milestone-identifier uint)))
```

#### `get-contributor-funding-amount`
Gets the total contribution amount from a specific contributor.
```clarity
(define-read-only (get-contributor-funding-amount 
    (project-identifier uint) 
    (funding-contributor principal)))
```

#### `is-project-fully-funded`
Checks if a project has reached its funding goal.
```clarity
(define-read-only (is-project-fully-funded 
    (project-identifier uint)))
```

## Error Codes

| Code | Description |
|------|-------------|
| ERR-UNAUTHORIZED-ACCESS | User not authorized for the operation |
| ERR-PROJECT-DOES-NOT-EXIST | Project ID not found |
| ERR-PROJECT-ALREADY-FUNDED | Project has already reached funding goal |
| ERR-INSUFFICIENT-BALANCE | Insufficient funds for operation |
| ERR-INVALID-FUNDING-AMOUNT | Invalid funding amount specified |
| ERR-MILESTONE-DOES-NOT-EXIST | Milestone ID not found |
| ERR-MILESTONE-INCOMPLETE | Milestone completion conditions not met |

## Data Structures

### Open Source Projects
```clarity
{
    project-creator: principal,
    project-title: (string-ascii 100),
    project-description: (string-utf8 500),
    target-funding-amount: uint,
    total-funds-raised: uint,
    project-status: (string-ascii 20),
    project-creation-block: uint
}
```

### Project Development Milestones
```clarity
{
    milestone-title: (string-ascii 100),
    milestone-description: (string-utf8 500),
    milestone-completion-deadline: uint,
    milestone-funding-amount: uint,
    milestone-status: (string-ascii 20)
}
```

### Project Funding Contributors
```clarity
{
    contribution-amount: uint
}
```

## Security Considerations

1. **Access Control**
   - Only project creators can add milestones and mark them as complete
   - Only contract administrator can initialize the contract
   - Public functions have appropriate authorization checks

2. **Fund Safety**
   - Automatic fund distribution upon milestone completion
   - Prevention of over-funding
   - Secure STX token transfers using contract principal

3. **Input Validation**
   - All numeric inputs are validated
   - String lengths are constrained
   - Milestone deadlines are verified

## Usage Examples

### Creating a New Project
```clarity
(contract-call? .open-source-funding create-open-source-project 
    "My Open Source Project" 
    "A detailed description of the project" 
    u1000000)
```

### Contributing Funds
```clarity
(contract-call? .open-source-funding contribute-project-funding 
    u1 
    u500000)
```

### Adding a Milestone
```clarity
(contract-call? .open-source-funding add-project-milestone 
    u1 
    "First Release" 
    "Complete core functionality" 
    u100000 
    u500000)
```