## Design patter decisions

#### Circuit breaker (emergency stop)

The ability to pause the contract - should it act incorrectly or become compromised - is implemented through importing the 'Pausable' OpenZeppelin contract, of which the Pledgeo contract is derived, and using the 'whenNotPaused' modifier for all of the external functions in the contract.

#### Ownership

The ability to renounce ownership as well as to transfer ownership of a contract to another account is implemented through importing the 'Ownable' OpenZeppelin contract and deriving the Pledgeo contract from it.

#### Lifecycle

- Mortality: the ability to destroy the contract for development purposes is implemented through the 'destroyContract' function (it may be removed in the future).
- Gradual deployment: not chosen to implement at the moment.

#### Locked pragma version

The pragma version is locked to 0.5.0 to prevent future compiler changes from causing incompatibilites with the Pledgeo contract.

#### Visibility of functions and state variables

The visibility of functions and state variables was explicitly labelled to avoid confusion.

#### Gas consumption optimization

##### Costly loops

State variables and calculations were moved out of the loops.

##### Use of modifiers

'Require' statements that were used repeatedly were turned into modifiers.

##### Choice of visibility

'external' was chosen over 'public' for functions that are not called from within the contract itself.

##### Short circuit rules

When the operators '||' and '&&' were used, the condition with the lower cost to calcuate was written first over the most expensive one to save gas if short circuited.