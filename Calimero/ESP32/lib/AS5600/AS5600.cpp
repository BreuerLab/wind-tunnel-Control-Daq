//
//    FILE: AS56000.cpp
//  AUTHOR: Rob Tillaart
// VERSION: 0.3.1
// PURPOSE: Arduino library for AS5600 magnetic rotation meter
//    DATE: 2022-05-28
//     URL: https://github.com/RobTillaart/AS5600

//  0.1.0   2022-05-28  initial version.
//  0.1.1   2022-05-31  Add readReg2() to speed up reading 2 byte values.
//                      Fix clock wise and counter clock wise.
//                      Fix shift-direction @ getZPosition, getMPosition,
//                          getMaxAngle and getConfigure.
//  0.1.2   2022-06-02  Add getAngularSpeed().
//  0.1.3   2022-06-26  Add AS5600_RAW_TO_RADIANS.
//                      Add getAngularSpeed() mode parameter.
//                      Fix #8 bug in configure.
//  0.1.4   2022-06-27  Fix #7 use readReg2() to improve I2C performance.
//                      define constants for configuration functions.
//                      add examples - especially OUT pin related.
//                      Fix default parameter of the begin function.
//
//  0.2.0   2022-06-28  add software based direction control.
//                      add examples
//                      define constants for configuration functions.
//                      fix conversion constants (4096 based)
//                      add get- setOffset(degrees)   functions. (no radians yet)
//  0.2.1   notreleased add bool return to set() functions.
//                      update Readme (analog / PWM out)
//
//  0.3.0   2022-07-07  fix #18 invalid mask setConfigure().
//  0.3.1   2022-08-11  add support for AS5600L (I2C address)
//                      add magnetTooStrong() + magnetTooWeak();
//                      add / update examples
//                      update documentation

// TODO
//  Power-up time  1 minute (need HW)
//  check  Timing Characteristics

#include "AS5600.h"

//  CONFIGURATION REGISTERS
const uint8_t AS5600_ZMCO = 0x00;
const uint8_t AS5600_ZPOS = 0x01; // + 0x02
const uint8_t AS5600_MPOS = 0x03; // + 0x04
const uint8_t AS5600_MANG = 0x05; // + 0x06
const uint8_t AS5600_CONF = 0x07; // + 0x08

//  CONFIGURATION BIT MASKS - byte level
const uint8_t AS5600_CONF_POWER_MODE = 0x03;
const uint8_t AS5600_CONF_HYSTERESIS = 0x0C;
const uint8_t AS5600_CONF_OUTPUT_MODE = 0x30;
const uint8_t AS5600_CONF_PWM_FREQUENCY = 0xC0;
const uint8_t AS5600_CONF_SLOW_FILTER = 0x03;
const uint8_t AS5600_CONF_FAST_FILTER = 0x1C;
const uint8_t AS5600_CONF_WATCH_DOG = 0x20;

//  UNKNOWN REGISTERS 0x09-0x0A

//  OUTPUT REGISTERS
const uint8_t AS5600_RAW_ANGLE = 0x0C; // + 0x0D
const uint8_t AS5600_ANGLE = 0x0E;     // + 0x0F

// I2C_ADDRESS REGISTERS (AS5600L)
const uint8_t AS5600_I2CADDR = 0x20;
const uint8_t AS5600_I2CUPDT = 0x21;

//  STATUS REGISTERS
const uint8_t AS5600_STATUS = 0x0B;
const uint8_t AS5600_AGC = 0x1A;
const uint8_t AS5600_MAGNITUDE = 0x1B; // + 0x1C
const uint8_t AS5600_BURN = 0xFF;

//  STATUS BITS
const uint8_t AS5600_MAGNET_HIGH = 0x08;
const uint8_t AS5600_MAGNET_LOW = 0x10;
const uint8_t AS5600_MAGNET_DETECT = 0x20;

AS5600::AS5600(TwoWire *wire)
{
  _wire = wire;
}

#if defined(ESP8266) || defined(ESP32)
bool AS5600::begin(int dataPin, int clockPin, uint8_t directionPin)
{
  _directionPin = directionPin;
  if (_directionPin != 255)
  {
    pinMode(_directionPin, OUTPUT);
  }
  setDirection(AS5600_CLOCK_WISE);

  // _wire = &Wire;
  if ((dataPin < 255) && (clockPin < 255))
  {
    _wire->begin(dataPin, clockPin);
  }
  else
  {
    _wire->begin();
  }
  if (!isConnected())
    return false;
  return true;
}
#endif

