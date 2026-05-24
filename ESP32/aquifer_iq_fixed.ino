#include <Arduino.h>
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <Wire.h>
#include <Adafruit_GFX.h>
#include <Adafruit_SH110X.h>
#include <OneWire.h>
#include <DallasTemperature.h>

#define SERVICE_UUID        "4fafc201-1fb5-459e-8fcc-c5c9c331914b"
#define CHARACTERISTIC_UUID "beb5483e-36e1-4688-b7f5-ea07361b26a8"


#define TURBIDITY_CLEAN_V 1.075 
#define TURBIDITY_DIRTY_V 0.21  


#define SCREEN_WIDTH 128
#define SCREEN_HEIGHT 64
#define OLED_RESET -1
Adafruit_SH1106G display = Adafruit_SH1106G(SCREEN_WIDTH, SCREEN_HEIGHT, &Wire, OLED_RESET);

#define TEMP_PIN       4   
#define TURBIDITY_PIN  34  
#define TDS_PIN        35  
#define TOUCH_PIN      15  

OneWire oneWire(TEMP_PIN);
DallasTemperature sensors(&oneWire);


enum SystemState { STATE_WELCOME, STATE_MENU, STATE_WAIT_APP, STATE_SCAN, STATE_DISPLAY, STATE_SLEEP };
SystemState currentState = STATE_WELCOME;

enum WorkMode { MODE_NONE, MODE_SMART, MODE_LOCAL };
WorkMode currentMode = MODE_NONE;

enum TouchEvent { TOUCH_NONE, TOUCH_SINGLE, TOUCH_DOUBLE, TOUCH_LONG };


int menuCursor = 0;    
int currentPage = 0;      
float lastTDS = 0, lastPurity = 0, lastTemp = 25.0;

unsigned long lastInteractionTime = 0; 
const unsigned long SLEEP_TIMEOUT = 60000; 


BLECharacteristic* pCharacteristic = nullptr;
bool deviceConnected = false;
bool bleInitialized = false;

class ServerCallbacks : public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) override { deviceConnected = true; }
    void onDisconnect(BLEServer* pServer) override { deviceConnected = false; pServer->getAdvertising()->start(); }
};

void initBLE();
void runDeepScan();
void drawRadarAnimation();
void drawMenu();
void displayCurrentPage();

TouchEvent getTouchEvent() {
    static unsigned long touchStart = 0;
    static unsigned long lastRelease = 0;
    static int tapCount = 0;
    static bool wasTouched = false;
    static bool longPressHandled = false;
    
    bool isTouched = (digitalRead(TOUCH_PIN) == HIGH);
    unsigned long now = millis();
    TouchEvent result = TOUCH_NONE;

    if (isTouched && !wasTouched) {
        touchStart = now;
        longPressHandled = false;
        lastInteractionTime = now; 
    }

    if (isTouched && wasTouched) {
        if (!longPressHandled && (now - touchStart > 800)) { 
            longPressHandled = true;
            tapCount = 0; 
            result = TOUCH_LONG;
        }
    }

    if (!isTouched && wasTouched) { 
        if (!longPressHandled && (now - touchStart > 50)) {
            tapCount++;
            lastRelease = now;
        }
    }
    wasTouched = isTouched;

    if (!isTouched && tapCount > 0 && (now - lastRelease > 350)) {
        if (tapCount == 1) result = TOUCH_SINGLE;
        else if (tapCount >= 2) result = TOUCH_DOUBLE;
        tapCount = 0;
    }

    return result;
}

void setup() {
    Serial.begin(115200);
    pinMode(TOUCH_PIN, INPUT);
    analogReadResolution(12);
    
    sensors.begin();
    sensors.setWaitForConversion(false);
    
    Wire.begin(21, 22);
    if (!display.begin(0x3C, true)) {
        Serial.println("❌ OLED not found!");
    }
    delay(250);
    display.setContrast(255);
    
    currentState = STATE_WELCOME;
    lastInteractionTime = millis();
}

void loop() {
    TouchEvent touch = getTouchEvent();

    if (currentState == STATE_SLEEP && touch != TOUCH_NONE) {
        currentState = STATE_DISPLAY;
        lastInteractionTime = millis();
        return; 
    }

    switch (currentState) {
        
        case STATE_WELCOME:
            display.clearDisplay();
            display.setTextSize(1);
            display.setCursor(12, 20);
            display.println("Welcome to");
            display.setCursor(35, 35);
            display.setTextSize(2);
            display.println("AquiferIQ");
            display.display();
            
            if (millis() - lastInteractionTime > 2000) {
                currentState = STATE_MENU;
            }
            break;

        case STATE_MENU:
            drawMenu();
            if (touch == TOUCH_SINGLE) {
                menuCursor = (menuCursor == 0) ? 1 : 0;
            } 
            else if (touch == TOUCH_LONG) {
 
                if (menuCursor == 0) {
                    currentMode = MODE_SMART;
                    initBLE(); 
                    currentState = STATE_WAIT_APP;
                } else {
                    currentMode = MODE_LOCAL;
                    currentState = STATE_SCAN;
                }
            }
            break;

        case STATE_WAIT_APP:
            drawRadarAnimation();
            if (deviceConnected) {
                currentState = STATE_SCAN; 
            }
            break;

        case STATE_SCAN:
            runDeepScan(); 
            currentState = STATE_DISPLAY;
            currentPage = 0;
            lastInteractionTime = millis();
            break;

        case STATE_DISPLAY:
            if (millis() - lastInteractionTime > SLEEP_TIMEOUT) {
                currentState = STATE_SLEEP; 
                display.clearDisplay();
                display.display();
            } else {
                displayCurrentPage();
                
                if (touch == TOUCH_SINGLE) {
                    currentPage = (currentPage + 1) % 4;
                } 
                else if (touch == TOUCH_DOUBLE) {
                    currentState = STATE_SCAN;
                }
            }
            break;

        case STATE_SLEEP:
            break;
    }
}



