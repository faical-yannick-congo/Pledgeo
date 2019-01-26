## Design patter decisions

#### Circuit breaker (emergency stop)

The ability to pause the contract - should it act incorrectly or become compromised - is implemented through importing the 'Pausable' OpenZeppelin contract, of which the Pledgeo contract is derived, and using the 'whenNotPaused' modifier for all of the external functions in the contract.

#### Transfer Ownership

The ability to transfer ownership of a contract to another account is implemented through importing the 'Ownable' OpenZeppelin contract and deriving the Pledgeo contract from it.

#### Lock pragma version

The pragma version is locked to 0.5.0 to prevent future compiler changes from causing incompatibilites with the Pledgeo contract.

#### Costly loops

State variables and calculations were moved out of the loops to reduce gas consumption.

#### Restricted access

'Require' statements were used to restrict access to certain functions and establish the permissions. They were also used to check the validity of the input parameters. Those that were used repeatedly were turned into modifiers.