bool AS5600::begin(uint8_t directionPin)
{
  _directionPin = directionPin;
  if (_directionPin != 255)
  {
    pinMode(_directionPin, OUTPUT);
  }
  setDirection(AS5600_CLOCK_WISE);

  _wire->begin();
  if (!isConnected())
    return false;
  return true;
}

bool AS5600::isConnected()
{
  _wire->beginTransmission(_address);
  return (_wire->endTransmission() == 0);
}

/////////////////////////////////////////////////////////
//
//  CONFIGURATION REGISTERS + direction pin
//
void AS5600::setDirection(uint8_t direction)
{
  _direction = direction;
  if (_directionPin != 255)
  {
    digitalWrite(_directionPin, _direction);
  }
}

uint8_t AS5600::getDirection()
{
  if (_directionPin != 255)
  {
    _direction = digitalRead(_directionPin);
  }
  return _direction;
}

uint8_t AS5600::getZMCO()
{
  uint8_t value = readReg(AS5600_ZMCO);
  return value;
}

bool AS5600::setZPosition(uint16_t value)
{
  if (value > 0x0FFF)
    return false;
  writeReg2(AS5600_ZPOS, value);
  return true;
}

uint16_t AS5600::getZPosition()
{
  uint16_t value = readReg2(AS5600_ZPOS) & 0x0FFF;
  return value;
}

bool AS5600::setMPosition(uint16_t value)
{
  if (value > 0x0FFF)
    return false;
  writeReg2(AS5600_MPOS, value);
  return true;
}

uint16_t AS5600::getMPosition()
{
  uint16_t value = readReg2(AS5600_MPOS) & 0x0FFF;
  return value;
}

bool AS5600::setMaxAngle(uint16_t value)
{
  if (value > 0x0FFF)
    return false;
  writeReg2(AS5600_MANG, value);
  return true;
}

uint16_t AS5600::getMaxAngle()
{
  uint16_t value = readReg2(AS5600_MANG) & 0x0FFF;
  return value;
}

bool AS5600::setConfigure(uint16_t value)
{
  if (value > 0x3FFF)
    return false;
  writeReg2(AS5600_CONF, value);
  return true;
}

uint16_t AS5600::getConfigure()
{
  uint16_t value = readReg2(AS5600_CONF) & 0x3FFF;
  return value;
}

//  details configure
bool AS5600::setPowerMode(uint8_t powerMode)
{
  if (powerMode > 3)
    return false;
  uint8_t value = readReg(AS5600_CONF + 1);
  value &= ~AS5600_CONF_POWER_MODE;
  value |= powerMode;
  writeReg(AS5600_CONF + 1, value);
  return true;
}

uint8_t AS5600::getPowerMode()
{
  return readReg(AS5600_CONF + 1) & 0x03;
}

/**
 * @brief To avoid any toggling of the output when the magnet is not
moving, a 1 to 3 LSB hysteresis of the 12-bit resolution can be
enabled
 * @param hysteresis 0 (aucun) 1,2 3 LSB
**/
bool AS5600::setHysteresis(uint8_t hysteresis)
{
  if (hysteresis > 3)
    return false;
  uint8_t value = readReg(AS5600_CONF + 1);
  value &= ~AS5600_CONF_HYSTERESIS;
  value |= (hysteresis << 2);
  writeReg(AS5600_CONF + 1, value);
  return true;
}

uint8_t AS5600::getHysteresis()
{
  return (readReg(AS5600_CONF + 1) >> 2) & 0x03;
}

bool AS5600::setOutputMode(uint8_t outputMode)
{
  if (outputMode > 2)
    return false;
  uint8_t value = readReg(AS5600_CONF + 1);
  value &= ~AS5600_CONF_OUTPUT_MODE;
  value |= (outputMode << 4);
  writeReg(AS5600_CONF + 1, value);
  return true;
}

uint8_t AS5600::getOutputMode()
{
  return (readReg(AS5600_CONF + 1) >> 4) & 0x03;
}

bool AS5600::setPWMFrequency(uint8_t pwmFreq)
{
  if (pwmFreq > 3)
    return false;
  uint8_t value = readReg(AS5600_CONF + 1);
  value &= ~AS5600_CONF_PWM_FREQUENCY;
  value |= (pwmFreq << 6);
  writeReg(AS5600_CONF + 1, value);
  return true;
}

uint8_t AS5600::getPWMFrequency()
{
  return (readReg(AS5600_CONF + 1) >> 6) & 0x03;
}