void drawMenu() {
    display.clearDisplay();
    display.setTextSize(1);
    display.setCursor(0, 5);
    display.println("Select Mode:");
    display.drawLine(0, 15, 128, 15, SH110X_WHITE);

    display.setTextSize(1);
    

    if (menuCursor == 0) display.print(">");
    else display.print(" ");
    display.setCursor(10, 25);
    display.println("1. Smart Mode (App)");


    display.setCursor(0, 45);
    if (menuCursor == 1) display.print(">");
    else display.print(" ");
    display.setCursor(10, 45);
    display.println("2. Local Scan Only");

    display.display();
}

void drawRadarAnimation() {
    display.clearDisplay();
    int radius1 = (millis() / 40) % 25;
    int radius2 = ((millis() / 40) + 12) % 25;
    
    display.drawCircle(64, 25, radius1, SH110X_WHITE);
    display.drawCircle(64, 25, radius2, SH110X_WHITE);
    display.fillCircle(64, 25, 3, SH110X_WHITE);

    display.setTextSize(1);
    display.setCursor(15, 52);
    display.print("Waiting for App...");
    display.display();
}

void runDeepScan() {
    float tdsSum = 0, turbSum = 0;
    int samples = 0;
    sensors.requestTemperatures(); 


    for(int progress = 0; progress <= 100; progress += 2) {
        display.clearDisplay();
        
        display.drawRect(52, 12, 24, 34, SH110X_WHITE);
        display.drawLine(50, 12, 78, 12, SH110X_WHITE); 
        
        int fillHeight = (progress * 30) / 100;
        if (fillHeight > 0) {
            display.fillRect(54, 44 - fillHeight, 20, fillHeight, SH110X_WHITE);
        }

        display.setTextSize(1);
        display.setCursor(10, 52);
        display.print("Analyzing Water: ");
        display.print(progress);
        display.print("%");
        display.display();

        tdsSum += analogRead(TDS_PIN);
        turbSum += analogRead(TURBIDITY_PIN);
        samples++;
        delay(40); 
    }

    lastTemp = sensors.getTempCByIndex(0);
    if(lastTemp == DEVICE_DISCONNECTED_C) lastTemp = 25.0;

    float avgTdsAdc = tdsSum / samples;
    float vTds = avgTdsAdc * (3.3 / 4095.0);
    lastTDS = (133.42*pow(vTds,3) - 255.86*pow(vTds,2) + 857.39*vTds) * 0.5;
    if (lastTDS < 0) lastTDS = 0;

    float avgTurbAdc = turbSum / samples;
    float vTurb = avgTurbAdc * (3.3 / 4095.0);
    lastPurity = constrain(((vTurb - TURBIDITY_DIRTY_V) / (TURBIDITY_CLEAN_V - TURBIDITY_DIRTY_V)) * 100.0, 0.0, 100.0);

    if (currentMode == MODE_SMART && deviceConnected) {
        char buffer[80];
        snprintf(buffer, sizeof(buffer), "{\"tds\":%.1f,\"purity\":%.1f,\"temp\":%.1f}", lastTDS, lastPurity, lastTemp);
        pCharacteristic->setValue(buffer);
        pCharacteristic->notify();
    }
}

void displayCurrentPage() {
    display.clearDisplay();
    display.setTextColor(SH110X_WHITE);
    display.setTextSize(1);
    
    display.setCursor(0,0);
    display.print("AquiferIQ - ");
    
    switch(currentPage) {
        case 0: 
            display.println("Overview");
            display.drawLine(0, 10, 128, 10, SH110X_WHITE);
            display.setCursor(0, 18); display.printf("TDS:    %.0f PPM", lastTDS);
            display.setCursor(0, 34); display.printf("Purity: %.1f %%", lastPurity);
            display.setCursor(0, 50); display.printf("Temp:   %.1f C", lastTemp);
            break;
            
        case 1: 
            display.println("Temperature");
            display.setTextSize(3); display.setCursor(20, 25);
            display.printf("%.1f", lastTemp);
            display.setTextSize(1); display.print(" C");
            break;

        case 2: 
            display.println("TDS Level");
            display.setTextSize(3); display.setCursor(15, 25);
            display.printf("%.0f", lastTDS);
            display.setTextSize(1); display.print(" PPM");
            break;

        case 3: 
            display.println("Purity");
            display.setTextSize(3); display.setCursor(15, 25);
            display.printf("%.1f", lastPurity);
            display.setTextSize(1); display.print(" %");
            break;
    }
    
    if (currentMode == MODE_SMART && deviceConnected) {
        display.fillCircle(120, 5, 3, SH110X_WHITE);
    } else if (currentMode == MODE_LOCAL) {
        display.setCursor(118, 0);
        display.print("L");
    }
    
    display.display();
}

void initBLE() {
    if (bleInitialized) return;
    BLEDevice::init("AquiferIQ");
    BLEServer* pServer = BLEDevice::createServer();
    pServer->setCallbacks(new ServerCallbacks());
    BLEService* pService = pServer->createService(SERVICE_UUID);
    pCharacteristic = pService->createCharacteristic(CHARACTERISTIC_UUID, BLECharacteristic::PROPERTY_NOTIFY);
    pCharacteristic->addDescriptor(new BLE2902());
    pService->start();
    pServer->getAdvertising()->start();
    bleInitialized = true;
}
