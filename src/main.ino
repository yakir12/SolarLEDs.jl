#include <PacketSerial.h> // for the COBS
#include <Adafruit_DotStar.h> // for the LEDs
#include <SPI.h> // for the 11 channel
#include <EEPROM.h> // for writing to "disk"
#include <IRremote.h> // for IR remote

#define NUMPIXELS 300 // setup for two 150 LED strips


Adafruit_DotStar strip = Adafruit_DotStar(NUMPIXELS, DOTSTAR_BRG);

PacketSerial myPacketSerial;

const int RECV_PIN = 12;
IRrecv irrecv(RECV_PIN);

const int N_SUNS = 4;
const int N_BUTTONS = 17;
const int FRAME_SIZE = 4 * N_SUNS;

//bool ON = false;

void setup()
{
  myPacketSerial.begin(115200);
  myPacketSerial.setPacketHandler(&onPacketReceived);

  strip.begin();
  strip.show();

  irrecv.enableIRIn();
  irrecv.blink13(true);

  SPI.begin();
  SPI.beginTransaction(SPISettings(2000000, MSBFIRST, SPI_MODE0));

}


void loop()
{
  myPacketSerial.update();
  onIR();
//  if (ON) {
//    strip.setBrightness(0);
//    strip.show();
//    delay(9);
//  }
//  else {
//    strip.setBrightness(255);
//    strip.show();
//    delay(1);
//  }
//  ON = !ON;
}


void onPacketReceived(const uint8_t* buffer, size_t size)
{
  uint8_t mode = buffer[0];
  if (mode == 0) { // play

    strip.clear();
    for (int i = 1; i <= 4 * (N_SUNS - 1) + 1; i += 4) {
      uint8_t c = buffer[i];
      if (c != 0) {
        uint32_t color = strip.Color(c, 0, 0);
        uint16_t first = buffer[i + 1] | (buffer[i + 2] << 8);
        uint8_t count = buffer[i + 3];
        strip.fill(color, first, count);
      }
    }
    strip.show();

  }
  else if (mode == 1) { // upload
    uint8_t button = buffer[1];
    for (int i = 0; i < FRAME_SIZE; i++) {
      EEPROM.write(button * FRAME_SIZE + i, buffer[i + 2]);
    }
    uint8_t tempBuffer[size];
    tempBuffer[0] = mode;
    tempBuffer[1] = button;
    for (int i = 0; i < FRAME_SIZE; i++) {
      tempBuffer[i + 2] = EEPROM.read(button * FRAME_SIZE + i);
    }
    myPacketSerial.send(tempBuffer, size);
  }
  else if (mode == 2) { // download
    uint8_t button = buffer[1];
    uint8_t tempBuffer[FRAME_SIZE];
    for (int i = 0; i < FRAME_SIZE; i++) {
      tempBuffer[i] = EEPROM.read(FRAME_SIZE * button + i);
    }
    myPacketSerial.send(tempBuffer, FRAME_SIZE);
  }
  else if (mode == 3) { // reset
    for (int button = 0 ; button < N_BUTTONS ; button++) {
      for (int j = 0; j < N_SUNS; j++) {
        int i = button * FRAME_SIZE + 4 * j;
        EEPROM.write(i, 0);
        EEPROM.write(i + 1, 0);
        EEPROM.write(i + 2, 0);
        EEPROM.write(i + 3, 1);
      }
    }
    uint8_t answer[1] = {0x01};
    myPacketSerial.send(answer, 1);
  }
}


void onIR()
{
  decode_results IR_result;
  if (irrecv.decode(&IR_result)) {
    uint8_t button = IR2button(IR_result);
    if (button != 17) {
      strip.clear();
      for (int j = 0; j < 4; j++) {
        int i = button * FRAME_SIZE + 4 * j;
        uint8_t c = EEPROM.read(i);
        if (c != 0) {
          uint32_t color = strip.Color(c, 0, 0);
          uint16_t first = EEPROM.read(i + 1) | (EEPROM.read(i + 2) << 8);
          uint8_t count = EEPROM.read(i + 3);
          strip.fill(color, first, count);
        }
      }
      strip.show();
    }
  }
}


uint8_t IR2button(decode_results IR_result) {

  irrecv.resume();
  switch (IR_result.value) {

    case 0xFF4AB5: // 0
      return 0;

    case 0xFF6897: // 1
      return 1;

    case 0xFF9867: // 2
      return 2;

    case 0xFFB04F: // 3
      return 3;

    case 0xFF30CF: // 4
      return 4;

    case 0xFF18E7: // 5
      return 5;

    case 0xFF7A85: // 6
      return 6;

    case 0xFF10EF: // 7
      return 7;

    case 0xFF38C7: // 8
      return 8;

    case 0xFF5AA5: // 9
      return 9;

    case 0xFF52AD: // #
      return 10;

    case 0xFF42BD: // *
      return 11;

    case 0xFFC23D: // Right Arrow
      return 12;

    case 0xFF629D: // Up Arrow
      return 13;

    case 0xFF22DD: // Left Arrow
      return 14;

    case 0xFFA857: // Down Arrow
      return 15;

    case 0xFF02FD: // OK
      return 16;

    default:
      return 17;
  }
}