bool AS5600::setSlowFilter(uint8_t mask)
{
  if (mask > 3)
    return false;
  uint8_t value = readReg(AS5600_CONF);
  value &= ~AS5600_CONF_SLOW_FILTER;
  value |= mask;
  writeReg(AS5600_CONF, value);
  return true;
}

uint8_t AS5600::getSlowFilter()
{
  return readReg(AS5600_CONF) & 0x03;
}

bool AS5600::setFastFilter(uint8_t mask)
{
  if (mask > 7)
    return false;
  uint8_t value = readReg(AS5600_CONF);
  value &= ~AS5600_CONF_FAST_FILTER;
  value |= (mask << 2);
  writeReg(AS5600_CONF, value);
  return true;
}

uint8_t AS5600::getFastFilter()
{
  return (readReg(AS5600_CONF) >> 2) & 0x07;
}

bool AS5600::setWatchDog(uint8_t mask)
{
  if (mask > 1)
    return false;
  uint8_t value = readReg(AS5600_CONF);
  value &= ~AS5600_CONF_WATCH_DOG;
  value |= (mask << 5);
  writeReg(AS5600_CONF, value);
  return true;
}

uint8_t AS5600::getWatchDog()
{
  return (readReg(AS5600_CONF) >> 5) & 0x01;
}

/////////////////////////////////////////////////////////
//
//  OUTPUT REGISTERS
//
/**
 * @brief Acquisition de l'angle ( RAW ANGLE register, unscaled and unmodified angle)
 * @return Retourne une valeur entre 0 et 4095 (en prenant en compte l'offset de la lib)
 * @note The RAW ANGLE register contains the unscaled and unmodified angle.
 * */
uint16_t AS5600::rawAngle()
{
  uint16_t value = readReg2(AS5600_RAW_ANGLE) & 0x0FFF;
  if (_offset > 0)
    value = (value + _offset) & 0x0FFF;

  if ((_directionPin == 255) && (_direction == AS5600_COUNTERCLOCK_WISE))
  {
    value = (4096 - value) & 4095;
  }
  return value;
}

/**
 * @brief Acquisition de l'angle (ANGLE register, scaled output value)
 * @return Retourne une valeur entre 0 et 4095 (en prenant en compte l'offset de la lib)
 * @note The scaled output value is available in the ANGLE register.
 * The ANGLE register has a 10-LSB hysteresis at the limit of the 360 degree range
 * */
uint16_t AS5600::readAngle()
{
  uint16_t value = readReg2(AS5600_ANGLE) & 0x0FFF;
  if (_offset > 0)
    value = (value + _offset) & 0x0FFF;

  if ((_directionPin == 255) && (_direction == AS5600_COUNTERCLOCK_WISE))
  {
    value = (4096 - value) & 4095;
  }
  return value;
}

bool AS5600::setOffset(float degrees)
{
  // expect loss of precision.
  if (abs(degrees) > 36000)
    return false;
  bool neg = (degrees < 0);
  if (neg)
    degrees = -degrees;

  uint16_t offset = round(degrees * (4096 / 360.0));
  offset &= 4095;
  if (neg)
    offset = 4096 - offset;
  _offset = offset;
  return true;
}

float AS5600::getOffset()
{
  return _offset * AS5600_RAW_TO_DEGREES;
}

/////////////////////////////////////////////////////////
//
//  STATUS REGISTERS
//
uint8_t AS5600::readStatus()
{
  uint8_t value = readReg(AS5600_STATUS);
  return value;
}

uint8_t AS5600::readAGC()
{
  uint8_t value = readReg(AS5600_AGC);
  return value;
}

uint16_t AS5600::readMagnitude()
{
  uint16_t value = readReg2(AS5600_MAGNITUDE) & 0x0FFF;
  return value;
}

bool AS5600::detectMagnet()
{
  return (readStatus() & AS5600_MAGNET_DETECT) > 1;
}

bool AS5600::magnetTooStrong()
{
  return (readStatus() & AS5600_MAGNET_HIGH) > 1;
}

bool AS5600::magnetTooWeak()
{
  return (readStatus() & AS5600_MAGNET_LOW) > 1;
}

/////////////////////////////////////////////////////////
//
//  BURN COMMANDS
//
//  DO NOT UNCOMMENT - USE AT OWN RISK - READ DATASHEET
//
//  void AS5600::burnAngle()
//  {
//    writeReg(AS5600_BURN, x0x80);
//  }
//
//
//  void AS5600::burnSetting()
//  {
//    writeReg(AS5600_BURN, x0x40);
//  }

