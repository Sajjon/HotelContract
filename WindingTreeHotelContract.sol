pragma solidity ^0.4.15;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function Ownable() {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/*
 * Index_Interface
 * Interface of WTIndex contract
 */
contract Index_Interface {

  address public LifToken;

}


 /**
   @title AsyncCall_Interface, the interface of the AsyncCall Contract

   A contract that can receive requests to execute calls on itself.
   Every request can store encrypted data as a parameter, which can later be
   retrieved and decoded via web3.
   Requests may or may not require approval from the owner before execution.

   Inherits from OpenZeppelin's `Ownable`
 */
contract AsyncCall_Interface is Ownable {

  mapping(bytes32 => PendingCall) public pendingCalls;
  bool public waitConfirmation;

  modifier fromSelf(){
    require(msg.sender == address(this));
    _;
  }

  struct PendingCall {
    bytes callData;
    address sender;
    bool approved;
    bool success;
  }

  event CallStarted(address from, bytes32 dataHash);
  event CallFinish(address from, bytes32 dataHash);

  function changeConfirmation(bool _waitConfirmation) onlyOwner();
  function beginCall(bytes publicCallData, bytes privateData);
  function continueCall(bytes32 msgDataHash) onlyOwner();

}

 /**
   @title AsyncCall, a contract to execute calls with private data

   A contract that can receive requests to execute calls on itself.
   Every request can store encrypted data as a parameter, which can later be
   retrieved and decoded via web3.
   Requests may or may not require approval from the owner before execution.

   Inherits from OpenZeppelin's `Ownable`
 */
contract AsyncCall is Ownable {

  bytes32 public version = bytes32("0.0.1-alpha");
  bytes32 public contractType = bytes32("privatecall");

  // The calls requested to be executed indexed by `sha3(data)`
  mapping(bytes32 => PendingCall) public pendingCalls;

  // If the contract will require the owner's confirmation to execute the call
  bool public waitConfirmation;

  modifier fromSelf(){
    require(msg.sender == address(this));
    _;
  }

  struct PendingCall {
    bytes callData;
    address sender;
    bool approved;
    bool success;
  }

  /**
     @dev Event triggered when a call is requested
  **/
  event CallStarted(address from, bytes32 dataHash);

  /**
     @dev Event triggered when a call is finished
  **/
  event CallFinish(address from, bytes32 dataHash);

  /**
     @dev `changeConfirmation` allows the owner of the contract to switch the
     `waitConfirmation` value

     @param _waitConfirmation The new `waitConfirmation` value
   */
  function changeConfirmation(bool _waitConfirmation) onlyOwner() {
    waitConfirmation = _waitConfirmation;
  }

  /**
     @dev `beginCall` requests the execution of a call by the contract

     @param publicCallData The call data to be executed
     @param privateData The extra, encrypted data stored as a parameter
     returns true if the call was requested succesfully
   */
  function beginCall(bytes publicCallData, bytes privateData) {

    bytes32 msgDataHash = keccak256(msg.data);

    require(pendingCalls[msgDataHash].sender == address(0));

    pendingCalls[msgDataHash] = PendingCall(
      publicCallData,
      tx.origin,
      !waitConfirmation,
      false
    );
    CallStarted( tx.origin, msgDataHash);
    if (!waitConfirmation){
      require(this.call(pendingCalls[msgDataHash].callData));
      pendingCalls[msgDataHash].success = true;
      CallFinish(pendingCalls[msgDataHash].sender, msgDataHash);
    }
  }

  /**
     @dev `continueCall` allows the owner to approve the execution of a call

     @param msgDataHash The hash of the call to be executed
   */
  function continueCall(bytes32 msgDataHash) onlyOwner() {

    require(pendingCalls[msgDataHash].sender != address(0));

    pendingCalls[msgDataHash].approved = true;

    require(this.call(pendingCalls[msgDataHash].callData));
    pendingCalls[msgDataHash].success = true;

    CallFinish(pendingCalls[msgDataHash].sender, msgDataHash);

  }

}



/**
   @title Images, contract for managing images

   A contract that allows an owner to add/remove image urls in a array.
   Allows anyone to read the image urls.

   Inherits from OpenZeppelin's `Ownable`
 */
contract Images is Ownable {

  bytes32 public version = bytes32("0.0.1-alpha");
  bytes32 public contractType = bytes32("images");

  // Array of image urls
  string[] public images;

  /**
     @dev `addImage` allows the owner to add an image

     @param url The url of the image
   */
  function addImage(string url) onlyOwner() {
    images.push(url);
  }

  /**
     @dev `removeImage` allows the owner to remove an image

     @param index The image's index in the `images` array
   */
  function removeImage(uint index) onlyOwner() {
    delete images[index];
  }

  /**
     @dev `getImagesLength` get the length of the `images` array

     @return uint Length of the `images` array
   */
  function getImagesLength() constant returns (uint) {
    return images.length;
  }

}


/*
 * UnitType_Interface
 * Interface of UnitType contract
 */
contract UnitType_Interface is Ownable, Images {

  // Main information
  bytes32 public unitType;
  uint public totalUnits;

  // Owner methods
  function edit(string description, uint minGuests, uint maxGuests, string price) onlyOwner();
  function addAmenity(uint amenity) onlyOwner();
  function removeAmenity( uint amenity) onlyOwner();
  function removeUnit(uint unitIndex) onlyOwner();
  function increaseUnits() onlyOwner();
  function decreaseUnits() onlyOwner();

  // Public methods
  function getInfo() constant returns(string, uint, uint, string, bool);
  function getAmenities() constant returns(uint[]);

}


/*
 * Unit_Interface
 * Interface of Unit contract
 */
contract Unit_Interface is Ownable {

  // Main Information
  bool public active;
  bytes32 public unitType;
  uint256 public defaultLifTokenPrice;

  // Events
  event Book(address from, uint fromDay, uint daysAmount);

  // Owner methods
  function setActive(bool _active) onlyOwner();
  function setCurrencyCode(bytes8 _currencyCode) onlyOwner();
  function setSpecialPrice(uint256 price, uint256 fromDay, uint256 daysAmount) onlyOwner();
  function setSpecialLifPrice(uint256 price, uint256 fromDay, uint256 daysAmount) onlyOwner();
  function setDefaultPrice(uint256 price) onlyOwner();
  function setDefaultLifPrice(uint256 price) onlyOwner();
  function book(address from, uint256 fromDay, uint256 daysAmount) onlyOwner() returns(bool);

  // Public methods
  function getReservation(uint256 day) constant returns(uint256, uint256, address);
  function getCost(uint256 fromDay, uint256 daysAmount) constant returns(uint256);
  function getLifCost(uint256 fromDay, uint256 daysAmount) constant returns(uint256);

}

 /**
   @title UnitType, contract for a unit type in a hotel

   A type of unit that a Hotel has in their inventory. Stores the
   total number of units, description, min/max guests, price, amenities and
   images.

   Inherits from OpenZeppelin's `Ownable` and WT's 'Images'.
 */
contract UnitType is Ownable, Images {

  bytes32 public version = bytes32("0.0.1-alpha");
  bytes32 public contractType = bytes32("unittype");

  // The name of the unit type
  bytes32 public unitType;

  // The total amount of units of this type
  uint public totalUnits;

  // The description of the unit type
  string description;

  // The minimun and maximun amount of guests
  uint minGuests;
  uint maxGuests;

  // The price of the unit
  string price;

  // The amenities in the unit type, represented by uints
  uint[] amenities;
  mapping(uint => uint) amenitiesIndex;

  /**
     @dev Constructor.

     @param _owner see `owner`
     @param _unitType see `unitType`
   */
  function UnitType(address _owner, bytes32 _unitType){
    owner = _owner;
    unitType = _unitType;
  }

  /**
     @dev `edit` allows the owner of the contract to change the description,
     min/max guests and base price

     @param _price The base price of the unit
     @param _minGuests The minimun amount of guests allowed
     @param _maxGuests The maximun amount of guests allowed
     @param _description The new description
   */
  function edit(
    string _description,
    uint _minGuests,
    uint _maxGuests,
    string _price
  ) onlyOwner() {
    description = _description;
    minGuests = _minGuests;
    maxGuests = _maxGuests;
    price = _price;
  }

  /**
     @dev `increaseUnits` allows the owner to increase the `totalUnits`
   */
  function increaseUnits() onlyOwner() {
    totalUnits ++;
  }

  /**
     @dev `decreaseUnits` allows the owner to decrease the `totalUnits`
   */
  function decreaseUnits() onlyOwner() {
    totalUnits --;
  }

  /**
     @dev `addAmenity` allows the owner to add an amenity.

     @param amenityId The id of the amenity to add
   */
  function addAmenity(uint amenityId) onlyOwner() {
    amenitiesIndex[amenityId] = amenities.length;
    amenities.push(amenityId);
  }

  /**
     @dev `removeAmenity` allows the owner to remove an amenity

     @param amenityId The id of the amenity in the amenitiesIndex array
   */
  function removeAmenity(uint amenityId) onlyOwner() {
    delete amenities[ amenitiesIndex[amenityId] ];
    amenitiesIndex[amenityId] = 0;
  }

  /**
     @dev `GetInfo` get the information of the unit

     @return string The description of the unit type
     @return uint The minimun amount guests
     @return uint The maximun amount guests
     @return string The base price
   */
  function getInfo() constant returns(string, uint, uint, string) {
    return (description, minGuests, maxGuests, price);
  }

  /**
     @dev `getAmenities` get the amenities ids

     @return uint[] Array of all the amenities ids in the unit type
   */
  function getAmenities() constant returns(uint[]) {
    return (amenities);
  }

}


/**
   @title Hotel, contract for a Hotel registered in the WT network

   A contract that represents a hotel in the WT network. It stores the
   hotel's main information as well as its geographic coordinates, address,
   country, timezone, zip code, images and the contract addresses of the hotel's
   unit types and individual units.
   Every hotel offers different types of units, each type represented
   by a `UnitType` contract whose address is stored in the mapping `unitTypes`.
   Each individual unit is represented by its own `Unit` contract, whose address
   is stored in the `units` array.

   Inherits from OpenZeppelin's `Ownable` and WT's 'Images'
 */
contract Hotel is AsyncCall, Images {

  bytes32 public version = bytes32("0.0.1-alpha");
  bytes32 public contractType = bytes32("hotel");

  // Main information
  string public name;
  string public description;
  address public manager;
  uint public created;

  // Address and Location
  string public lineOne;
  string public lineTwo;
  string public zip;
  string public country;
  uint public timezone;
  uint public latitude;
  uint public longitude;

  // The `UnitType` contracts indexed by type and index
  mapping(bytes32 => address) public unitTypes;
  bytes32[] public unitTypeNames;

  // Array of addresses of `Unit` contracts and mapping of their index position
  mapping(address => uint) public unitsIndex;
  address[] public units;

  /**
     @dev Event triggered on every booking
  **/
  event Book(address from, address unit, uint256 fromDay, uint256 daysAmount);

  /**
     @dev Constructor.

     @param _name see `name`
     @param _description see `description`
     @param _manager see `_manager`
   */
  function Hotel(string _name, string _description, address _manager) {
    name = _name;
    description = _description;
    manager = _manager;
    created = block.number;
    unitTypeNames.length ++;
    units.length ++;
  }

  /**
     @dev `editInfo` allows the owner of the contract to change the hotel's
     main information

     @param _name The new name of the hotel
     @param _description The new description of the hotel
   */
  function editInfo(
    string _name,
    string _description
  ) onlyOwner() {
    name = _name;
    description = _description;
  }

  /**
     @dev `editAddress` allows the owner of the contract to change the hotel's
     physical address

     @param _lineOne The new main address of the hotel
     @param _lineTwo The new second address of the hotel
     @param _zip The new zip code of the hotel
     @param _country The new country of the hotel
   */
  function editAddress(
    string _lineOne,
    string _lineTwo,
    string _zip,
    string _country
  ) onlyOwner() {
    lineOne = _lineOne;
    lineTwo = _lineTwo;
    zip = _zip;
    country = _country;
  }

  /**
     @dev `editLocation` allows the owner of the contract to change the hotel's
     location

     @param _timezone The new timezone of the hotel
     @param _longitude The new longitude value of the location of the hotel
     @param _latitude The new longitude value of the latitude of the hotel
   */
  function editLocation(
    uint _timezone,
    uint _longitude,
    uint _latitude
  ) onlyOwner() {
    timezone = _timezone;
    latitude = _latitude;
    longitude = _longitude;
  }

  /**
     @dev `addUnitType` allows the owner to add a new unit type

     @param addr The address of the `UnitType` contract
   */
  function addUnitType(
    address addr
  ) onlyOwner() {
    bytes32 unitType = UnitType_Interface(addr).unitType();
		require(unitTypes[unitType] == address(0));
		unitTypes[unitType] = addr;
		unitTypeNames.push(unitType);
	}

  /**
     @dev `addUnit` allows the owner to add a new unit to the inventory

     @param unit The address of the `Unit` contract
   */
	function addUnit(
    address unit
  ) onlyOwner() {
		require(unitTypes[Unit_Interface(unit).unitType()] != address(0));
    unitsIndex[unit] = units.length;
    units.push(unit);
    UnitType_Interface(unitTypes[Unit_Interface(unit).unitType()]).increaseUnits();
  }

  /**
     @dev `removeUnit` allows the owner to remove a unit from the inventory

     @param unit The address of the `Unit` contract
   */
  function removeUnit(address unit) onlyOwner() {
    delete units[ unitsIndex[unit] ];
    delete unitsIndex[unit];
    UnitType_Interface(unitTypes[Unit_Interface(unit).unitType()]).decreaseUnits();
  }

  /**
     @dev `removeUnitType` allows the owner to remove a unit type

     @param unitType The type of unit
     @param index The unit's index in the `unitTypeNames` array
   */
  function removeUnitType(
    bytes32 unitType,
    uint index
  ) onlyOwner() {
    require(unitTypes[unitType] != address(0));
    require(unitTypeNames[index] == unitType);
    delete unitTypes[unitType];
    delete unitTypeNames[index];
  }

  /**
     @dev `changeUnitType` allows the owner to change a unit type

     @param unitType The type of unit
     @param newAddr The new address of the `UnitType` contract
   */
  function changeUnitType(
    bytes32 unitType,
    address newAddr
  ) onlyOwner() {
    require(unitTypes[unitType] != address(0));
    require(Unit_Interface(newAddr).unitType() == unitType);
    unitTypes[unitType] = newAddr;
  }

  /**
     @dev `callUnitType` allows the owner to call a unit type

     @param unitType The type of unit
     @param data The data of the call to execute on the `UnitType` contract
   */
  function callUnitType(
    bytes32 unitType,
    bytes data
  ) onlyOwner() {
    require(unitTypes[unitType] != address(0));
    require(unitTypes[unitType].call(data));
  }

  /**
     @dev `callUnit` allows the owner to call a unit

     @param unitAddress The address of the `Unit` contract
     @param data The data of the call to execute on the `Unit` contract
   */
  function callUnit(
    address unitAddress,
    bytes data
  ) onlyOwner() {
    require(unitsIndex[unitAddress] > 0);
    require(unitAddress.call(data));
  }

  /**
     @dev `book` allows the contract to execute a book function itself

     @param unitAddress The address of the `Unit` contract
     @param from The address of the opener of the reservation
     @param fromDay The starting day of the period of days to book
     @param daysAmount The amount of days in the booking period
   */
  function book(
    address unitAddress,
    address from,
    uint256 fromDay,
    uint256 daysAmount
  ) fromSelf() {
    require(unitsIndex[unitAddress] > 0);
    require(daysAmount > 0);
    require(Unit_Interface(unitAddress).book(from, fromDay, daysAmount));
    Book(from, unitAddress, fromDay, daysAmount);
  }

  /**
     @dev `bookWithLif` allows the contract to execute a book function itself

     @param unitAddress The address of the `Unit` contract
     @param from The address of the opener of the reservation
     @param fromDay The starting day of the period of days to book
     @param daysAmount The amount of days in the booking period
   */
  function bookWithLif(
    address unitAddress,
    address from,
    uint256 fromDay,
    uint256 daysAmount
  ) fromSelf() {
    require(unitsIndex[unitAddress] > 0);
    require(daysAmount > 0);
    uint256 price = Unit_Interface(unitAddress).getLifCost(fromDay, daysAmount);
    require(Unit_Interface(unitAddress).book(from, fromDay, daysAmount));
    require(ERC20(Index_Interface(owner).LifToken()).transferFrom(from, this, price));
    Book(from, unitAddress, fromDay, daysAmount);
  }

  /**
     @dev `getUnitType` get the address of a unit type

     @param unitType The type of the unit

     @return address Address of the `UnitType` contract
   */
  function getUnitType(bytes32 unitType) constant returns (address) {
    return unitTypes[unitType];
  }

  /**
     @dev `getUnitTypeNames` get the names of all the unitTypes

     @return bytes32[] Names of all the unit types
   */
  function getUnitTypeNames() constant returns (bytes32[]) {
    return unitTypeNames;
  }

  /**
     @dev `getUnitsLength` get the length of the `units` array

     @return uint Length of the `units` array
   */
  function getUnitsLength() constant returns (uint) {
    return units.length;
  }

  /**
     @dev `getUnits` get the `units` array

     @return address[] the `units` array
   */
  function getUnits() constant returns (address[]) {
    return units;
  }

}


/*
 * Hotel_Interface
 * Interface of Hotel contract
 */
contract Hotel_Interface is AsyncCall_Interface, Images {

  // Main information
  string public name;
  string public description;
  address public manager;
  uint public created;

  // Address and Location
  string public lineOne;
  string public lineTwo;
  string public zip;
  string public country;
  uint public timezone;
  uint public latitude;
  uint public longitude;

  // The `UnitType` contracts indexed by type and index
  mapping(bytes32 => address) public unitTypes;
  bytes32[] public unitTypeNames;

  // Array of addresses of `Unit` contracts and mapping of their index position
  mapping(address => uint) public unitsIndex;
  address[] public units;

  event Book(address from, address unit, uint256 fromDay, uint256 daysAmount);

  // Owner methods
  function editInfo(string _name, string _description) onlyOwner();
  function editAddress(string _lineOne, string _lineTwo, string _zip, string _country) onlyOwner() ;
  function editLocation(uint _timezone, uint _longitude, uint _latitude) onlyOwner();
  function addUnit(address unit) onlyOwner();
  function removeUnit(address unit) onlyOwner();
  function addUnitType(address addr) onlyOwner();
  function removeUnitType(bytes32 unitType, uint index) onlyOwner();
  function changeUnitType(bytes32 unitType, address newAddr) onlyOwner();
  function callUnitType(bytes32 unitType, bytes data) onlyOwner();
  function callUnit(address unitAddress, bytes data) onlyOwner();

  // Private call methods
  function book(address unitAddress, address from, uint fromDay, uint daysAmount) fromSelf();
  function bookWithLif(address unitAddress, address from, uint256 fromDay, uint256 daysAmount) fromSelf();

  // Public constant methods
  function getUnitType(bytes32 unitType) constant returns (address);
  function getUnitTypeNames() constant returns (bytes32[]);

}



 /**
   @title Unit, contract for an individual unit in a Hotel

   A contract that represents an individual unit of a hotel registered in the
   WT network. Tracks the price and availability of this unit.

   Inherits from WT's `PrivateCall`
 */
contract Unit is Ownable {

  bytes32 public version = bytes32("0.0.1-alpha");
  bytes32 public contractType = bytes32("unit");

  // The type of the unit
  bytes32 public unitType;

  // The status of the unit
  bool public active;

  // The default price for the Unit in LifTokens
  uint256 public defaultLifPrice;

  // Currency code for the custom price
  bytes8 public currencyCode;

  // Default price in custom currency (10000 = 100.00)
  uint256 public defaultPrice;

  /*
     Mapping of reservations, indexed by date represented by number of days
     after 01-01-1970
  */
  mapping(uint256 => UnitDay) reservations;
  struct UnitDay {
    uint256 specialPrice;
    uint256 specialLifPrice;
    address bookedBy;
  }

  /**
     @dev Constructor. Creates the `Unit` contract with an active status

     @param _owner see `owner`
     @param _unitType see `unitType`
   */
  function Unit(address _owner, bytes32 _unitType) {
    owner = _owner;
    unitType = _unitType;
    active = true;
  }

  /**
     @dev `setActive` allows the owner of the contract to switch the status

     @param _active The new status of the unit
   */
  function setActive(bool _active) onlyOwner() {
    active = _active;
  }

  /**
     @dev `setCurrencyCode` allows the owner of the contract to set which
     currency other than Líf the Unit is priced in

     @param _currencyCode The hex value of the currency code
   */
  function setCurrencyCode(bytes8 _currencyCode) onlyOwner() {
    currencyCode = _currencyCode;
  }

  /**
     @dev `setPrice` allows the owner of the contract to set a speical price in
     the custom currency for a range of dates

     @param price The price of the unit
     @param fromDay The starting date of the period of days to change
     @param daysAmount The amount of days in the period
   */
  function setSpecialPrice(
    uint256 price,
    uint256 fromDay,
    uint256 daysAmount
  ) onlyOwner() {
    uint256 toDay = fromDay+daysAmount;
    for (uint256 i = fromDay; i < toDay; i++)
      reservations[i].specialPrice = price;
  }

  /**
     @dev `setSpecialLifPrice` allows the owner of the contract to set a special
     price in Líf for a range of days

     @param price The price of the unit
     @param fromDay The starting date of the period of days to change
     @param daysAmount The amount of days in the period
   */
  function setSpecialLifPrice(
    uint256 price,
    uint256 fromDay,
    uint256 daysAmount
  ) onlyOwner() {
    uint256 toDay = fromDay+daysAmount;
    for (uint256 i = fromDay; i < toDay; i++)
      reservations[i].specialLifPrice = price;
  }

  /**
     @dev `setDefaultPrice` allows the owner of the contract to set the default
     price in the custom currency for reserving the Unit for 1 day

     @param price The new default price
   */
  function setDefaultPrice(uint256 price) onlyOwner() {
    defaultPrice = price;
  }

  /**
     @dev `setDefaultLifPrice` allows the owner of the contract to set the default
     price in Lif for reserving the Unit for 1 day

     @param price The new default Lif price
   */
  function setDefaultLifPrice(uint256 price) onlyOwner() {
    defaultLifPrice = price;
  }

  /**
     @dev `book` allows the owner to make a reservation

     @param from The address of the opener of the reservation
     @param fromDay The starting day of the period of days to book
     @param daysAmount The amount of days in the booking period

     @return bool Whether the booking was successful or not
   */
  function book(
    address from,
    uint256 fromDay,
    uint256 daysAmount
  ) onlyOwner() returns(bool) {
    require(isFutureDay(fromDay));
    require(active);
    uint256 toDay = fromDay+daysAmount;

    for (uint256 i = fromDay; i < toDay ; i++){
      if (reservations[i].bookedBy != address(0)) {
        return false;
      }
    }

    for (i = fromDay; i < toDay ; i++)
      reservations[i].bookedBy = from;
    return true;
  }

  /**
     @dev `getReservation` get the avalibility and price of a day

     @param day The number of days after 01-01-1970

     @return uint256 The price of the day in the custom currency, 0 if default price
     @return uint256 The price of the day in Líf, 0 if default price
     @return address The address of the owner of the reservation
     returns 0x0 if its available
   */
  function getReservation(
    uint256 day
  ) constant returns(uint256, uint256, address) {
    return (
      reservations[day].specialPrice,
      reservations[day].specialLifPrice,
      reservations[day].bookedBy
    );
  }

  /**
     @dev `getCost` calculates the cost of renting the Unit for the given dates

     @param fromDay The starting date of the period of days to book
     @param daysAmount The amount of days in the period

     @return uint256 The total cost of the booking in the custom currency
   */
  function getCost(
    uint256 fromDay,
    uint256 daysAmount
  ) constant returns(uint256) {
    uint256 toDay = fromDay+daysAmount;
    uint256 totalCost = 0;

    for (uint256 i = fromDay; i < toDay ; i++){
      if (reservations[i].specialPrice > 0) {
        totalCost += reservations[i].specialPrice;
      } else {
        totalCost += defaultPrice;
      }
    }

    return totalCost;
  }

  /**
     @dev `getLifCost` calculates the cost of renting the Unit for the given dates

     @param fromDay The starting date of the period of days to book
     @param daysAmount The amount of days in the period

     @return uint256 The total cost of the booking in Lif
   */
  function getLifCost(
    uint256 fromDay,
    uint256 daysAmount
  ) constant returns(uint256) {
    uint256 toDay = fromDay+daysAmount;
    uint256 totalCost = 0;

    for (uint256 i = fromDay; i < toDay ; i++){
      if (reservations[i].specialLifPrice > 0) {
        totalCost += reservations[i].specialLifPrice;
      } else {
        totalCost += defaultLifPrice;
      }
    }

    return totalCost;
  }

  /**
     @dev `isFutureDay` checks that a timestamp is not a past date

     @param time The number of days after 01-01-1970

     @return bool If the timestamp is today or in the future
   */
  function isFutureDay(uint256 time) internal returns (bool) {
    return !(now / 86400 > time);
  }

}