float AS5600::getAngularSpeed(uint8_t mode)
{
  uint32_t now = micros();
  int angle = readAngle();
  uint32_t deltaT = now - _lastMeasurement;
  int deltaA = angle - _lastAngle;

  //  assumption is that there is no more than 180° rotation
  //  between two consecutive measurements.
  //  => at least two measurements per rotation (preferred 4).
  if (deltaA > 2048)
    deltaA -= 4096;
  if (deltaA < -2048)
    deltaA += 4096;
  float speed = (deltaA * 1e6) / deltaT;

  //  remember last time & angle
  _lastMeasurement = now;
  _lastAngle = angle;
  //  return degrees or radians
  if (mode == AS5600_MODE_RADIANS)
  {
    return speed * AS5600_RAW_TO_RADIANS;
  }
  //  default return degrees
  return speed * AS5600_RAW_TO_DEGREES;
}

/**
 * @brief Acquisition de l'angle.
 * @param (bool) fixedSamplingPeriod, (true) : temps minimum entre 2 mesures = samplingPeriod µs
 *                                    (false) : vitesse de mesure maximale
 * @return (uint16_t) angle entre 0 et 4095
 * **/
u_int16_t AS5600::getAnglePos(bool fixedSamplingPeriod)
{
  uint16_t angle;
  if (fixedSamplingPeriod == true)
  {
    bool mesureOK = false;
    while (mesureOK == false)
    {
      currentMicros = micros();
      if (currentMicros - previousMicros >= samplingPeriod)
      {
        previousMicros = currentMicros;
        // Acquisition
        angle = rawAngle();
        mesureOK = true;
      }
    }
  }
  else
  {
    angle = rawAngle();
  }

  return angle;
}

/**
 * @brief  Position de l'angle dans les 4 quadrants
 * @param  (u_int16_t) angle - Entre 0 et 4095
 * @return (u_int8_t) n° du quadrant (entre 1 et 4)
 * */
u_int8_t AS5600::getQuadrant(u_int16_t angle)
{
  // https://curiousscientist.tech/blog/as5600-magnetic-position-encoder
  /* Quadrants:
    4  |  1
    ---|---
    3  |  2
    */

  u_int8_t quadrantNumber;

  if (angle <= 1024)
  { // Quadrant 1
    quadrantNumber = 1;
  }
  else if (angle <= 2048)
  { // Quadrant 2
    quadrantNumber = 2;
  }
  else if (angle <= 3072)
  { // Quadrant 3
    quadrantNumber = 3;
  }
  else if (angle < 4096)
  { // Quadrant 4
    quadrantNumber = 4;
  }
  return quadrantNumber;
}

/**
 * @brief  Calcul de la position absolue / angle total
 * @param  (u_int8_t) quadrantNumber - n° du quadrant (entre 1 et 4)
 * @param  (u_int16_t) angle - Entre 0 et 4095
 * @return (int32_t) totalAngle absolu (+/-), un tour=4096
 * @remarks Nécessite d'avoir au moins 4 aquisitions par tour.
 *          Met à jour les attributs previousquadrantNumber et numberofTurns
 * **/
int32_t AS5600::getTotalAngle(u_int8_t quadrantNumber, u_int16_t angle)
{
  // https://curiousscientist.tech/blog/as5600-magnetic-position-encoder

  int32_t totalAngle;

  if (quadrantNumber != previousquadrantNumber) // if we changed quadrant
  {
    if (quadrantNumber == 1 && previousquadrantNumber == 4)
    {
      numberofTurns++; // 4 --> 1 transition: CW rotation
    }

    if (quadrantNumber == 4 && previousquadrantNumber == 1)
    {
      numberofTurns--; // 1 --> 4 transition: CCW rotation
    }

    previousquadrantNumber = quadrantNumber; // update to the current quadrant
  }

  // total absolute position
  totalAngle = (int)((numberofTurns * 4096) + angle); // number of turns (+/-) plus the actual angle within the 0-360 range
  return totalAngle;
}

/**
 * @brief Retourne le nombre de tours
 * @return nombre total de tours complets. Si négatif il faut ajouter +1
 **/
int32_t AS5600::getNumberofTurns()
{
  return numberofTurns;
}

/**
 * @brief Initialisation du quadrant de départ et du nombre de tours.
 * Positionnement entre -2048 (quandrant 3&4) et +2048 (quadrant 1&2)
 * */
void AS5600::initQuadrantAndTurns()
{
  u_int16_t angle = getAnglePos(true);
  previousquadrantNumber = getQuadrant(angle);
  if (previousquadrantNumber >= 3)
    numberofTurns = -1;
}

/**
 * @brief (Test) Mesure la durée de 1000 acquisitions (pour connaitre le temps de traitement ESP)
 * **/
void AS5600::test_vitesse_1000_acquisitions()
{
  uint16_t angle;
  int inc_test_vitesse = 0;
  unsigned long debut = micros();

  while (inc_test_vitesse < 1000)
  {
    // Acquisition
    // angle = getAnglePos(false);
    // affichage
    // Serial.println(angle);
    angle = getAnglePos(false);
    Serial.println((int)getTotalAngle(getQuadrant(angle), angle));
    inc_test_vitesse += 1;
    // }
  }
  unsigned long duree = micros() - debut;
  Serial.print("Durée pour 1000 acquisitions = ");
  Serial.print(duree);
  Serial.println(" µs");
}

  /**  
   * @brief Gestion logicielle de l'offset. Permet de fixer la position 0
   * @param anglePos Position entre 0 et 4095
   * @remarks mets à jour _offset, numberofTurns=0 et appelle initQuadrantAndTurns
  **/
void AS5600::setOffsetRAW(u_int16_t anglePos)
{
  // Dans rawAngle() :  value = (value + _offset) & 0x0FFF; 
  anglePos = anglePos -_offset; //valeur mesurée sans offset
  anglePos &= 4095;
  _offset = -anglePos;

  // mets à jour numberofTurns=0 et appelle initQuadrantAndTurns
  numberofTurns=0;
  initQuadrantAndTurns();
}
/*
  // expect loss of precision.
  if (abs(degrees) > 36000)
    return false;
  bool neg = (degrees < 0);
  if (neg)
    degrees = -degrees;

  uint16_t offset = round(degrees * (4096 / 360.0));
  offset &= 4095;
  if (neg)
    offset = 4096 - offset;
  _offset = offset;
  return true;
*/

u_int16_t AS5600::getOffsetRAW()
{
  return _offset;
}

/////////////////////////////////////////////////////////
//
//  PRIVATE AS5600
//
uint8_t AS5600::readReg(uint8_t reg)
{
  _wire->beginTransmission(_address);
  _wire->write(reg);
  _error = _wire->endTransmission();

  _wire->requestFrom(_address, (uint8_t)1);
  uint8_t _data = _wire->read();
  return _data;
}

uint16_t AS5600::readReg2(uint8_t reg)
{
  _wire->beginTransmission(_address);
  _wire->write(reg);
  _error = _wire->endTransmission();

  _wire->requestFrom(_address, (uint8_t)2);
  uint16_t _data = _wire->read();
  _data <<= 8;
  _data += _wire->read();
  return _data;
}

uint8_t AS5600::writeReg(uint8_t reg, uint8_t value)
{
  _wire->beginTransmission(_address);
  _wire->write(reg);
  _wire->write(value);
  _error = _wire->endTransmission();
  return _error;
}

uint8_t AS5600::writeReg2(uint8_t reg, uint16_t value)
{
  _wire->beginTransmission(_address);
  _wire->write(reg);
  _wire->write(value >> 8);
  _wire->write(value & 0xFF);
  _error = _wire->endTransmission();
  return _error;
}

/////////////////////////////////////////////////////////////////////////////
//
//  AS5600L
//
AS5600L::AS5600L(uint8_t address, TwoWire *wire) : AS5600(wire)
{
  _address = address;
  ; //  0x40 = default address AS5600L.
}

bool AS5600L::setAddress(uint8_t address)
{
  //  skip reserved I2C addresses
  if ((address < 8) || (address > 119))
    return false;

  //  note address need to be shifted 1 bit.
  writeReg(AS5600_I2CADDR, address << 1);
  writeReg(AS5600_I2CUPDT, address << 1);

  //  remember new address.
  _address = address;
  return true;
}

bool AS5600L::setI2CUPDT(uint8_t address)
{
  //  skip reserved I2C addresses
  if ((address < 8) || (address > 119))
    return false;
  writeReg(AS5600_I2CUPDT, address << 1);
  return true;
}

uint8_t AS5600L::getI2CUPDT()
{
  return (readReg(AS5600_I2CUPDT) >> 1);
}

//  -- END OF FILE --
